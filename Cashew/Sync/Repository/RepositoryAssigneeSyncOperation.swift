//
//  RepositoryAssigneeSyncOperation.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class RepositoryAssigneeSyncOperation: RepositoryBaseSyncOperation {
    
    private let repositoriesService: QRepositoriesService
    private var ownersSet = Set<QOwner>()
    
    let repository: QRepository
    
    required init(repository: QRepository) {
        self.repository = repository
        self.repositoriesService = QRepositoriesService(forAccount: repository.account)
        super.init()
    }
    
    override func main() {
        
        // fetch local assignees
        let owners = QOwnerStore.ownersForAccountId(repository.account.identifier, repositoryId: repository.identifier)
        owners.forEach({ ownersSet.insert($0) })
        
        // fetch remote assignees
        let semaphore = dispatch_semaphore_create(0)
        var successful = true
        fetchAssignees { [weak self] (err) in
            dispatch_semaphore_signal(semaphore)
            guard let strongSelf = self else { return }
            successful = (err == nil && !strongSelf.cancelled)
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        if successful {
            ownersSet.forEach { (owner) in
                QRepositoryStore.deleteAssignee(owner, forRepository: repository)
            }
        }
        
    }
    
    // MARK: Service calls
    
    private func fetchAssignees(pageNumber pageNumber: Int = 1, onCompletion: ( (NSError?) -> Void ) ) {
        
        if cancelled {
            onCompletion( NSError(domain: "co.cashewapp.RepositoryAssigneesSyncError", code: 0, userInfo: nil) )
            return;
        }
        
        repositoriesService.assigneesForRepository(repository, pageNumber: pageNumber, pageSize: RepositoryAssigneeSyncOperation.pageSize) { [weak self] (owners, context, err) in
            guard let owners = owners as? [QOwner], strongSelf = self where err == nil else {
                onCompletion(err)
                return
            }
            
            // save new owners
            for owner in owners {
                guard !strongSelf.cancelled else { return }
                QRepositoryStore.saveAssignee(owner, forRepository: strongSelf.repository)
                strongSelf.ownersSet.remove(owner)
            }
            
            if strongSelf.cancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryAssigneesSyncError", code: 0, userInfo: nil) )
                return;
            }
            
            // sleep if about to hit rate limit
            strongSelf.sleepIfNeededWithContext(context)
            
            
            // next page or complete operation
            if let nextPageNumber = context.nextPageNumber as? Int where !strongSelf.cancelled {
                strongSelf.fetchAssignees(pageNumber: nextPageNumber, onCompletion: onCompletion)
                
            } else if strongSelf.cancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryAssigneesSyncError", code: 0, userInfo: nil) )
                
            } else {
                onCompletion(nil)
            }
            
            
        }
        
    }
    
}
