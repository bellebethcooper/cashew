//
//  RepositoryLabelSyncOperation.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class RepositoryLabelsSyncOperation: RepositoryBaseSyncOperation {
    
    fileprivate let repositoriesService: QRepositoriesService
    fileprivate var labelsSet = Set<QLabel>()
    
    let repository: QRepository
    
    
    required init(repository: QRepository) {
        self.repository = repository
        self.repositoriesService = QRepositoriesService(for: repository.account)
        super.init()
    }
    
    override func main() {
        
        // fetch local labels
        if let labels = QLabelStore.labels(forAccountId: repository.account.identifier, repositoryId: repository.identifier, includeHidden: true) {
            labels.forEach({ labelsSet.insert($0) })            
        }
        
        // fetch remote labels
        let semaphore = DispatchSemaphore(value: 0)
        var successful = true
        fetchLabels { [weak self] (err) in
            semaphore.signal()
            guard let strongSelf = self else { return }
            successful = (err == nil && !strongSelf.isCancelled)
        }
        semaphore.wait(timeout: DispatchTime.distantFuture)
        
        if successful {
            // hide labels that don't exist on server
            labelsSet.forEach { (label) in
                QLabelStore.hide(label)
            }
            
            // make sure all labels not in set are not hidden
            QLabelStore.unhideLabelsNot(inLabel: labelsSet, accountId: repository.account.identifier, repositoryId: repository.identifier)
        }
    }
    
    // MARK: Service calls
    
    fileprivate func fetchLabels(pageNumber: Int = 1, onCompletion: @escaping ( (NSError?) -> Void ) ) {
        
        if isCancelled {
            onCompletion( NSError(domain: "co.cashewapp.RepositoryLabelsSyncError", code: 0, userInfo: nil) )
            return;
        }
        
        repositoriesService.labels(for: repository, pageNumber: pageNumber, pageSize: RepositoryLabelsSyncOperation.pageSize) { [weak self] (labels, context, err) in
            guard let labels = labels as? [QLabel], let strongSelf = self , err == nil else {
                onCompletion(err as! NSError)
                return
            }
            
            // save new labels
            for label in labels {
                guard !strongSelf.isCancelled else { return }
                QLabelStore.save(label, allowUpdate: true)
                strongSelf.labelsSet.remove(label)
            }
            
            if strongSelf.isCancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryLabelsSyncError", code: 0, userInfo: nil) )
                return;
            }
            
            // sleep if about to hit rate limit
            strongSelf.sleepIfNeededWithContext(context)
            
            // next page or complete operation
            if let nextPageNumber = context.nextPageNumber as? Int , !strongSelf.isCancelled {
                strongSelf.fetchLabels(pageNumber: nextPageNumber, onCompletion: onCompletion)
                
            } else if strongSelf.isCancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryIssueSyncError", code: 0, userInfo: nil) )
                
            } else {
                onCompletion(nil)
            }
            
            
        }
        
    }
    
}
