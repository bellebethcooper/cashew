//
//  RepositoryLabelSyncOperation.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class RepositoryLabelsSyncOperation: RepositoryBaseSyncOperation {
    
    private let repositoriesService: QRepositoriesService
    private var labelsSet = Set<QLabel>()
    
    let repository: QRepository
    
    
    required init(repository: QRepository) {
        self.repository = repository
        self.repositoriesService = QRepositoriesService(forAccount: repository.account)
        super.init()
    }
    
    override func main() {
        
        // fetch local labels
        let labels = QLabelStore.labelsForAccountId(repository.account.identifier, repositoryId: repository.identifier, includeHidden: true)
        labels.forEach({ labelsSet.insert($0) })
        
        // fetch remote labels
        let semaphore = dispatch_semaphore_create(0)
        var successful = true
        fetchLabels { [weak self] (err) in
            dispatch_semaphore_signal(semaphore)
            guard let strongSelf = self else { return }
            successful = (err == nil && !strongSelf.cancelled)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        if successful {
            // hide labels that don't exist on server
            labelsSet.forEach { (label) in
                QLabelStore.hideLabel(label)
            }
            
            // make sure all labels not in set are not hidden
            QLabelStore.unhideLabelsNotInLabelSet(labelsSet, accountId: repository.account.identifier, repositoryId: repository.identifier)
        }
    }
    
    // MARK: Service calls
    
    private func fetchLabels(pageNumber pageNumber: Int = 1, onCompletion: ( (NSError?) -> Void ) ) {
        
        if cancelled {
            onCompletion( NSError(domain: "co.cashewapp.RepositoryLabelsSyncError", code: 0, userInfo: nil) )
            return;
        }
        
        repositoriesService.labelsForRepository(repository, pageNumber: pageNumber, pageSize: RepositoryLabelsSyncOperation.pageSize) { [weak self] (labels, context, err) in
            guard let labels = labels as? [QLabel], strongSelf = self where err == nil else {
                onCompletion(err)
                return
            }
            
            // save new labels
            for label in labels {
                guard !strongSelf.cancelled else { return }
                QLabelStore.saveLabel(label, allowUpdate: true)
                strongSelf.labelsSet.remove(label)
            }
            
            if strongSelf.cancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryLabelsSyncError", code: 0, userInfo: nil) )
                return;
            }
            
            // sleep if about to hit rate limit
            strongSelf.sleepIfNeededWithContext(context)
            
            // next page or complete operation
            if let nextPageNumber = context.nextPageNumber as? Int where !strongSelf.cancelled {
                strongSelf.fetchLabels(pageNumber: nextPageNumber, onCompletion: onCompletion)
                
            } else if strongSelf.cancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryIssueSyncError", code: 0, userInfo: nil) )
                
            } else {
                onCompletion(nil)
            }
            
            
        }
        
    }
    
}
