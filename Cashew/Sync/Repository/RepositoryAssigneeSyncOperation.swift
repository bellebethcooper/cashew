//
//  RepositoryAssigneeSyncOperation.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class RepositoryAssigneeSyncOperation: RepositoryBaseSyncOperation {
    
    fileprivate let repositoriesService: QRepositoriesService
    fileprivate var ownersSet = Set<QOwner>()
    
    let repository: QRepository
    
    required init(repository: QRepository) {
        self.repository = repository
        self.repositoriesService = QRepositoriesService(for: repository.account)
        super.init()
    }
    
    override func main() {
        
        // fetch local assignees
        let owners = QOwnerStore.owners(forAccountId: repository.account.identifier, repositoryId: repository.identifier)
        owners?.forEach({ ownersSet.insert($0) })
        
        // fetch remote assignees
        let semaphore = DispatchSemaphore(value: 0)
        var successful = true
        fetchAssignees { [weak self] (err) in
            semaphore.signal()
            guard let strongSelf = self else { return }
            successful = (err == nil && !strongSelf.isCancelled)
        }
        semaphore.wait(timeout: .distantFuture)
        
        if successful {
            ownersSet.forEach { (owner) in
                QRepositoryStore.deleteAssignee(owner, for: repository)
            }
        }
        
    }
    
    // MARK: Service calls
    
    fileprivate func fetchAssignees(pageNumber: Int = 1, onCompletion: @escaping ( (NSError?) -> Void ) ) {
        
        if isCancelled {
            onCompletion( NSError(domain: "co.cashewapp.RepositoryAssigneesSyncError", code: 0, userInfo: nil) )
            return;
        }
        
        repositoriesService.assignees(for: repository, pageNumber: pageNumber, pageSize: RepositoryAssigneeSyncOperation.pageSize) { [weak self] (owners, context, err) in
            guard let owners = owners as? [QOwner], let strongSelf = self , err == nil else {
                onCompletion(err as? NSError)
                return
            }
            
            // save new owners
            for owner in owners {
                guard !strongSelf.isCancelled else { return }
                QRepositoryStore.saveAssignee(owner, for: strongSelf.repository)
                strongSelf.ownersSet.remove(owner)
            }
            
            if strongSelf.isCancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryAssigneesSyncError", code: 0, userInfo: nil) )
                return;
            }
            
            // sleep if about to hit rate limit
            strongSelf.sleepIfNeededWithContext(context)
            
            
            // next page or complete operation
            if let nextPageNumber = context.nextPageNumber as? Int , !strongSelf.isCancelled {
                strongSelf.fetchAssignees(pageNumber: nextPageNumber, onCompletion: onCompletion)
                
            } else if strongSelf.isCancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryAssigneesSyncError", code: 0, userInfo: nil) )
                
            } else {
                onCompletion(nil)
            }
            
            
        }
        
    }
    
}
