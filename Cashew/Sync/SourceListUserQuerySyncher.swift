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
    
    //private(set) var isRunning = false
    private let sourceListCloudKitService = SourceListCloudKitService()
    private let serialOperationQueue = NSOperationQueue()
    private let userQueryCloudKitService = UserQueriesCloudKitService()
    
    deinit {
        QUserQueryStore.removeObserver(self)
    }
    
    required override init() {
        super.init()
        QUserQueryStore.addObserver(self)
        
        serialOperationQueue.name = "co.cashewapp.SourceListUserQuerySyncher"
        serialOperationQueue.maxConcurrentOperationCount = 1
    }
    
    func sync() {
        
        //isRunning = true
        
        legacyFetchOnceFromCloudKit()
        
        serialOperationQueue.addOperationWithBlock { [weak self] in
            guard let strongSelf = self else { return }
            
            let group = dispatch_group_create()
            
            // grab whatever is on server and save locally
            let accounts = QAccountStore.accounts()
            for account in accounts {
                dispatch_group_enter(group)
                strongSelf.userQueryCloudKitService.syncUserQueriesForAccount(account, onCompletion: { (records, err) in
                    dispatch_group_leave(group)
                })
            }
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
            
            // make sure what is stored locally is saved remotely
            for account in accounts {
                let userQueries = QUserQueryStore.fetchUserQueriesForAccount(account)
                userQueries.forEach({ (userQuery) in
                    guard let userQuery = userQuery as? UserQuery where userQuery.externalId == nil else { return }
                    dispatch_group_enter(group)
                    strongSelf.userQueryCloudKitService.saveUserQuery(userQuery, onCompletion: { (record, err) in
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
        dispatch_once(&SourceListUserQuerySyncher.dispatchlegacyFetchOnceToken) {
            let accounts = QAccountStore.accounts()
            for account in accounts {
                self.sourceListCloudKitService.fetchSourceListUserQueriesForAccount(account, legacyRecordType: .LegacySourceListUserQuery1, onCompletion: { (userQueries, err) in
                    guard let userQueries = userQueries as? [UserQuery] else { return }
                    userQueries.forEach { (userQuery) in
                        
                        self.sourceListCloudKitService.deleteSourceListUserQuery(userQuery, legacyRecordType: .LegacySourceListUserQuery1) { (deletedRecord, deletedRecordErr) in
                            assert(deletedRecordErr == nil)
                            NSLog("did delete record -> \(userQuery) \(deletedRecord) error \(deletedRecordErr)")
                        }
                    }
                })
                self.sourceListCloudKitService.fetchSourceListUserQueriesForAccount(account, legacyRecordType: .LegacySourceListUserQuery2, onCompletion: { (userQueries, err) in
                    guard let userQueries = userQueries as? [UserQuery] else { return }
                    userQueries.forEach { (userQuery) in
                        
                        self.sourceListCloudKitService.deleteSourceListUserQuery(userQuery, legacyRecordType: .LegacySourceListUserQuery2) { (deletedRecord, deletedRecordErr) in
                            assert(deletedRecordErr == nil)
                            NSLog("did delete record -> \(userQuery) \(deletedRecord) error \(deletedRecordErr)")
                        }
                    }
                })
            }
        }
    }
}

extension SourceListUserQuerySyncher: QStoreObserver {
    
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {
        guard let userQuery = record as? UserQuery else {
            return;
        }
        saveUserQueryToCloud(userQuery)
    }
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {
        guard let userQuery = record as? UserQuery else {
            return;
        }
        serialOperationQueue.addOperationWithBlock { [weak self] in
            guard let strongSelf = self else { return }
            let semaphore = dispatch_semaphore_create(0)
            //            strongSelf.sourceListCloudKitService.deleteSourceListUserQuery(userQuery) { (deletedRecord, err) in
            //                //DDLogDebug("cloud kit synched deleted userQuery: \(userQuery) with record \(deletedRecord) and err \(err)")
            //                dispatch_semaphore_signal(semaphore);
            //            }
            strongSelf.userQueryCloudKitService.deleteUserQuery(userQuery, onCompletion: { (deletedRecord, err) in
                dispatch_semaphore_signal(semaphore);
            })
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        
    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        
    }
    
    private func saveUserQueryToCloud(userQuery: UserQuery) {
        serialOperationQueue.addOperationWithBlock { [weak self] in
            guard let strongSelf = self else { return }
            let semaphore = dispatch_semaphore_create(0)
            //            strongSelf.sourceListCloudKitService.saveSourceListUserQuery(userQuery) { (createdRecord, err) in
            //                //DDLogDebug("cloud kit synched saved user query: \(userQuery) with record \(createdRecord) and err \(err)")
            //                dispatch_semaphore_signal(semaphore);
            //            }
            strongSelf.userQueryCloudKitService.saveUserQuery(userQuery, onCompletion: { (createdRecord, err) in
                dispatch_semaphore_signal(semaphore);
            })
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            //DDLogDebug("Done adding cloud userQuery \(userQuery)")
        }
    }
}
