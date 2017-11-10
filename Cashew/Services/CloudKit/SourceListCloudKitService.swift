//
//  SourceListCloudKitService.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/3/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import CloudKit


@objc(SRSourceListCloudKitService)
class SourceListCloudKitService: BaseCloudKitService {
    
    
    func deleteSourceListUserQuery(userQuery: UserQuery, legacyRecordType: CloudRecordType, onCompletion: CloudOnCompletion) {
        let privateDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        fetchRecordsForUserQuery(userQuery, legacyRecordType: legacyRecordType) { (deleteRecords, err) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                
                guard let deleteRecords = deleteRecords as? [CKRecord] else {
                    onCompletion(nil, err)
                    return
                }
                
                let group = dispatch_group_create()
                var error: NSError? = nil
                deleteRecords.forEach { (deleteRecord) in
                    dispatch_group_enter(group)
                    privateDatabase.deleteRecordWithID(deleteRecord.recordID, completionHandler: { (recordID, err) in
                        error = err
                        dispatch_group_leave(group)
                    })
                }
                dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
                
                onCompletion(deleteRecords, error)
            })
        }
    }
    
    func fetchSourceListUserQueriesForAccount(account: QAccount, legacyRecordType: CloudRecordType, onCompletion: CloudOnCompletion) {
        guard let baseURL = account.baseURL.absoluteString else { return }
        let trimmedBaseURL = (baseURL as NSString).trimmedString()
        let privateDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let predicate = NSPredicate(format: "baseURL = %@ && userId = %@", trimmedBaseURL, account.userId)
        let query = CKQuery(recordType: legacyRecordType.rawValue, predicate: predicate)
        privateDatabase.performQuery(query, inZoneWithID: nil) { [weak self] (records, err) in
            guard let records = records where err == nil && records.count > 0 else {
                onCompletion(nil, err);
                return
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                self?.fetchUserQueriesForRecords(records, account: account, onCompletion: onCompletion);
            }
        }
    }
    
    private func fetchUserQueriesForRecords(records: [CKRecord], account: QAccount, onCompletion: CloudOnCompletion) {
        var queries = [UserQuery]()
        for record in records {
            guard let query = record["query"] as? String, name = record["name"] as? String else {
                continue
            }
            //QUserQueryStore.saveUserQueryWithQuery(query, account: account, name: name)
            let userQuery = UserQuery(identifier: nil, account: account, displayName: name, query: query)
            queries.append(userQuery)
        }
        
        onCompletion(queries, nil)
    }
    
    private func fetchRecordsForUserQuery(userQuery: UserQuery, legacyRecordType: CloudRecordType, onCompletion: CloudOnCompletion) {
        guard let baseURL = userQuery.account.baseURL.absoluteString else { return }
        let trimmedBaseURL = (baseURL as NSString).trimmedString()
        let privateDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let predicate = NSPredicate(format: "baseURL = %@ && name = %@ && userId = %@", trimmedBaseURL, userQuery.displayName, userQuery.account.userId)
        let query = CKQuery(recordType: legacyRecordType.rawValue, predicate: predicate)
        
        privateDatabase.performQuery(query, inZoneWithID: nil) { (foundRecords, err) in
            onCompletion(foundRecords, err)
        }
    }
    
    
}


extension SourceListCloudKitService {
    
    func fetchSourceListRepositoriesForAccount(account: QAccount, legacyRepoCloudType: CloudRecordType, onCompletion: CloudOnCompletion) {
        guard let baseURL = account.baseURL.absoluteString else {
            onCompletion(nil, NSError(domain: "co.cashewapp.URLError", code: 0, userInfo: nil ))
            return
        }
        let trimmedBaseURL = (baseURL as NSString).trimmedString()
        let container = CKContainer.defaultContainer()
        let privateDatabase = container.publicCloudDatabase
        let predicate = NSPredicate(format: "baseURL = %@ && userId = %@", trimmedBaseURL, account.userId)
        let query = CKQuery(recordType: legacyRepoCloudType.rawValue, predicate: predicate)
        privateDatabase.performQuery(query, inZoneWithID: nil) { [weak self] (records, err) in
            guard let records = records where err == nil && records.count > 0 else {
                onCompletion(nil, err);
                return
            }
            
            self?.fetchRepositoriesForRecords(records, account: account, onCompletion: onCompletion);
        }
    }
    
    
    private func fetchRepositoriesForRecords(records: [CKRecord], account: QAccount, onCompletion: CloudOnCompletion) {
        let group = dispatch_group_create()
        let service = QRepositoriesService(forAccount: account)
        var repositories = [QRepository]()
        let accessQueue = dispatch_queue_create("SourceListCloudKitService.fetchRepositoriesForRecords", DISPATCH_QUEUE_SERIAL)
        
        for record in records {
            guard let ownerLogin = record["ownerLogin"] as? String, repositoryName = record["name"] as? String else {
                continue
            }
            
            let repo: QRepository? = QRepositoryStore.repositoryForAccountId(account.identifier, ownerLogin: ownerLogin, repositoryName: repositoryName)
            
            if let repo = repo {
                
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
                    QRepositoryStore.saveRepository(repo)
                    dispatch_sync(accessQueue, {
                        repositories.append(repo)
                    })
                    
                    dispatch_group_leave(group)
                })
            }
        }
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER); // FIXME: probably a bad idea
        onCompletion(repositories, nil)
    }
    
    func deleteSourceListRepository(repository: QRepository, legacyRepoCloudType: CloudRecordType, onCompletion: CloudOnCompletion) {
        let container = CKContainer.defaultContainer()
        let privateDatabase = container.publicCloudDatabase
        
        fetchRecordsForRepository(repository, legacyRepoCloudType: legacyRepoCloudType) { (deleteRecords, err) in
            guard let deleteRecords = deleteRecords as? [CKRecord] else {
                onCompletion(nil, err)
                return
                
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                let group = dispatch_group_create()
                var error: NSError? = nil
                deleteRecords.forEach { (deleteRecord) in
                    dispatch_group_enter(group)
                    //
                    privateDatabase.deleteRecordWithID(deleteRecord.recordID, completionHandler: { (recordID, err) in
                        error = err
                        dispatch_group_leave(group)
                    })
                    //
                }
                dispatch_group_wait(group, DISPATCH_TIME_FOREVER); // FIXME: probably a bad idea
                
                onCompletion(deleteRecords, error)
            })
        }
    }
    
    private func fetchRecordsForRepository(repository: QRepository, legacyRepoCloudType: CloudRecordType, onCompletion: CloudOnCompletion) {
        //        guard let baseURL = repository.account.baseURL.absoluteString else {
        //            onCompletion(nil, NSError(domain: "co.cashewapp.Cloud.InvalidBaseURL", code: 2345, userInfo: nil))
        //            return;
        //        }
        
        guard let baseURL = repository.account.baseURL.absoluteString else {
            onCompletion(nil, NSError(domain: "co.cashewapp.URLError", code: 0, userInfo: nil ))
            return
        }
        let trimmedBaseURL = (baseURL as NSString).trimmedString()
        
        let container = CKContainer.defaultContainer()
        let privateDatabase = container.publicCloudDatabase
        let predicate = NSPredicate(format: "baseURL = %@ && identifier = %@ && userId = %@", trimmedBaseURL, repository.identifier, repository.account.userId)
        let query = CKQuery(recordType: legacyRepoCloudType.rawValue, predicate: predicate)
        
        privateDatabase.performQuery(query, inZoneWithID: nil) { (foundRecords, err) in
            guard err == nil else {
                DDLogDebug("error fetching records for repository -> \(err)")
                onCompletion(nil, err)
                return
            }
            onCompletion(foundRecords, nil)
        }
    }
    
    
}

