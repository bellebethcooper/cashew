//
//  RepositoriesCloudKitService.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/29/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import CloudKit

@objc(SRRepositoriesCloudKitService)
class RepositoriesCloudKitService: BaseCloudKitService {
    
    func saveRepository(repository: QRepository, onCompletion: CloudOnCompletion) {
        let db = CKContainer.defaultContainer().publicCloudDatabase
        let container = CKContainer.defaultContainer()
        
        guard let baseURL = repository.account.baseURL.absoluteString else {
            onCompletion(nil, NSError(domain: "co.cashewapp.missingURL", code: 0, userInfo: nil))
            return
        }
        let trimmedBaseURL = (baseURL as NSString).trimmedString()
        
        container.fetchUserRecordIDWithCompletionHandler { (currentUserId, err) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                
                guard let currentUserId = currentUserId else {
                    onCompletion(nil, nil)
                    return
                }
                
                if let recordName = repository.externalId {
                    let recordId = CKRecordID(recordName: recordName)
                    db.fetchRecordWithID(recordId, completionHandler: { (record, err) in
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                            guard let record = record where err == nil else {
                                onCompletion(nil, err)
                                return;
                            }
                            
                            if let isDeleted = record["deleted"] as? Bool, updatedAt = record.modificationDate ?? record.creationDate where !isDeleted && updatedAt != repository.updatedAt && repository.updatedAt != nil {
                                onCompletion(repository, nil)
                                return
                            }
                            
                            record["fullName"] = repository.fullName
                            record["ownerLogin"] = repository.owner.login
                            record["name"] = repository.name
                            record["identifier"] = repository.identifier
                            record["baseURL"] = trimmedBaseURL
                            record["userId"] = repository.account.userId
                            record["deleted"] = false
                            record["creatorId"] = currentUserId.recordName
                            
                            db.saveRecord(record, completionHandler: { (saveRecord, saveError) in
                                guard let saveRecord = saveRecord where saveError == nil else {
                                    onCompletion(nil, saveError)
                                    return;
                                }
                                
                                repository.externalId = saveRecord.recordID.recordName
                                repository.updatedAt = saveRecord.modificationDate ?? saveRecord.modificationDate
                                QRepositoryStore.saveRepository(repository)
                                onCompletion(repository, nil)
                            })
                            
                        }
                        
                    })
                } else {
                    
                    let record = CKRecord(recordType: CloudRecordType.Repository.rawValue)
                    
                    record["fullName"] = repository.fullName
                    record["ownerLogin"] = repository.owner.login
                    record["name"] = repository.name
                    record["identifier"] = repository.identifier
                    record["baseURL"] = trimmedBaseURL
                    record["userId"] = repository.account.userId
                    record["deleted"] = false
                    record["creatorId"] = currentUserId.recordName
                    
                    db.saveRecord(record, completionHandler: { (saveRecord, saveError) in
                        guard let saveRecord = saveRecord where saveError == nil else {
                            onCompletion(nil, saveError)
                            return;
                        }
                        
                        repository.externalId = saveRecord.recordID.recordName
                        repository.updatedAt = saveRecord.modificationDate ?? saveRecord.modificationDate
                        QRepositoryStore.saveRepository(repository)
                        onCompletion(repository, nil)
                    })
                }
            }
        }
    }
    
    func deleteRepository(repository: QRepository, onCompletion: CloudOnCompletion) {
        let db = CKContainer.defaultContainer().publicCloudDatabase
        guard let recordName = repository.externalId else {
            onCompletion(repository, nil);
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
                        self.deleteDuplicateRecordsForRepository(repository)
                    }
                    
                    onCompletion(repository, saveError)
                })
            }
            
        })
    }
    
    private func deleteDuplicateRecordsForRepository(repository: QRepository) {
        guard let baseURL = repository.account.baseURL.absoluteString else { return }
        let trimmedBaseURL = (baseURL as NSString).trimmedString()
        
        let container = CKContainer.defaultContainer()
        let privateDatabase = container.publicCloudDatabase
        let predicate = NSPredicate(format: "baseURL = %@ && identifier = %@ && userId = %@", trimmedBaseURL, repository.identifier, repository.account.userId)
        let query = CKQuery(recordType: CloudRecordType.Repository.rawValue, predicate: predicate)
        
        privateDatabase.performQuery(query, inZoneWithID: nil) { (foundRecords, err) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                guard err == nil else {
                    DDLogDebug("error fetching records for repository -> \(err)")
                    return
                }
                foundRecords?.forEach({ (record) in
                    if let isDeleted = record["deleted"] as? Bool where !isDeleted {
                        privateDatabase.deleteRecordWithID(record.recordID, completionHandler: { (record, err) in
                            DDLogDebug("Did delete duplicate repository record \(repository.fullName)")
                        })
                        // privateDatabase.deleteRecordWithID(record.recordID
                    }
                })
                
            }
        }
    }
    
    
    func syncRepositoriesForAccount(account: QAccount, onCompletion: CloudOnCompletion) {
        let container = CKContainer.defaultContainer()
        let group = dispatch_group_create()
        let service = QRepositoriesService(forAccount: account)
        let accessQueue = dispatch_queue_create("co.cashewapp.RepositoriesCloudKitService.syncRepositoriesForAccount", DISPATCH_QUEUE_SERIAL)
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
                let query = CKQuery(recordType: CloudRecordType.Repository.rawValue, predicate: predicate)
                let db = CKContainer.defaultContainer().publicCloudDatabase
                
                db.performQuery(query, inZoneWithID: nil, completionHandler: { (records, queryErr) in
                    guard let records = records where queryErr == nil else {
                        onCompletion(nil, queryErr)
                        return;
                    }
                    
                    var repositories = [QRepository]()
                    records.forEach({ (record) in
                        
                        guard let baseURL = record["baseURL"] as? String, userId = record["userId"] as? NSNumber where baseURL == trimmedBaseURL && userId == account.userId else { return }
                        guard let fullName = record["fullName"] as? String, ownerLogin = record["ownerLogin"] as? String, repositoryName = record["name"] as? String  else { return }
                        
                        if let isDeleted = record["deleted"] as? Bool where isDeleted == true {
                            if let existingRepo = QRepositoryStore.repositoryForAccountId(account.identifier, fullName: fullName) {
                                QRepositoryStore.deleteRepository(existingRepo)
                            }
                        } else {
                            if let repo = QRepositoryStore.repositoryForAccountId(account.identifier, fullName: fullName) {
                                dispatch_sync(accessQueue, {
                                    repositories.append(repo)
                                })
                            } else {
                                dispatch_group_enter(group)
                                service.repositoryForOwnerLogin(ownerLogin, repositoryName: repositoryName, onCompletion: { (repo, context, err) in
                                    guard let repo = repo as? QRepository where err == nil  else {
                                        dispatch_group_leave(group)
                                        return
                                    }
                                    repo.account = account
                                    repo.updatedAt = record.modificationDate ?? record.creationDate
                                    repo.externalId = record.recordID.recordName
                                    QRepositoryStore.saveRepository(repo)
                                    dispatch_sync(accessQueue, {
                                        repositories.append(repo)
                                    })
                                    
                                    dispatch_group_leave(group)
                                })
                                
                            }
                        }
                    })
                    
                    dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
                    onCompletion(repositories, nil)
                })
            }
        }
        
    }
    
}
