//
//  SourceListUserQuerySyncher.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/3/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa


@objc(SRSourceListUserQuerySyncher)
class SourceListUserQuerySyncher: NSObject {
    
    private static var __once: () = {
        let accounts = QAccountStore.accounts()
        for account in accounts! {
//            self.sourceListCloudKitService.fetchSourceListUserQueriesForAccount(account, legacyRecordType: .LegacySourceListUserQuery1, onCompletion: { (userQueries, err) in
//                guard let userQueries = userQueries as? [UserQuery] else { return }
//                userQueries.forEach { (userQuery) in
//
//                    self.sourceListCloudKitService.deleteSourceListUserQuery(userQuery, legacyRecordType: .LegacySourceListUserQuery1) { (deletedRecord, deletedRecordErr) in
//                        assert(deletedRecordErr == nil)
//                        NSLog("did delete record -> \(userQuery) \(deletedRecord) error \(deletedRecordErr)")
//                    }
//                }
//            })
//            self.sourceListCloudKitService.fetchSourceListUserQueriesForAccount(account, legacyRecordType: .LegacySourceListUserQuery2, onCompletion: { (userQueries, err) in
//                guard let userQueries = userQueries as? [UserQuery] else { return }
//                userQueries.forEach { (userQuery) in
//                    
//                    self.sourceListCloudKitService.deleteSourceListUserQuery(userQuery, legacyRecordType: .LegacySourceListUserQuery2) { (deletedRecord, deletedRecordErr) in
//                        assert(deletedRecordErr == nil)
//                        NSLog("did delete record -> \(userQuery) \(deletedRecord) error \(deletedRecordErr)")
//                    }
//                }
//            })
        }
    }()
    
    //private(set) var isRunning = false
    fileprivate let sourceListCloudKitService = SourceListCloudKitService()
    fileprivate let serialOperationQueue = OperationQueue()
    fileprivate let userQueryCloudKitService = UserQueriesCloudKitService()
    
    deinit {
        QUserQueryStore.remove(self)
    }
    
    required override init() {
        super.init()
        QUserQueryStore.add(self)
        
        serialOperationQueue.name = "co.cashewapp.SourceListUserQuerySyncher"
        serialOperationQueue.maxConcurrentOperationCount = 1
    }
    
    func sync() {
        
        //isRunning = true
        
        legacyFetchOnceFromCloudKit()
        
        serialOperationQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }
            
            let group = DispatchGroup()
            
            // grab whatever is on server and save locally
            let accounts = QAccountStore.accounts()
            for account in accounts! {
                group.enter()
                strongSelf.userQueryCloudKitService.syncUserQueriesForAccount(account, onCompletion: { (records, err) in
                    group.leave()
                })
            }
            group.wait(timeout: .distantFuture)
            
            // make sure what is stored locally is saved remotely
            for account in accounts! {
                let userQueries = QUserQueryStore.fetchUserQueries(for: account)
                userQueries?.forEach({ (userQuery) in
                    guard let userQuery = userQuery as? UserQuery , userQuery.externalId == nil else { return }
                    group.enter()
                    strongSelf.userQueryCloudKitService.saveUserQuery(userQuery, onCompletion: { (record, err) in
                        group.leave()
                    })
                })
            }
            group.wait(timeout: .distantFuture)
        }
    }
    
//    func stop() {
//        isRunning = false
//    }
    
    fileprivate static var dispatchlegacyFetchOnceToken: Int = 0
    fileprivate func legacyFetchOnceFromCloudKit() {
        _ = SourceListUserQuerySyncher.__once
    }
}

extension SourceListUserQuerySyncher: QStoreObserver {
    
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {
        guard let userQuery = record as? UserQuery else {
            return;
        }
        saveUserQueryToCloud(userQuery)
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {
        guard let userQuery = record as? UserQuery else {
            return;
        }
        serialOperationQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }
            let semaphore = DispatchSemaphore(value: 0)
            //            strongSelf.sourceListCloudKitService.deleteSourceListUserQuery(userQuery) { (deletedRecord, err) in
            //                //DDLogDebug("cloud kit synched deleted userQuery: \(userQuery) with record \(deletedRecord) and err \(err)")
            //                dispatch_semaphore_signal(semaphore);
            //            }
            strongSelf.userQueryCloudKitService.deleteUserQuery(userQuery, onCompletion: { (deletedRecord, err) in
                semaphore.signal();
            })
            semaphore.wait(timeout: .distantFuture);
        }
        
    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        
    }
    
    fileprivate func saveUserQueryToCloud(_ userQuery: UserQuery) {
        serialOperationQueue.addOperation { [weak self] in
            guard let strongSelf = self else { return }
            let semaphore = DispatchSemaphore(value: 0)
            //            strongSelf.sourceListCloudKitService.saveSourceListUserQuery(userQuery) { (createdRecord, err) in
            //                //DDLogDebug("cloud kit synched saved user query: \(userQuery) with record \(createdRecord) and err \(err)")
            //                dispatch_semaphore_signal(semaphore);
            //            }
            strongSelf.userQueryCloudKitService.saveUserQuery(userQuery, onCompletion: { (createdRecord, err) in
                semaphore.signal();
            })
            semaphore.wait(timeout: .distantFuture);
            //DDLogDebug("Done adding cloud userQuery \(userQuery)")
        }
    }
}
