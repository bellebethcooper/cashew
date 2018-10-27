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
    
    private static var __once: () = {
            let accounts = QAccountStore.accounts()
        for account in accounts! {
//                self.sourceListCloudKitService.fetchSourceListRepositoriesForAccount(account, legacyRepoCloudType: .LegacySourceListRepository1, onCompletion: { (repos, err) in
//                    guard let repos = repos as? [QRepository] else { return }
//                    repos.forEach { (repo) in
//
//                        self.sourceListCloudKitService.deleteSourceListRepository(repo, legacyRepoCloudType: .LegacySourceListRepository1) { (deletedRecord, deletedRecordErr) in
//                            assert(deletedRecordErr == nil)
//                            NSLog("did delete record -> \(repo) \(deletedRecord) error \(deletedRecordErr)")
//                        }
//                    }
//                })
//                self.sourceListCloudKitService.fetchSourceListRepositoriesForAccount(account, legacyRepoCloudType: .LegacySourceListRepository2, onCompletion: { (repos, err) in
//                    guard let repos = repos as? [QRepository] else { return }
//                    repos.forEach { (repo) in
//                        self.sourceListCloudKitService.deleteSourceListRepository(repo, legacyRepoCloudType: .LegacySourceListRepository2) { (deletedRecord, deletedRecordErr) in
//                            assert(deletedRecordErr == nil)
//                            NSLog("did delete record -> \(repo) \(deletedRecord) error \(deletedRecordErr)")
//                        }
//                    }
//                })
            }
        }()
    
    fileprivate(set) var isRunning = false
    fileprivate let repositoriesCloudKitService = RepositoriesCloudKitService()
    
    fileprivate let sourceListCloudKitService = SourceListCloudKitService()
    fileprivate let serialOperationQueue = OperationQueue()
    
    deinit {
        QRepositoryStore.remove(self)
    }
    
    required override init() {
        super.init()
        QRepositoryStore.add(self)
        
        serialOperationQueue.name = "co.cashewapp.SourceListRepositorySyncer"
        serialOperationQueue.maxConcurrentOperationCount = 1
    }
    
    func sync() {
        
        //        isRunning = true
        
        legacyFetchOnceFromCloudKit()
        
        serialOperationQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }
            
            let group = DispatchGroup()
            
            // grab whatever is on server and save locally
            let accounts = QAccountStore.accounts()
            for account in accounts! {
                group.enter()
                strongSelf.repositoriesCloudKitService.syncRepositoriesForAccount(account, onCompletion: { (records, err) in
                    group.leave()
                })
            }
            group.wait(timeout: DispatchTime.distantFuture)
            
            // make sure what is stored locally is saved remotely
            for account in accounts! {
                let repositories = QRepositoryStore.repositories(forAccountId: account.identifier)
                repositories?.forEach({ (repository) in
                    guard repository.externalId == nil else { return }
                    group.enter()
                    strongSelf.repositoriesCloudKitService.saveRepository(repository, onCompletion: { (record, err) in
                        group.leave()
                    })
                })
            }
            group.wait(timeout: DispatchTime.distantFuture)
        }
    }
    
    //    func stop() {
    //        isRunning = false
    //    }
    
    fileprivate static var dispatchlegacyFetchOnceToken: Int = 0
    fileprivate func legacyFetchOnceFromCloudKit() {
        _ = SourceListRepositorySyncer.__once
    }
}

extension SourceListRepositorySyncer: QStoreObserver {
    
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {
        guard let repository = record as? QRepository else {
            return;
        }
        serialOperationQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }
            let semaphore = DispatchSemaphore(value: 0)
            //            strongSelf.sourceListCloudKitService.saveSourceListRepository(repository) { (createdRecord, err) in
            //                //DDLogDebug("cloud kit synched saved repository: \(repository) with record \(createdRecord) and err \(err)")
            //                dispatch_semaphore_signal(semaphore);
            //            }
            strongSelf.repositoriesCloudKitService.saveRepository(repository, onCompletion: { (record, err) in
                semaphore.signal();
            })
            semaphore.wait(timeout: DispatchTime.distantFuture);
            //DDLogDebug("Done adding cloud repository \(record)")
        }
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {
        guard let repository = record as? QRepository else {
            return;
        }
        serialOperationQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }
            let semaphore = DispatchSemaphore(value: 0)
            //            strongSelf.sourceListCloudKitService.deleteSourceListRepository(repository) { (deletedRecord, err) in
            //                //DDLogDebug("cloud kit synched deleted repository: \(repository) with record \(deletedRecord) and err \(err)")
            //                dispatch_semaphore_signal(semaphore);
            //            }
            strongSelf.repositoriesCloudKitService.delete(repository, onCompletion: { (record, err) in
                semaphore.signal();
            })
            semaphore.wait(timeout: DispatchTime.distantFuture);
            //DDLogDebug("Done removing cloud repository \(record)")
        }
        
    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        // DON'T add anything in here. otherwise, it's an infinite loop
    }
}


// legacy tables in ClouldKit
extension SourceListRepositorySyncer {
    
}
