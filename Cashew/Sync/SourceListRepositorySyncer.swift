//
//  SourceListRepositorySyncer.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/3/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

@objc(SRSourceListRepositorySyncer)
class SourceListRepositorySyncer: NSObject {
    
    private(set) var isRunning = false
    private let repositoriesCloudKitService = RepositoriesCloudKitService()
    
    private let sourceListCloudKitService = SourceListCloudKitService()
    private let serialOperationQueue = NSOperationQueue()
    
    deinit {
        QRepositoryStore.removeObserver(self)
    }
    
    required override init() {
        super.init()
        QRepositoryStore.addObserver(self)
        
        serialOperationQueue.name = "co.cashewapp.SourceListRepositorySyncer"
        serialOperationQueue.maxConcurrentOperationCount = 1
    }
    
    func sync() {
        
        //        isRunning = true
        
        legacyFetchOnceFromCloudKit()
        
        serialOperationQueue.addOperationWithBlock { [weak self] in
            guard let strongSelf = self else { return }
            
            let group = dispatch_group_create()
            
            // grab whatever is on server and save locally
            let accounts = QAccountStore.accounts()
            for account in accounts {
                dispatch_group_enter(group)
                strongSelf.repositoriesCloudKitService.syncRepositoriesForAccount(account, onCompletion: { (records, err) in
                    dispatch_group_leave(group)
                })
            }
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
            
            // make sure what is stored locally is saved remotely
            for account in accounts {
                let repositories = QRepositoryStore.repositoriesForAccountId(account.identifier)
                repositories.forEach({ (repository) in
                    guard repository.externalId == nil else { return }
                    dispatch_group_enter(group)
                    strongSelf.repositoriesCloudKitService.saveRepository(repository, onCompletion: { (record, err) in
                        dispatch_group_leave(group)
                    })
                })
            }
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        }
    }
    
    //    func stop() {
    //        isRunning = false
    //    }
    
    private static var dispatchlegacyFetchOnceToken: dispatch_once_t = 0
    private func legacyFetchOnceFromCloudKit() {
        dispatch_once(&SourceListRepositorySyncer.dispatchlegacyFetchOnceToken) {
            let accounts = QAccountStore.accounts()
            for account in accounts {
                self.sourceListCloudKitService.fetchSourceListRepositoriesForAccount(account, legacyRepoCloudType: .LegacySourceListRepository1, onCompletion: { (repos, err) in
                    guard let repos = repos as? [QRepository] else { return }
                    repos.forEach { (repo) in
                        
                        self.sourceListCloudKitService.deleteSourceListRepository(repo, legacyRepoCloudType: .LegacySourceListRepository1) { (deletedRecord, deletedRecordErr) in
                            assert(deletedRecordErr == nil)
                            NSLog("did delete record -> \(repo) \(deletedRecord) error \(deletedRecordErr)")
                        }
                    }
                })
                self.sourceListCloudKitService.fetchSourceListRepositoriesForAccount(account, legacyRepoCloudType: .LegacySourceListRepository2, onCompletion: { (repos, err) in
                    guard let repos = repos as? [QRepository] else { return }
                    repos.forEach { (repo) in
                        self.sourceListCloudKitService.deleteSourceListRepository(repo, legacyRepoCloudType: .LegacySourceListRepository2) { (deletedRecord, deletedRecordErr) in
                            assert(deletedRecordErr == nil)
                            NSLog("did delete record -> \(repo) \(deletedRecord) error \(deletedRecordErr)")
                        }
                    }
                })
            }
        }
    }
}

extension SourceListRepositorySyncer: QStoreObserver {
    
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {
        guard let repository = record as? QRepository else {
            return;
        }
        serialOperationQueue.addOperationWithBlock { [weak self] in
            guard let strongSelf = self else { return }
            let semaphore = dispatch_semaphore_create(0)
            //            strongSelf.sourceListCloudKitService.saveSourceListRepository(repository) { (createdRecord, err) in
            //                //DDLogDebug("cloud kit synched saved repository: \(repository) with record \(createdRecord) and err \(err)")
            //                dispatch_semaphore_signal(semaphore);
            //            }
            strongSelf.repositoriesCloudKitService.saveRepository(repository, onCompletion: { (record, err) in
                dispatch_semaphore_signal(semaphore);
            })
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            //DDLogDebug("Done adding cloud repository \(record)")
        }
    }
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {
        guard let repository = record as? QRepository else {
            return;
        }
        serialOperationQueue.addOperationWithBlock { [weak self] in
            guard let strongSelf = self else { return }
            let semaphore = dispatch_semaphore_create(0)
            //            strongSelf.sourceListCloudKitService.deleteSourceListRepository(repository) { (deletedRecord, err) in
            //                //DDLogDebug("cloud kit synched deleted repository: \(repository) with record \(deletedRecord) and err \(err)")
            //                dispatch_semaphore_signal(semaphore);
            //            }
            strongSelf.repositoriesCloudKitService.deleteRepository(repository, onCompletion: { (record, err) in
                dispatch_semaphore_signal(semaphore);
            })
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            //DDLogDebug("Done removing cloud repository \(record)")
        }
        
    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        // DON'T add anything in here. otherwise, it's an infinite loop
    }
}


// legacy tables in ClouldKit
extension SourceListRepositorySyncer {
    
}
