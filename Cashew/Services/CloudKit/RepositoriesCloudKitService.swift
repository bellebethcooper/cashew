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
    
    func saveRepository(_ repository: QRepository, onCompletion: @escaping CloudOnCompletion) {
//        let db = CKContainer.default().publicCloudDatabase
//        let container = CKContainer.default()
//
//        let baseURL = repository.account.baseURL.absoluteString
//        let trimmedBaseURL = (baseURL as NSString).trimmedString()
//
//        container.fetchUserRecordID { (currentUserId, err) in
//            DispatchQueue.global(qos: .background).async {
//
//                guard let currentUserId = currentUserId else {
//                    onCompletion(nil, nil)
//                    return
//                }
//
//                if let recordName = repository.externalId {
//                    let recordId = CKRecordID(recordName: recordName)
//                    db.fetch(withRecordID: recordId, completionHandler: { (record, err) in
//                        DispatchQueue.global(qos: .background).async {
//                            guard let record = record , err == nil else {
//                                onCompletion(nil, err as! NSError)
//                                return;
//                            }
//
//                            if let isDeleted = record["deleted"] as? Bool, let updatedAt = record.modificationDate ?? record.creationDate , !isDeleted && updatedAt != repository.updatedAt && repository.updatedAt != nil {
//                                onCompletion(repository, nil)
//                                return
//                            }
//
//                            record["fullName"] = repository.fullName as! CKRecordValue
//                            record["ownerLogin"] = repository.owner.login as! CKRecordValue
//                            record["name"] = repository.name as! CKRecordValue
//                            record["identifier"] = repository.identifier
//                            record["baseURL"] = trimmedBaseURL
//                            record["userId"] = repository.account.userId
//                            record["deleted"] = false as CKRecordValue
//                            record["creatorId"] = currentUserId.recordName as CKRecordValue
//
//                            db.save(record, completionHandler: { (saveRecord, saveError) in
//                                guard let saveRecord = saveRecord , saveError == nil else {
//                                    onCompletion(nil, saveError as! NSError)
//                                    return;
//                                }
//
//                                repository.externalId = saveRecord.recordID.recordName
//                                repository.updatedAt = saveRecord.modificationDate ?? saveRecord.modificationDate
//                                QRepositoryStore.save(repository)
//                                onCompletion(repository, nil)
//                            })
//
//                        }
//
//                    })
//                } else {
//
//                    let record = CKRecord(recordType: CloudRecordType.Repository.rawValue)
//
//                    record["fullName"] = repository.fullName as! CKRecordValue
//                    record["ownerLogin"] = repository.owner.login as! CKRecordValue
//                    record["name"] = repository.name as! CKRecordValue
//                    record["identifier"] = repository.identifier
//                    record["baseURL"] = trimmedBaseURL
//                    record["userId"] = repository.account.userId
//                    record["deleted"] = false as CKRecordValue?
//                    record["creatorId"] = currentUserId.recordName as CKRecordValue?
//
//                    db.save(record, completionHandler: { (saveRecord, saveError) in
//                        guard let saveRecord = saveRecord , saveError == nil else {
//                            onCompletion(nil, saveError as NSError?)
//                            return;
//                        }
//
//                        repository.externalId = saveRecord.recordID.recordName
//                        repository.updatedAt = saveRecord.modificationDate ?? saveRecord.modificationDate
//                        QRepositoryStore.save(repository)
//                        onCompletion(repository, nil)
//                    })
//                }
//            }
//        }
    }
    
    func delete(_ repository: QRepository, onCompletion: @escaping CloudOnCompletion) {
//        let db = CKContainer.default().publicCloudDatabase
//        guard let recordName = repository.externalId else {
//            onCompletion(repository, nil);
//            return
//        }
//
//        let recordId = CKRecordID(recordName: recordName)
//
//        db.fetch(withRecordID: recordId, completionHandler: { (currentRecord, err) in
//            DispatchQueue.global(qos: .background).async {
//                guard let currentRecord = currentRecord , err == nil else {
//                    onCompletion(nil, err as! NSError)
//                    return;
//                }
//
//                currentRecord["deleted"] = true as CKRecordValue
//
//                db.save(currentRecord, completionHandler: { (record, saveError) in
//                    DispatchQueue.global(qos: .background).async {
//                        self.deleteDuplicateRecordsForRepository(repository)
//                    }
//
//                    onCompletion(repository, saveError as! NSError)
//                })
//            }
//
//        })
    }
    
    fileprivate func deleteDuplicateRecordsForRepository(_ repository: QRepository) {
//        let baseURL = repository.account.baseURL.absoluteString
//        let trimmedBaseURL = (baseURL as NSString).trimmedString()
//        let container = CKContainer.default()
//        let privateDatabase = container.publicCloudDatabase
//        let predicate = NSPredicate(format: "baseURL = %@ && identifier = %@ && userId = %@", trimmedBaseURL, repository.identifier, repository.account.userId)
//        let query = CKQuery(recordType: CloudRecordType.Repository.rawValue, predicate: predicate)
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
//                            DDLogDebug("Did delete duplicate repository record \(repository.fullName)")
//                        })
//                        // privateDatabase.deleteRecordWithID(record.recordID
//                    }
//                })
//
//            }
//        }
    }
    
    
    @objc func syncRepositoriesForAccount(_ account: QAccount, onCompletion: @escaping CloudOnCompletion) {
//        let container = CKContainer.default()
//        let group = DispatchGroup()
//        let service = QRepositoriesService(for: account)
//        let accessQueue = DispatchQueue(label: "co.cashewapp.RepositoriesCloudKitService.syncRepositoriesForAccount", attributes: [])
//        let baseURL = account.baseURL.absoluteString
//        let trimmedBaseURL = (baseURL as NSString).trimmedString()
//        
//        container.fetchUserRecordID { (currentUserId, err) in
//            DispatchQueue.global(qos: .background).async {
//                
//                guard let currentUserId = currentUserId , err == nil else {
//                    onCompletion(nil, err as NSError?)
//                    return
//                }
//                
//                let predicate = NSPredicate(format: "creatorId = %@", currentUserId.recordName)
//                let query = CKQuery(recordType: CloudRecordType.Repository.rawValue, predicate: predicate)
//                let db = CKContainer.default().publicCloudDatabase
//                
//                db.perform(query, inZoneWith: nil, completionHandler: { (records, queryErr) in
//                    guard let records = records , queryErr == nil else {
//                        onCompletion(nil, queryErr as NSError?)
//                        return;
//                    }
//                    
//                    var repositories = [QRepository]()
//                    records.forEach({ (record) in
//                        
//                        guard let baseURL = record["baseURL"] as? String, let userId = record["userId"] as? NSNumber , baseURL == trimmedBaseURL as String && userId == account.userId else { return }
//                        guard let fullName = record["fullName"] as? String, let ownerLogin = record["ownerLogin"] as? String, let repositoryName = record["name"] as? String  else { return }
//                        
//                        if let isDeleted = record["deleted"] as? Bool , isDeleted == true {
//                            if let existingRepo = QRepositoryStore.repository(forAccountId: account.identifier, fullName: fullName) {
//                                QRepositoryStore.delete(existingRepo)
//                            }
//                        } else {
//                            if let repo = QRepositoryStore.repository(forAccountId: account.identifier, fullName: fullName) {
//                                accessQueue.sync(execute: {
//                                    repositories.append(repo)
//                                })
//                            } else {
//                                group.enter()
//                                service.repository(forOwnerLogin: ownerLogin, repositoryName: repositoryName, onCompletion: { (repo, context, err) in
//                                    guard let repo = repo as? QRepository , err == nil  else {
//                                        group.leave()
//                                        return
//                                    }
//                                    repo.account = account
//                                    repo.updatedAt = record.modificationDate ?? record.creationDate
//                                    repo.externalId = record.recordID.recordName
//                                    QRepositoryStore.save(repo)
//                                    accessQueue.sync {
//                                        repositories.append(repo)
//                                    }
//                                    
//                                    group.leave()
//                                })
//                                
//                            }
//                        }
//                    })
//                    
//                    group.wait(timeout: .distantFuture)
//                    onCompletion(repositories as AnyObject, nil)
//                })
//            }
//        }
//        
    }
    
}
