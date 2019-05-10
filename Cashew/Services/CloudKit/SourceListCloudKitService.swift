//
//  SourceListCloudKitService.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/3/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import CloudKit
import os.log

@objc(SRSourceListCloudKitService)
class SourceListCloudKitService: BaseCloudKitService {
    
    
    func deleteSourceListUserQuery(_ userQuery: UserQuery, legacyRecordType: CloudRecordType, onCompletion: @escaping CloudOnCompletion) {
//        let privateDatabase = CKContainer.default().publicCloudDatabase
//
//        fetchRecordsForUserQuery(userQuery, legacyRecordType: legacyRecordType) { (deleteRecords, err) in
//            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async(execute: {
//
//                guard let deleteRecords = deleteRecords as? [CKRecord] else {
//                    onCompletion(nil, err)
//                    return
//                }
//
//                let group = DispatchGroup()
//                var error: NSError? = nil
//                deleteRecords.forEach { (deleteRecord) in
//                    group.enter()
//                    privateDatabase.delete(withRecordID: deleteRecord.recordID, completionHandler: { (recordID, err) in
//                        error = err as NSError?
//                        group.leave()
//                    })
//                }
//                group.wait(timeout: .distantFuture);
//
//                onCompletion(deleteRecords as AnyObject?, error)
//            })
//        }
    }
    
    func fetchSourceListUserQueriesForAccount(_ account: QAccount, legacyRecordType: CloudRecordType, onCompletion: @escaping CloudOnCompletion) {
//        let baseURL = account.baseURL.absoluteString
//        let trimmedBaseURL = (baseURL as NSString).trimmedString()
//        let privateDatabase = CKContainer.default().publicCloudDatabase
//        let predicate = NSPredicate(format: "baseURL = %@ && userId = %@", trimmedBaseURL, account.userId)
//        let query = CKQuery(recordType: legacyRecordType.rawValue, predicate: predicate)
//        privateDatabase.perform(query, inZoneWith: nil) { [weak self] (records, err) in
//            guard let records = records , err == nil && records.count > 0 else {
//                onCompletion(nil, err as! NSError);
//                return
//            }
//            DispatchQueue.global().async {
//                self?.fetchUserQueriesForRecords(records, account: account, onCompletion: onCompletion);
//            }
//        }
    }
    
    fileprivate func fetchUserQueriesForRecords(_ records: [CKRecord], account: QAccount, onCompletion: CloudOnCompletion) {
//        var queries = [UserQuery]()
//        for record in records {
//            guard let query = record["query"] as? String, let name = record["name"] as? String else {
//                continue
//            }
//            //QUserQueryStore.saveUserQueryWithQuery(query, account: account, name: name)
//            let userQuery = UserQuery(identifier: nil, account: account, displayName: name, query: query)
//            queries.append(userQuery)
//        }
//
//        onCompletion(queries as AnyObject?, nil)
    }
    
    fileprivate func fetchRecordsForUserQuery(_ userQuery: UserQuery, legacyRecordType: CloudRecordType, onCompletion: @escaping CloudOnCompletion) {
//        let baseURL = userQuery.account.baseURL.absoluteString
//        let trimmedBaseURL = (baseURL as NSString).trimmedString()
//        let privateDatabase = CKContainer.default().publicCloudDatabase
//        let predicate = NSPredicate(format: "baseURL = %@ && name = %@ && userId = %@", trimmedBaseURL, userQuery.displayName, userQuery.account.userId)
//        let query = CKQuery(recordType: legacyRecordType.rawValue, predicate: predicate)
//
//        privateDatabase.perform(query, inZoneWith: nil) { (foundRecords, err) in
//            onCompletion(foundRecords as AnyObject, err as! NSError)
//        }
    }
    
    
}


extension SourceListCloudKitService {
    
    func fetchSourceListRepositoriesForAccount(_ account: QAccount, legacyRepoCloudType: CloudRecordType, onCompletion: @escaping CloudOnCompletion) {
        let baseURL = account.baseURL.absoluteString
        let trimmedBaseURL = (baseURL as NSString).trimmedString()
        let container = CKContainer.default()
        let privateDatabase = container.publicCloudDatabase
        let predicate = NSPredicate(format: "baseURL = %@ && userId = %@", trimmedBaseURL, account.userId)
        let query = CKQuery(recordType: legacyRepoCloudType.rawValue, predicate: predicate)
        privateDatabase.perform(query, inZoneWith: nil) { [weak self] (records, err) in
            guard let records = records , err == nil && records.count > 0 else {
                onCompletion(nil, err as! NSError);
                return
            }
            
            self?.fetchRepositoriesForRecords(records, account: account, onCompletion: onCompletion);
        }
    }
    
    
    fileprivate func fetchRepositoriesForRecords(_ records: [CKRecord], account: QAccount, onCompletion: CloudOnCompletion) {
        let group = DispatchGroup()
        let service = QRepositoriesService(for: account)
        var repositories = [QRepository]()
        let accessQueue = DispatchQueue(label: "SourceListCloudKitService.fetchRepositoriesForRecords", attributes: [])
        
        for record in records {
            guard let ownerLogin = record["ownerLogin"] as? String, let repositoryName = record["name"] as? String else {
                continue
            }
            
            let repo: QRepository? = QRepositoryStore.repository(forAccountId: account.identifier, ownerLogin: ownerLogin, repositoryName: repositoryName)
            
            if let repo = repo {
                
                accessQueue.sync(execute: {
                    repositories.append(repo)
                })
            } else {
                group.enter()
                service.repository(forOwnerLogin: ownerLogin, repositoryName: repositoryName, onCompletion: { (repo, context, err) in
                    guard let repo = repo as? QRepository , err == nil  else {
                        group.leave()
                        return
                    }
                    repo.account = account
                    QRepositoryStore.save(repo)
                    accessQueue.sync {
                        repositories.append(repo)
                    }
                    
                    group.leave()
                })
            }
        }
        
        group.wait(timeout: .distantFuture); // FIXME: probably a bad idea
        onCompletion(repositories as AnyObject, nil)
    }
    
    func deleteSourceListRepository(_ repository: QRepository, legacyRepoCloudType: CloudRecordType, onCompletion: @escaping CloudOnCompletion) {
        let container = CKContainer.default()
        let privateDatabase = container.publicCloudDatabase
        
        fetchRecordsForRepository(repository, legacyRepoCloudType: legacyRepoCloudType) { (deleteRecords, err) in
            guard let deleteRecords = deleteRecords as? [CKRecord] else {
                onCompletion(nil, err)
                return
                
            }
            DispatchQueue.global().async {
                let group = DispatchGroup()
                var error: NSError? = nil
                deleteRecords.forEach { (deleteRecord) in
                    group.enter()
                    //
                    privateDatabase.delete(withRecordID: deleteRecord.recordID, completionHandler: { (recordID, err) in
                        error = err as! NSError
                        group.leave()
                    })
                    //
                }
                group.wait(timeout: .distantFuture) // FIXME: probably a bad idea
                
                onCompletion(deleteRecords as AnyObject, error)
            }
        }
    }
    
    fileprivate func fetchRecordsForRepository(_ repository: QRepository, legacyRepoCloudType: CloudRecordType, onCompletion: @escaping CloudOnCompletion) {
        //        guard let baseURL = repository.account.baseURL.absoluteString else {
        //            onCompletion(nil, NSError(domain: "co.cashewapp.Cloud.InvalidBaseURL", code: 2345, userInfo: nil))
        //            return;
        //        }
        
        let baseURL = repository.account.baseURL.absoluteString
        let trimmedBaseURL = (baseURL as NSString).trimmedString()
        
        let container = CKContainer.default()
        let privateDatabase = container.publicCloudDatabase
        let predicate = NSPredicate(format: "baseURL = %@ && identifier = %@ && userId = %@", trimmedBaseURL, repository.identifier, repository.account.userId)
        let query = CKQuery(recordType: legacyRepoCloudType.rawValue, predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { (foundRecords, err) in
            guard err == nil else {
                os_log("error fetching records for repository -> %@", log: .default, type: .debug, err!.localizedDescription)
                onCompletion(nil, err as! NSError)
                return
            }
            onCompletion(foundRecords as AnyObject, nil)
        }
    }
    
    
}

