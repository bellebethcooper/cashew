//
//  UserQueriesCloudKitService.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/31/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import CloudKit

class UserQueriesCloudKitService: BaseCloudKitService {
    
    func saveUserQuery(_ userQuery: UserQuery, onCompletion: @escaping CloudOnCompletion) {
//        let db = CKContainer.default().publicCloudDatabase
//
//        let container = CKContainer.default()
//        container.fetchUserRecordID { (currentUserId, err) in
//            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
//
//                guard let currentUserId = currentUserId else {
//                    onCompletion(nil, nil)
//                    return
//                }
//
//                let baseURL = userQuery.account.baseURL.absoluteString
//                let trimmedBaseURL = (baseURL as NSString).trimmedString()
//
//                if let recordName = userQuery.externalId {
//                    let recordId = CKRecordID(recordName: recordName)
//                    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
//                        db.fetch(withRecordID: recordId, completionHandler: { (record, err) in
//                            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
//                                guard let record = record , err == nil else {
//                                    onCompletion(nil, err as NSError?)
//                                    return;
//                                }
//
//                                if let isDeleted = record["deleted"] as? Bool, let updatedAt = record.modificationDate ?? record.creationDate , !isDeleted && updatedAt != userQuery.updatedAt && userQuery.updatedAt != nil {
//                                    onCompletion(userQuery, nil)
//                                    return
//                                }
//
//                                record["name"] = userQuery.displayName as CKRecordValue?
//                                record["query"] = userQuery.query as CKRecordValue?
//                                record["baseURL"] = trimmedBaseURL
//                                record["userId"] = userQuery.account.userId
//                                record["deleted"] = false as CKRecordValue?
//                                record["creatorId"] = currentUserId.recordName as CKRecordValue?
//
//                                db.save(record, completionHandler: { (saveRecord, saveError) in
//                                    guard let saveRecord = saveRecord , saveError == nil else {
//                                        onCompletion(nil, saveError as NSError?)
//                                        return;
//                                    }
//
//                                    userQuery.externalId = saveRecord.recordID.recordName
//                                    userQuery.updatedAt = saveRecord.modificationDate ?? saveRecord.modificationDate
//                                    QUserQueryStore.saveUserQuery(withQuery: userQuery.query, account: userQuery.account, name: userQuery.displayName, externalId: userQuery.externalId, updatedAt: userQuery.updatedAt)
//                                    onCompletion(userQuery, nil)
//                                })
//
//                            }
//
//                        })
//                    }
//                } else {
//
//                    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
//                        let container = CKContainer.default()
//                        let privateDatabase = container.publicCloudDatabase
//                        let predicate = NSPredicate(format: "baseURL = %@ && name = %@ && userId = %@", trimmedBaseURL, userQuery.displayName, userQuery.account.userId)
//                        let query = CKQuery(recordType: CloudRecordType.UserQuery.rawValue, predicate: predicate)
//
//                        privateDatabase.perform(query, inZoneWith: nil) { (foundRecords, err) in
//                            DispatchQueue.global(qos: .background).async {
//                                //                        guard  else {
//                                //                            DDLogDebug("error fetching records for repository -> \(err)")
//                                //                            return
//                                //                        }
//                                if let firstRecord = foundRecords?.first , err == nil {
//                                    firstRecord["name"] = userQuery.displayName as CKRecordValue
//                                    firstRecord["query"] = userQuery.query as CKRecordValue
//                                    firstRecord["baseURL"] = trimmedBaseURL
//                                    firstRecord["userId"] = userQuery.account.userId
//                                    firstRecord["deleted"] = false as CKRecordValue
//                                    firstRecord["creatorId"] = currentUserId.recordName as CKRecordValue
//
//                                    db.save(firstRecord, completionHandler: { (saveRecord, saveError) in
//                                        guard let saveRecord = saveRecord , saveError == nil else {
//                                            onCompletion(nil, saveError as! NSError)
//                                            return;
//                                        }
//
//                                        userQuery.externalId = saveRecord.recordID.recordName
//                                        userQuery.updatedAt = saveRecord.modificationDate ?? saveRecord.modificationDate
//                                        QUserQueryStore.saveUserQuery(withQuery: userQuery.query, account: userQuery.account, name: userQuery.displayName, externalId: userQuery.externalId, updatedAt: userQuery.updatedAt)
//                                        onCompletion(userQuery, nil)
//                                    })
//
//                                } else {
//
//                                    let record = CKRecord(recordType: CloudRecordType.UserQuery.rawValue)
//
//                                    record["name"] = userQuery.displayName as CKRecordValue
//                                    record["query"] = userQuery.query as CKRecordValue
//                                    record["baseURL"] = trimmedBaseURL
//                                    record["userId"] = userQuery.account.userId
//                                    record["deleted"] = false as CKRecordValue
//                                    record["creatorId"] = currentUserId.recordName as CKRecordValue
//
//                                    db.save(record, completionHandler: { (saveRecord, saveError) in
//                                        guard let saveRecord = saveRecord , saveError == nil else {
//                                            onCompletion(nil, saveError as! NSError)
//                                            return;
//                                        }
//
//                                        userQuery.externalId = saveRecord.recordID.recordName
//                                        userQuery.updatedAt = saveRecord.modificationDate ?? saveRecord.modificationDate
//                                        QUserQueryStore.saveUserQuery(withQuery: userQuery.query, account: userQuery.account, name: userQuery.displayName, externalId: userQuery.externalId, updatedAt: userQuery.updatedAt)
//                                        onCompletion(userQuery, nil)
//                                    })
//
//
//                                }
//                            }
//                        }
//                    }
//
//
//                }
//            }
//        }
    }
    
    func deleteUserQuery(_ userQuery: UserQuery, onCompletion: @escaping CloudOnCompletion) {
//        let db = CKContainer.default().publicCloudDatabase
//        guard let recordName = userQuery.externalId else {
//            onCompletion(userQuery, nil);
//            return
//        }
//
//        let recordId = CKRecordID(recordName: recordName)
//
//        db.fetch(withRecordID: recordId, completionHandler: { (currentRecord, err) in
//            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
//                guard let currentRecord = currentRecord , err == nil else {
//                    onCompletion(nil, err as NSError?)
//                    return;
//                }
//
//                currentRecord["deleted"] = true as CKRecordValue?
//
//                db.save(currentRecord, completionHandler: { (record, saveError) in
//                    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async {
//                        self.deleteDuplicateRecordsForUserQuery(userQuery)
//                    }
//
//                    onCompletion(userQuery, saveError as NSError?)
//                })
//            }
//
//        })
    }
    
    fileprivate func deleteDuplicateRecordsForUserQuery(_ userQuery: UserQuery) {
//        let baseURL = userQuery.account.baseURL.absoluteString
//        let trimmedBaseURL = (baseURL as NSString).trimmedString()
//
//        let container = CKContainer.default()
//        let privateDatabase = container.publicCloudDatabase
//        let predicate = NSPredicate(format: "baseURL = %@ && name = %@ && userId = %@", trimmedBaseURL, userQuery.displayName, userQuery.account.userId)
//        let query = CKQuery(recordType: CloudRecordType.UserQuery.rawValue, predicate: predicate)
//
//        privateDatabase.perform(query, inZoneWith: nil) { (foundRecords, err) in
//            DispatchQueue.global(qos: .background).async {
//                guard err == nil else {
//                    DDLogDebug("error fetching records for repository -> \(err)")
//                    return
//                }
//                foundRecords?.forEach({ (record) in
//                    if let isDeleted = record["deleted"] as? Bool , !isDeleted {
//                        privateDatabase.delete(withRecordID: record.recordID, completionHandler: { (record, err) in
//                            DDLogDebug("Did delete duplicate user query record \(userQuery.displayName)")
//                        })
//                    }
//                })
//
//            }
//        }
    }
    
    func syncUserQueriesForAccount(_ account: QAccount, onCompletion: @escaping CloudOnCompletion) {
//        let container = CKContainer.default()
//
//        let baseURL = account.baseURL.absoluteString
//        let trimmedBaseURL = (baseURL as NSString).trimmedString()
//
//        container.fetchUserRecordID { (currentUserId, err) in
//            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
//
//                guard let currentUserId = currentUserId , err == nil else {
//                    onCompletion(nil, err as NSError?)
//                    return
//                }
//
//                let predicate = NSPredicate(format: "creatorId = %@", currentUserId.recordName)
//                let query = CKQuery(recordType: CloudRecordType.UserQuery.rawValue, predicate: predicate)
//                let db = CKContainer.default().publicCloudDatabase
//
//                db.perform(query, inZoneWith: nil, completionHandler: { (records, queryErr) in
//                    guard let records = records , queryErr == nil else {
//                        onCompletion(nil, queryErr as NSError?)
//                        return;
//                    }
//
//                    var userQueries = [UserQuery]()
//                    records.forEach({ (record) in
//
////                        let baseURL = record["baseURL"] as? String,
////                            userId = record["userId"] as? NSNumber,
////                            baseURL == trimmedBaseURL as String && userId == account.userId
//                        guard let displayName = record["name"] as? String, let query = record["query"] as? String else { return }
//
//                        if let isDeleted = record["deleted"] as? Bool, isDeleted == true {
//                            if let userQuery = QUserQueryStore.fetchUserQuery(for: account, name: displayName) as? UserQuery {
//                                QUserQueryStore.deleteUserQuery(userQuery)
//                            }
//                        } else {
//                            if let userQuery = QUserQueryStore.fetchUserQuery(for: account, name: displayName) as? UserQuery {
//                                userQueries.append(userQuery)
//                            } else {
//                                QUserQueryStore.saveUserQuery(withQuery: query, account: account, name: displayName, externalId: record.recordID.recordName, updatedAt: record.modificationDate ?? record.creationDate)
//
//                                if let userQuery = QUserQueryStore.fetchUserQuery(for: account, name: displayName) as? UserQuery {
//                                    userQueries.append(userQuery)
//                                }
//                            }
//                        }
//                    })
//
//                    onCompletion(userQueries as AnyObject?, nil)
//                })
//            }
//        }
//
    }
    
    
}
