//
//  RepositoryMilestoneSyncOperation.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class RepositoryMilestoneSyncOperation: RepositoryBaseSyncOperation {
    
    private let repositoriesService: QRepositoriesService
    private var milestonesSet = Set<QMilestone>()
    
    let repository: QRepository
    
    required init(repository: QRepository) {
        self.repository = repository
        self.repositoriesService = QRepositoriesService(forAccount: repository.account)
        super.init()
    }
    
    override func main() {
        
        // fetch local milestones
        let milestones = QMilestoneStore.milestonesForAccountId(repository.account.identifier, repositoryId: repository.identifier, includeHidden: true)
        milestones.forEach({ milestonesSet.insert($0) })
        
        // fetch remote milestones
        let semaphore = dispatch_semaphore_create(0)
        var successful = true
        fetchMilestones { [weak self] (err) in
            dispatch_semaphore_signal(semaphore)
            guard let strongSelf = self else { return }
            successful = (err == nil && !strongSelf.cancelled)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        if successful {
            // hide milestones that don't exist on server
            milestonesSet.forEach { (milestone) in
                //QLabelStore.hideLabel(label)
                QMilestoneStore.hideMilestone(milestone)
            }
            
            // make sure all milestones not in set are not hidden
            QMilestoneStore.unhideMilestonesNotInMilestoneSet(milestonesSet, forAccountId: repository.account.identifier, repositoryId: repository.identifier)
        }
    }
    
    // MARK: Service calls
    
    private func fetchMilestones(pageNumber pageNumber: Int = 1, onCompletion: ( (NSError?) -> Void ) ) {
        
        if cancelled {
            onCompletion( NSError(domain: "co.cashewapp.RepositoryMilestonesSyncError", code: 0, userInfo: nil) )
            return;
        }
        
        repositoriesService.milestonesForRepository(repository, pageNumber: pageNumber, pageSize: RepositoryMilestoneSyncOperation.pageSize) { [weak self] (milestones, context, err) in
            guard let milestones = milestones as? [QMilestone], strongSelf = self where err == nil else {
                onCompletion(err)
                return
            }
            
            // save new milestones
            for milestone in milestones {
                guard !strongSelf.cancelled else { return }
                QMilestoneStore.saveMilestone(milestone)
                strongSelf.milestonesSet.remove(milestone)
            }
            
            if strongSelf.cancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryMilestonesSyncError", code: 0, userInfo: nil) )
                return;
            }
            
            // sleep if about to hit rate limit
            strongSelf.sleepIfNeededWithContext(context)
            
            // next page or complete operation
            if let nextPageNumber = context.nextPageNumber as? Int where !strongSelf.cancelled {
                strongSelf.fetchMilestones(pageNumber: nextPageNumber, onCompletion: onCompletion)
                
            } else if strongSelf.cancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryMilestonesSyncError", code: 0, userInfo: nil) )
                
            } else {
                onCompletion(nil)
            }
            
            
        }
        
    }
}
