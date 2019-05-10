//
//  RepositorySyncOperation.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa


class RepositoryIssueSyncOperation: RepositoryBaseSyncOperation {
    
    fileprivate static let updatedSortKey = "updated"
    fileprivate static let createdSortKey = "created"
    
    fileprivate let issuesService: QIssuesService
    
    let repository: QRepository
    let sortKey: String
    let ascending: Bool
    let since: Date?
    
    required init(repository: QRepository) {
        self.repository = repository
        self.issuesService = QIssuesService(for: repository.account)
        
        if let since = repository.deltaSyncDate , repository.initialSyncCompleted {
            self.since = since
            self.sortKey = RepositoryIssueSyncOperation.updatedSortKey
            self.ascending = true
        } else {
            self.since = nil
            self.sortKey = RepositoryIssueSyncOperation.createdSortKey
            self.ascending = false
        }
        
        super.init()
    }
    
    
    override func main() {
        
        let semaphore = DispatchSemaphore(value: 0)
        
        fetchIssuesForRepository { [weak self] (err) in
            semaphore.signal()
            guard let strongSelf = self else { return }
            
            if err == nil && strongSelf.isCancelled == false && strongSelf.repository.initialSyncCompleted == false {
                QRepositoryStore.markAsCompletedSync(for: strongSelf.repository)
            }
        }
        
        semaphore.wait(timeout: .distantFuture)
        
    }
    
    
    // MARK: Service calls
    
    fileprivate func fetchIssuesForRepository(pageNumber: Int = 1, onCompletion: @escaping ((NSError?) -> Void)) {
        let pageSize = RepositoryIssueSyncOperation.pageSize
        
        if isCancelled {
            onCompletion( NSError(domain: "co.cashewapp.RepositoryIssueSyncError", code: 0, userInfo: nil) )
            return;
        }
        
        issuesService.issues(for: repository, pageNumber: pageNumber, pageSize: pageSize, sortKey: sortKey, ascending: ascending, since: since) { [weak self] (issues, context, err) in
            guard let strongSelf = self, let issues = issues as? [QIssue] , err == nil else {
                onCompletion(err as! NSError)
                return
            }
            
            // fetch existing issues
            let issueNumbers = issues.map({ $0.number })
            let existingIssuesList = QIssueStore.issues(with: issueNumbers, for: strongSelf.repository)
            var existingIssuesMap = [NSNumber: QIssue]()
            existingIssuesList?.forEach({ (issue) in
                existingIssuesMap[issue.number] = issue
            })
            
            // save issues if not new
            for issue in issues {
                guard !strongSelf.isCancelled else { break }
                var shouldSave = true
                
                if let existingIssue = existingIssuesMap[issue.number] , existingIssue.updatedAt == issue.updatedAt {
                    shouldSave = false
                }
                
                if shouldSave {
                    QIssueStore.save(issue)
                    let syncDate = issue.updatedAt
                    QRepositoryStore.saveDeltaSyncDate(syncDate, for: strongSelf.repository)
                }
            }
            
            if strongSelf.isCancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryIssueSyncError", code: 0, userInfo: nil) )
                return;
            }
            
            // sleep if about to hit rate limit
            strongSelf.sleepIfNeededWithContext(context)
            
            if let nextPageNumber = context.nextPageNumber as? Int , !strongSelf.isCancelled {
                strongSelf.fetchIssuesForRepository(pageNumber: nextPageNumber, onCompletion: onCompletion)
                
            } else if strongSelf.isCancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryIssueSyncError", code: 0, userInfo: nil) )
                
            } else {
                onCompletion(nil)
            }
            
        }
    }
    
}
