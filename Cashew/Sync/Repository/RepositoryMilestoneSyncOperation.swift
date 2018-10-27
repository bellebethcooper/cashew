//
//  RepositoryMilestoneSyncOperation.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class RepositoryMilestoneSyncOperation: RepositoryBaseSyncOperation {
    
    fileprivate let repositoriesService: QRepositoriesService
    fileprivate var milestonesSet = Set<QMilestone>()
    
    let repository: QRepository
    
    required init(repository: QRepository) {
        self.repository = repository
        self.repositoriesService = QRepositoriesService(for: repository.account)
        super.init()
    }
    
    override func main() {
        
        // fetch local milestones
        let milestones = QMilestoneStore.milestones(forAccountId: repository.account.identifier, repositoryId: repository.identifier, includeHidden: true)
        milestones?.forEach({ milestonesSet.insert($0) })
        
        // fetch remote milestones
        let semaphore = DispatchSemaphore(value: 0)
        var successful = true
        fetchMilestones { [weak self] (err) in
            semaphore.signal()
            guard let strongSelf = self else { return }
            successful = (err == nil && !strongSelf.isCancelled)
        }
        semaphore.wait(timeout: DispatchTime.distantFuture)
        
        if successful {
            // hide milestones that don't exist on server
            milestonesSet.forEach { (milestone) in
                //QLabelStore.hideLabel(label)
                QMilestoneStore.hide(milestone)
            }
            
            // make sure all milestones not in set are not hidden
            QMilestoneStore.unhideMilestonesNot(inMilestoneSet: milestonesSet, forAccountId: repository.account.identifier, repositoryId: repository.identifier)
        }
    }
    
    // MARK: Service calls
    
    fileprivate func fetchMilestones(pageNumber: Int = 1, onCompletion: @escaping ( (NSError?) -> Void ) ) {
        
        if isCancelled {
            onCompletion( NSError(domain: "co.cashewapp.RepositoryMilestonesSyncError", code: 0, userInfo: nil) )
            return;
        }
        
        repositoriesService.milestones(for: repository, pageNumber: pageNumber, pageSize: RepositoryMilestoneSyncOperation.pageSize) { [weak self] (milestones, context, err) in
            guard let milestones = milestones as? [QMilestone], let strongSelf = self , err == nil else {
                onCompletion(err as! NSError)
                return
            }
            
            // save new milestones
            for milestone in milestones {
                guard !strongSelf.isCancelled else { return }
                QMilestoneStore.save(milestone)
                strongSelf.milestonesSet.remove(milestone)
            }
            
            if strongSelf.isCancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryMilestonesSyncError", code: 0, userInfo: nil) )
                return;
            }
            
            // sleep if about to hit rate limit
            strongSelf.sleepIfNeededWithContext(context)
            
            // next page or complete operation
            if let nextPageNumber = context.nextPageNumber as? Int , !strongSelf.isCancelled {
                strongSelf.fetchMilestones(pageNumber: nextPageNumber, onCompletion: onCompletion)
                
            } else if strongSelf.isCancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryMilestonesSyncError", code: 0, userInfo: nil) )
                
            } else {
                onCompletion(nil)
            }
            
            
        }
        
    }
}
