//
//  QIssuesViewDataSource.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/31/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc protocol QIssuesViewDataSourceDelegate: class {
    func dataSource(dataSource: QIssuesViewDataSource?, didInsertIndexSet: NSIndexSet, forFilter: QIssueFilter);
    func dataSource(dataSource: QIssuesViewDataSource?, didDeleteIndexSet: NSIndexSet, forFilter: QIssueFilter);
    
}

class QIssuesViewDataSource: NSObject {
    
    weak var dataSourceDelegate: QIssuesViewDataSourceDelegate?
    
    private var issues = [QIssue]()
    private var pagination = QPagination(pageOffset: 0, pageSize: 1000)
    private var filter: QIssueFilter?
    private var issuesSet = Set<QIssue>()
    private var serialQueue: dispatch_queue_t = dispatch_queue_create("com.simplerocket.issues.dataSource", DISPATCH_QUEUE_CONCURRENT);
    private var loadedAll: Bool = false
    
    deinit {
        QIssueStore.removeObserver(self)
        QRepositoryStore.removeObserver(self)
        QIssueNotificationStore.removeObserver(self)
    }
    
    override init() {
        super.init()
        QIssueStore.addObserver(self)
        QRepositoryStore.addObserver(self)
        QIssueNotificationStore.addObserver(self)
    }
    
    func numberOfIssues() -> Int {
        var total = 0
        dispatch_sync(self.serialQueue) { () -> Void in
            total = self.issues.count
        }
        //DDLogDebug("total issues \(total)")
        return total
    }
    
    func issueAtIndex(index: Int) -> QIssue {
        var issue: QIssue?
        dispatch_sync(self.serialQueue) { () -> Void in
            issue =  self.issues[index]
        }
        
        return issue!
    }
    
    func indexOfIssue(issue: QIssue) -> Int {
        var index: Int?
        dispatch_sync(self.serialQueue) { () -> Void in
            index = self.issues.indexOf(issue)
        }
        
        return index == nil ? NSNotFound : index!
    }
    
    
    func fetchIssuesWithFilter(filter: QIssueFilter) {
        dispatch_barrier_sync(self.serialQueue) { () -> Void in
            // self.doneFetching = false
            self.filter = filter
            self.pagination = QPagination(pageOffset: 0, pageSize: 1000)
            self.loadedAll = false
            let allIssues = QIssueStore.issuesWithFilter(filter, pagination:self.pagination)
            //QLabelStore.populateLabelsForIssues(allIssues)
            self.issuesSet.removeAll()
            allIssues.forEach { (issue: QIssue) -> () in
                self.issuesSet.insert(issue)
            }
            self.issues = allIssues
        };
        
    }
    
    func countIssuesWithFilter(filter: QIssueFilter) -> Int {
        var total = 0
        dispatch_sync(self.serialQueue) { () -> Void in
            total = QIssueStore.countForIssuesWithFilter(filter)
        };
        return total
    }
    
    func nextPage() {
        dispatch_barrier_async(self.serialQueue) { () -> Void in
            guard self.loadedAll == false else { return }
            self.pagination.pageOffset = self.pagination.pageOffset.integerValue + self.pagination.pageSize.integerValue
            let allNewIssues = QIssueStore.issuesWithFilter(self.filter, pagination:self.pagination)
            self.loadedAll = allNewIssues.count == 0
            self.insertNewIssues(allNewIssues.filter({ !self.issuesSet.contains($0) }))
        };
    }
    
    
    private func insertNewIssues(issues: [QIssue]) {
       // QLabelStore.populateLabelsForIssues(issues)
        
        
        issues.forEach { (issue) in
            
            self.issuesSet.insert(issue)
            
            let index = self.issues.insertionIndexOf(issue) {
                return self.sortIssue($0, elem2: $1)
            }
            self.issues.insert(issue, atIndex: index)
        }
        
        let multableIndexSet = NSMutableIndexSet()
        issues.forEach { (issue) in
            if let index = self.issues.indexOf(issue) {
                multableIndexSet.addIndex(index)
            }
        }
        
        if let indexSet = multableIndexSet.copy() as? NSIndexSet where indexSet.count > 0 {
            self.dataSourceDelegate?.dataSource(self, didInsertIndexSet: indexSet, forFilter: self.filter!)
        }
    }
    
    private func shouldFilterOutIssue(issue: QIssue) -> Bool {
        assert(!NSThread.isMainThread())
        
        guard let aFilter = self.filter where aFilter.filterType != SRFilterType_Drafts else {
            return true
        }
        
        if self.issuesSet.contains(issue) {
            return true
        }
        
        if let query = aFilter.query {
            let adjustedQuery = query.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).lowercaseString
            if ( adjustedQuery.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) != 0  &&
                ( ( " \(issue.title.lowercaseString)".containsString(" \(adjustedQuery)")) || (issue.body != nil && " \(issue.body!.lowercaseString)".containsString(" \(adjustedQuery)"))) ) == false {
                //DDLogDebug("**** filtered [%@]", issue.number)
                return true
            }
        }
        
        if aFilter.filterType == SRFilterType_Notifications && issue.notification == nil {
            return true
        }
        
        if aFilter.account.isEqualToAccount(issue.account) == false {
            //DDLogDebug("**** filtered [%@] account", issue.number)
            return true
        }
        
        if aFilter.repositories.count > 0 && aFilter.repositories.containsObject(issue.repository.fullName) == false {
            //DDLogDebug("**** filtered [%@] repo", issue.number)
            return true
        }
        
        if let login = issue.assignee?.login where aFilter.assignees.count > 0 && aFilter.assignees.containsObject(login) == false {
            //DDLogDebug("**** filtered [%@] %@ from filter.assignees %@", issue.number, issue.assignee != nil ? login : "nil", aFilter.assignees)
            return true
        }
        
        if issue.assignee == nil && aFilter.assignees.count > 0 {
            //DDLogDebug("**** filtered [%@] %@ from filter.assignees %@", issue.number, "nil", self.filter!.assignees)
            return true
        }
        
        if aFilter.authors.count > 0 && aFilter.authors.containsObject(issue.user.login) == false {
            //DDLogDebug("**** filtered [%@] author", issue.number)
            return true
        }
        
        if let milestone = issue.milestone where aFilter.milestones.count > 0 && aFilter.milestones.containsObject(milestone.title) == false {
            //DDLogDebug("**** filtered [%@] milestone", issue.number)
            return true
        }
        
        if issue.milestone == nil && aFilter.milestones.count > 0 {
            //DDLogDebug("**** filtered [%@] %@ from filter.milestones %@", issue.number, "nil", aFilter.milestones)
            return true
        }
        
        if aFilter.issueNumbers.count > 0 && aFilter.issueNumbers.containsObject(issue.number.stringValue) == false {
            //DDLogDebug("**** filtered [%@] issue number", issue.number)
            return true
        }
        
        if aFilter.states.count > 0 {
            if (issue.state == "open" && aFilter.states.containsObject(IssueStoreIssueState_Open) == false) {
                //DDLogDebug("***** opened-filtered [%@] from filter.states %@", issue.number, self.filter!.states)
                return true
            }
            if (issue.state == "closed" && aFilter.states.containsObject(IssueStoreIssueState_Closed) == false) {
                //DDLogDebug("****** closed-filtered [%@] from filter.states %@", issue.number, self.filter!.states)
                return true
            }
        }
        
        if aFilter.labels.count > 0 && (issue.labels == nil || issue.labels?.count == 0) {
            //DDLogDebug("**** filtered [%@] no matching label for labels %@", issue.number, aFilter.labels)
            return true
        }
        
        if aFilter.labels.count > 0 && issue.labels != nil && issue.labels?.count > 0 {
            var foundOne: Bool = false
            for label in issue.labels! {
                if aFilter.labels.containsObject(label.name!) {
                    foundOne = true
                    break
                }
            }
            
            if !foundOne {
                //DDLogDebug("**** filtered [%@] no matching labels %@ for labels %@", issue.number, issue.labels!, aFilter.labels)
                return true
            }
        }
        
        if aFilter.filterType == SRFilterType_Favorites && !QIssueFavoriteStore.isFavoritedIssue(issue) {
            return true
        }
        
        if let mentions = aFilter.mentions.array as? [String] where mentions.count > 0 {
            let mentioned = QIssueStore.areTheseOwnerLogins(mentions, mentionedInIssue: issue)
            if mentioned == false {
                //DDLogDebug("**** filtered [%@] no matching mentions for %@", issue.number, aFilter.mentions)
                return true
            }
        }
        
        
        return false
    }
    
    private func sortIssue(elem1: QIssue, elem2: QIssue) -> Bool {
        switch(self.filter!.sortKey) {
        case kQIssueUpdatedDateSortKey:
            return  (self.filter!.ascending ? elem1.updatedAt.compare(elem2.updatedAt) == NSComparisonResult.OrderedAscending :  elem1.updatedAt.compare(elem2.updatedAt) == NSComparisonResult.OrderedDescending)
        case kQIssueClosedDateSortKey:
            guard let closedAt1 = elem1.closedAt, closedAt2 = elem2.closedAt else {
                if elem1.closedAt == nil && elem2.closedAt == nil {
                    return true
                } else if elem1.closedAt != nil {
                    if self.filter!.ascending {
                        return false
                    } else {
                        return true
                    }
                } else if elem2.closedAt != nil {
                    if self.filter!.ascending {
                        return true
                    } else {
                        return false
                    }
                }
                return true
            }
            
            return  (self.filter!.ascending ? closedAt1.compare(closedAt2) == NSComparisonResult.OrderedAscending :  closedAt1.compare(closedAt2) == NSComparisonResult.OrderedDescending)
        case kQIssueCreatedDateSortKey:
            return  (self.filter!.ascending ? elem1.createdAt.compare(elem2.createdAt) == NSComparisonResult.OrderedAscending :  elem1.createdAt.compare(elem2.createdAt) == NSComparisonResult.OrderedDescending)
        case kQIssueIssueNumberSortKey:
            return  (self.filter!.ascending ? elem1.number.compare(elem2.number) == NSComparisonResult.OrderedAscending : elem1.number.compare(elem2.number) == NSComparisonResult.OrderedDescending)
        case kQIssueIssueStateSortKey:
            return  (self.filter!.ascending ? elem1.state.compare(elem2.state) == NSComparisonResult.OrderedAscending : elem1.state.compare(elem2.state) == NSComparisonResult.OrderedDescending)
        case kQIssueTitleSortKey:
            return  (self.filter!.ascending ? elem1.title.compare(elem2.title) == NSComparisonResult.OrderedAscending : elem1.title.compare(elem2.title) == NSComparisonResult.OrderedDescending)
        case kQIssueAssigneeSortKey:
            let assignee1 = elem1.assignee?.login ?? ""
            let assignee2 = elem2.assignee?.login ?? ""
            return  (self.filter!.ascending ? assignee1.compare(assignee2) == NSComparisonResult.OrderedAscending : assignee1.compare(assignee2) == NSComparisonResult.OrderedDescending)
        default:
            assert(false, "Invalid sort key")
        }
        return true
    }
    
}


extension QIssuesViewDataSource: QStoreObserver {
    
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {
        dispatch_barrier_async(self.serialQueue) { () -> Void in
            
            if let issue = record as? QIssue where self.shouldFilterOutIssue(issue) == false && !self.issuesSet.contains(issue) {
                self.insertNewIssues([issue])
            }
        }
    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        dispatch_barrier_async(self.serialQueue) { () -> Void in
            
            if let updatedIssue = record as? QIssue, index = self.issues.indexOf(updatedIssue) {
                self.issues[index] = updatedIssue
            }
            
        }
    }
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {
        dispatch_barrier_async(self.serialQueue) { () -> Void in
            if let repository = record as? QRepository {
                let removalIndexes = self.issues.enumerate().flatMap({ (index: Int, issue: QIssue) -> (index: Int, issue: QIssue)? in
                    if issue.repository.isEqual(repository) {
                        return (index: index, issue: issue)
                    }
                    return nil
                })
                
                guard removalIndexes.count > 0 else { return }
                
                let indexSet = NSMutableIndexSet()
                for removal in removalIndexes {
                    indexSet.addIndex(removal.index)
                    if let index = self.issues.indexOf(removal.issue) {
                        self.issues.removeAtIndex(index)
                    }
                }
                
                if let delegate = self.dataSourceDelegate {
                    delegate.dataSource(self, didDeleteIndexSet: indexSet, forFilter: self.filter!)
                }
                
                
                
            }
        }
    }
}


