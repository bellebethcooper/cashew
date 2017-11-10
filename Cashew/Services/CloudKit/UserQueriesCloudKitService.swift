//
//  UserQueriesCloudKitService.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/31/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import CloudKit

class UserQueriesCloudKitService: BaseCloudKitService {
    
    func saveUserQuery(userQuery: UserQuery, onCompletion: CloudOnCompletion) {
        let db = CKContainer.defaultContainer().publicCloudDatabase
        
        let container = CKContainer.defaultContainer()
        container.fetchUserRecordIDWithCompletionHandler { (currentUserId, err) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                
                guard let currentUserId = currentUserId else {
                    onCompletion(nil, nil)
                    return
                }
                
                guard let baseURL = userQuery.account.baseURL.absoluteString else {
                    onCompletion(nil, NSError(domain: "co.cashewapp.URLError", code: 0, userInfo: nil ))
                    return
                }
                let trimmedBaseURL = (baseURL as NSString).trimmedString()
                
                if let recordName = userQuery.externalId {
                    let recordId = CKRecordID(recordName: recordName)
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                        db.fetchRecordWithID(recordId, completionHandler: { (record, err) in
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                                guard let record = record where err == nil else {
                                    onCompletion(nil, err)
                                    return;
                                }
                                
                                if let isDeleted = record["deleted"] as? Bool, updatedAt = record.modificationDate ?? record.creationDate where !isDeleted && updatedAt != userQuery.updatedAt && userQuery.updatedAt != nil {
                                    onCompletion(userQuery, nil)
                                    return
                                }
                                
                                record["name"] = userQuery.displayName
                                record["query"] = userQuery.query
                                record["baseURL"] = trimmedBaseURL
                                record["userId"] = userQuery.account.userId
                                record["deleted"] = false
                                record["creatorId"] = currentUserId.recordName
                                
                                db.saveRecord(record, completionHandler: { (saveRecord, saveError) in
                                    guard let saveRecord = saveRecord where saveError == nil else {
                                        onCompletion(nil, saveError)
                                        return;
                                    }
                                    
                                    userQuery.externalId = saveRecord.recordID.recordName
                                    userQuery.updatedAt = saveRecord.modificationDate ?? saveRecord.modificationDate
                                    QUserQueryStore.saveUserQueryWithQuery(userQuery.query, account: userQuery.account, name: userQuery.displayName, externalId: userQuery.externalId, updatedAt: userQuery.updatedAt)
                                    onCompletion(userQuery, nil)
                                })
                                
                            }
                            
                        })
                    }
                } else {
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                        let container = CKContainer.defaultContainer()
                        let privateDatabase = container.publicCloudDatabase
                        let predicate = NSPredicate(format: "baseURL = %@ && name = %@ && userId = %@", trimmedBaseURL, userQuery.displayName, userQuery.account.userId)
                        let query = CKQuery(recordType: CloudRecordType.UserQuery.rawValue, predicate: predicate)
                        
                        privateDatabase.performQuery(query, inZoneWithID: nil) { (foundRecords, err) in
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                                //                        guard  else {
                                //                            DDLogDebug("error fetching records for repository -> \(err)")
                                //                            return
                                //                        }
                                if let firstRecord = foundRecords?.first where err == nil {
                                    firstRecord["name"] = userQuery.displayName
                                    firstRecord["query"] = userQuery.query
                                    firstRecord["baseURL"] = trimmedBaseURL
                                    firstRecord["userId"] = userQuery.account.userId
                                    firstRecord["deleted"] = false
                                    firstRecord["creatorId"] = currentUserId.recordName
                                    
                                    db.saveRecord(firstRecord, completionHandler: { (saveRecord, saveError) in
                                        guard let saveRecord = saveRecord where saveError == nil else {
                                            onCompletion(nil, saveError)
                                            return;
                                        }
                                        
                                        userQuery.externalId = saveRecord.recordID.recordName
                                        userQuery.updatedAt = saveRecord.modificationDate ?? saveRecord.modificationDate
                                        QUserQueryStore.saveUserQueryWithQuery(userQuery.query, account: userQuery.account, name: userQuery.displayName, externalId: userQuery.externalId, updatedAt: userQuery.updatedAt)
                                        onCompletion(userQuery, nil)
                                    })
                                    
                                } else {
                                    
                                    let record = CKRecord(recordType: CloudRecordType.UserQuery.rawValue)
                                    
                                    record["name"] = userQuery.displayName
                                    record["query"] = userQuery.query
                                    record["baseURL"] = trimmedBaseURL
                                    record["userId"] = userQuery.account.userId
                                    record["deleted"] = false
                                    record["creatorId"] = currentUserId.recordName
                                    
                                    db.saveRecord(record, completionHandler: { (saveRecord, saveError) in
                                        guard let saveRecord = saveRecord where saveError == nil else {
                                            onCompletion(nil, saveError)
                                            return;
                                        }
                                        
                                        userQuery.externalId = saveRecord.recordID.recordName
                                        userQuery.updatedAt = saveRecord.modificationDate ?? saveRecord.modificationDate
                                        QUserQueryStore.saveUserQueryWithQuery(userQuery.query, account: userQuery.account, name: userQuery.displayName, externalId: userQuery.externalId, updatedAt: userQuery.updatedAt)
                                        onCompletion(userQuery, nil)
                                    })
                                    
                                    
                                }
                            }
                        }
                    }
                    
                    
                }
            }
        }
    }
    
    func deleteUserQuery(userQuery: UserQuery, onCompletion: CloudOnCompletion) {
        let db = CKContainer.defaultContainer().publicCloudDatabase
        guard let recordName = userQuery.externalId else {
            onCompletion(userQuery, nil);
            return
        }
        
        let recordId = CKRecordID(recordName: recordName)
        
        db.fetchRecordWithID(recordId, completionHandler: { (currentRecord, err) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                guard let currentRecord = currentRecord where err == nil else {
                    onCompletion(nil, err)
                    return;
                }
                
                currentRecord["deleted"] = true
                
                db.saveRecord(currentRecord, completionHandler: { (record, saveError) in
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                        self.deleteDuplicateRecordsForUserQuery(userQuery)
                    }
                    
                    onCompletion(userQuery, saveError)
                })
            }
            
        })
    }
    
    private func deleteDuplicateRecordsForUserQuery(userQuery: UserQuery) {
        guard let baseURL = userQuery.account.baseURL.absoluteString else {
            //onCompletion(nil, NSError(domain: "co.cashewapp.URLError", code: 0, userInfo: nil ))
            return
        }
        let trimmedBaseURL = (baseURL as NSString).trimmedString()
        
        let container = CKContainer.defaultContainer()
        let privateDatabase = container.publicCloudDatabase
        let predicate = NSPredicate(format: "baseURL = %@ && name = %@ && userId = %@", trimmedBaseURL, userQuery.displayName, userQuery.account.userId)
        let query = CKQuery(recordType: CloudRecordType.UserQuery.rawValue, predicate: predicate)
        
        privateDatabase.performQuery(query, inZoneWithID: nil) { (foundRecords, err) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                guard err == nil else {
                    DDLogDebug("error fetching records for repository -> \(err)")
                    return
                }
                foundRecords?.forEach({ (record) in
                    if let isDeleted = record["deleted"] as? Bool where !isDeleted {
                        privateDatabase.deleteRecordWithID(record.recordID, completionHandler: { (record, err) in
                            DDLogDebug("Did delete duplicate user query record \(userQuery.displayName)")
                        })
                    }
                })
                
            }
        }
    }
    
    func syncUserQueriesForAccount(account: QAccount, onCompletion: CloudOnCompletion) {
        let container = CKContainer.defaultContainer()
        
        guard let baseURL = account.baseURL.absoluteString else {
            onCompletion(nil, NSError(domain: "co.cashewapp.URLError", code: 0, userInfo: nil ))
            return
        }
        let trimmedBaseURL = (baseURL as NSString).trimmedString()
        
        container.fetchUserRecordIDWithCompletionHandler { (currentUserId, err) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                
                guard let currentUserId = currentUserId where err == nil else {
                    onCompletion(nil, err)
                    return
                }
                
                let predicate = NSPredicate(format: "creatorId = %@", currentUserId.recordName)
                let query = CKQuery(recordType: CloudRecordType.UserQuery.rawValue, predicate: predicate)
                let db = CKContainer.defaultContainer().publicCloudDatabase
                
                db.performQuery(query, inZoneWithID: nil, completionHandler: { (records, queryErr) in
                    guard let records = records where queryErr == nil else {
                        onCompletion(nil, queryErr)
                        return;
                    }
                    
                    var userQueries = [UserQuery]()
                    records.forEach({ (record) in
                        
                        guard let baseURL = record["baseURL"] as? String, userId = record["userId"] as? NSNumber where baseURL == trimmedBaseURL && userId == account.userId else { return }
                        guard let displayName = record["name"] as? String, query = record["query"] as? String else { return }
                        
                        if let isDeleted = record["deleted"] as? Bool where isDeleted == true {
                            if let userQuery = QUserQueryStore.fetchUserQueryForAccount(account, name: displayName) as? UserQuery {
                                QUserQueryStore.deleteUserQuery(userQuery)
                            }
                        } else {
                            if let userQuery = QUserQueryStore.fetchUserQueryForAccount(account, name: displayName) as? UserQuery {
                                userQueries.append(userQuery)
                            } else {
                                QUserQueryStore.saveUserQueryWithQuery(query, account: account, name: displayName, externalId: record.recordID.recordName, updatedAt: record.modificationDate ?? record.creationDate)
                                
                                if let userQuery = QUserQueryStore.fetchUserQueryForAccount(account, name: displayName) as? UserQuery {
                                    userQueries.append(userQuery)
                                }
                            }
                        }
                    })
                    
                    onCompletion(userQueries, nil)
                })
            }
        }
        
    }
    
    
}
