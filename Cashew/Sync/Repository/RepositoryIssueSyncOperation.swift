//
//  RepositorySyncOperation.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa


class RepositoryIssueSyncOperation: RepositoryBaseSyncOperation {
    
    private static let updatedSortKey = "updated"
    private static let createdSortKey = "created"
    
    private let issuesService: QIssuesService
    
    let repository: QRepository
    let sortKey: String
    let ascending: Bool
    let since: NSDate?
    
    required init(repository: QRepository) {
        self.repository = repository
        self.issuesService = QIssuesService(forAccount: repository.account)
        
        if let since = repository.deltaSyncDate where repository.initialSyncCompleted {
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
        
        let semaphore = dispatch_semaphore_create(0)
        
        fetchIssuesForRepository { [weak self] (err) in
            dispatch_semaphore_signal(semaphore)
            guard let strongSelf = self else { return }
            
            if err == nil && strongSelf.cancelled == false && strongSelf.repository.initialSyncCompleted == false {
                QRepositoryStore.markAsCompletedSyncForRepository(strongSelf.repository)
            }
        }
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
    }
    
    
    // MARK: Service calls
    
    private func fetchIssuesForRepository(pageNumber pageNumber: Int = 1, onCompletion: ((NSError?) -> Void)) {
        let pageSize = RepositoryIssueSyncOperation.pageSize
        
        if cancelled {
            onCompletion( NSError(domain: "co.cashewapp.RepositoryIssueSyncError", code: 0, userInfo: nil) )
            return;
        }
        
        issuesService.issuesForRepository(repository, pageNumber: pageNumber, pageSize: pageSize, sortKey: sortKey, ascending: ascending, since: since) { [weak self] (issues, context, err) in
            guard let strongSelf = self, issues = issues as? [QIssue] where err == nil else {
                onCompletion(err)
                return
            }
            
            // fetch existing issues
            let issueNumbers = issues.map({ $0.number })
            let existingIssuesList = QIssueStore.issuesWithNumbers(issueNumbers, forRepository: strongSelf.repository)
            var existingIssuesMap = [NSNumber: QIssue]()
            existingIssuesList.forEach({ (issue) in
                existingIssuesMap[issue.number] = issue
            })
            
            // save issues if not new
            for issue in issues {
                guard !strongSelf.cancelled else { break }
                var shouldSave = true
                
                if let existingIssue = existingIssuesMap[issue.number] where existingIssue.updatedAt == issue.updatedAt {
                    shouldSave = false
                }
                
                if shouldSave {
                    QIssueStore.saveIssue(issue)
                    let syncDate = issue.updatedAt ?? issue.createdAt
                    QRepositoryStore.saveDeltaSyncDate(syncDate, forRepository: strongSelf.repository)
                }
            }
            
            if strongSelf.cancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryIssueSyncError", code: 0, userInfo: nil) )
                return;
            }
            
            // sleep if about to hit rate limit
            strongSelf.sleepIfNeededWithContext(context)
            
            if let nextPageNumber = context.nextPageNumber as? Int where !strongSelf.cancelled {
                strongSelf.fetchIssuesForRepository(pageNumber: nextPageNumber, onCompletion: onCompletion)
                
            } else if strongSelf.cancelled {
                onCompletion( NSError(domain: "co.cashewapp.RepositoryIssueSyncError", code: 0, userInfo: nil) )
                
            } else {
                onCompletion(nil)
            }
            
        }
    }
    
}
