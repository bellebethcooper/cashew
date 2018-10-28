//
//  QIssuesViewDataSource.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/31/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc protocol QIssuesViewDataSourceDelegate: class {
    func dataSource(_ dataSource: QIssuesViewDataSource?, didInsertIndexSet: IndexSet, forFilter: QIssueFilter);
    func dataSource(_ dataSource: QIssuesViewDataSource?, didDeleteIndexSet: IndexSet, forFilter: QIssueFilter);
    
}

class QIssuesViewDataSource: NSObject {
    
    @objc weak var dataSourceDelegate: QIssuesViewDataSourceDelegate?
    
    fileprivate var issues = [QIssue]()
    fileprivate var pagination = QPagination(pageOffset: 0, pageSize: 1000)
    fileprivate var filter: QIssueFilter?
    fileprivate var issuesSet = Set<QIssue>()
    fileprivate var serialQueue: DispatchQueue = DispatchQueue(label: "co.hellocode.cashew.dataSource", attributes: DispatchQueue.Attributes.concurrent);
    fileprivate var loadedAll: Bool = false
    
    deinit {
        QIssueStore.remove(self)
        QRepositoryStore.remove(self)
        QIssueNotificationStore.remove(self)
    }
    
    override init() {
        super.init()
        QIssueStore.add(self)
        QRepositoryStore.add(self)
        QIssueNotificationStore.add(self)
    }
    
    @objc func numberOfIssues() -> Int {
        var total = 0
        (self.serialQueue).sync { () -> Void in
            total = self.issues.count
        }
        //DDLogDebug("total issues \(total)")
        return total
    }
    
    @objc func issueAtIndex(_ index: Int) -> QIssue {
        var issue: QIssue?
        (self.serialQueue).sync { () -> Void in
            issue =  self.issues[index]
        }
        
        return issue!
    }
    
    func indexOfIssue(_ issue: QIssue) -> Int {
        var index: Int?
        (self.serialQueue).sync { () -> Void in
            index = self.issues.index(of: issue)
        }
        
        return index == nil ? NSNotFound : index!
    }
    
    
    @objc func fetchIssuesWithFilter(_ filter: QIssueFilter) {
        self.serialQueue.sync(flags: .barrier, execute: { () -> Void in
            // self.doneFetching = false
            self.filter = filter
            self.pagination = QPagination(pageOffset: 0, pageSize: 1000)
            self.loadedAll = false
            let allIssues = QIssueStore.issues(with: filter, pagination:self.pagination)
            //QLabelStore.populateLabelsForIssues(allIssues)
            self.issuesSet.removeAll()
            allIssues?.forEach { (issue: QIssue) -> () in
                self.issuesSet.insert(issue)
            }
            if let allIssues = allIssues {
                self.issues = allIssues                
            }
        }) ;
        
    }
    
    func countIssuesWithFilter(_ filter: QIssueFilter) -> Int {
        var total = 0
        (self.serialQueue).sync { () -> Void in
            total = QIssueStore.countForIssues(with: filter)
        };
        return total
    }
    
    func nextPage() {
        self.serialQueue.async(flags: .barrier, execute: { () -> Void in
            guard self.loadedAll == false else { return }
            self.pagination.pageOffset = NSNumber(integerLiteral: self.pagination.pageOffset.intValue + self.pagination.pageSize.intValue)
            let allNewIssues = QIssueStore.issues(with: self.filter, pagination:self.pagination)
            self.loadedAll = allNewIssues?.count == 0
            self.insertNewIssues((allNewIssues?.filter({ !self.issuesSet.contains($0) }))!)
        }) ;
    }
    
    
    fileprivate func insertNewIssues(_ issues: [QIssue]) {
       // QLabelStore.populateLabelsForIssues(issues)
        
        
        issues.forEach { (issue) in
            
            self.issuesSet.insert(issue)
            
            let index = self.issues.insertionIndexOf(issue) {
                return self.sortIssue($0, elem2: $1)
            }
            self.issues.insert(issue, at: index)
        }
        
        let multableIndexSet = NSMutableIndexSet()
        issues.forEach { (issue) in
            if let index = self.issues.index(of: issue) {
                multableIndexSet.add(index)
            }
        }
        
        if let indexSet = multableIndexSet.copy() as? IndexSet , indexSet.count > 0 {
            self.dataSourceDelegate?.dataSource(self, didInsertIndexSet: indexSet, forFilter: self.filter!)
        }
    }
    
    fileprivate func shouldFilterOutIssue(_ issue: QIssue) -> Bool {
        assert(!Thread.isMainThread)
        
        guard let aFilter = self.filter , aFilter.filterType != SRFilterType_Drafts else {
            return true
        }
        
        if self.issuesSet.contains(issue) {
            return true
        }
        
        if let query = aFilter.query {
            let adjustedQuery = query.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
            if ( adjustedQuery.lengthOfBytes(using: String.Encoding.utf8) != 0  &&
                ( ( " \(issue.title.lowercased())".contains(" \(adjustedQuery)")) || (issue.body != nil && " \(issue.body!.lowercased())".contains(" \(adjustedQuery)"))) ) == false {
                //DDLogDebug("**** filtered [%@]", issue.number)
                return true
            }
        }
        
        if aFilter.filterType == SRFilterType_Notifications && issue.notification == nil {
            return true
        }
        
        if aFilter.account.isEqual(toAccount: issue.account) == false {
            //DDLogDebug("**** filtered [%@] account", issue.number)
            return true
        }
        
        if aFilter.repositories.count > 0 && aFilter.repositories.contains(issue.repository.fullName) == false {
            //DDLogDebug("**** filtered [%@] repo", issue.number)
            return true
        }
        
        if let login = issue.assignee?.login , aFilter.assignees.count > 0 && aFilter.assignees.contains(login) == false {
            //DDLogDebug("**** filtered [%@] %@ from filter.assignees %@", issue.number, issue.assignee != nil ? login : "nil", aFilter.assignees)
            return true
        }
        
        if issue.assignee == nil && aFilter.assignees.count > 0 {
            //DDLogDebug("**** filtered [%@] %@ from filter.assignees %@", issue.number, "nil", self.filter!.assignees)
            return true
        }
        
        if aFilter.authors.count > 0 && aFilter.authors.contains(issue.user.login) == false {
            //DDLogDebug("**** filtered [%@] author", issue.number)
            return true
        }
        
        if let milestone = issue.milestone , aFilter.milestones.count > 0 && aFilter.milestones.contains(milestone.title) == false {
            //DDLogDebug("**** filtered [%@] milestone", issue.number)
            return true
        }
        
        if issue.milestone == nil && aFilter.milestones.count > 0 {
            //DDLogDebug("**** filtered [%@] %@ from filter.milestones %@", issue.number, "nil", aFilter.milestones)
            return true
        }
        
        if aFilter.issueNumbers.count > 0 && aFilter.issueNumbers.contains(issue.number.stringValue) == false {
            //DDLogDebug("**** filtered [%@] issue number", issue.number)
            return true
        }
        
        if aFilter.states.count > 0 {
            if (issue.state == "open" && aFilter.states.contains(IssueStoreIssueState_Open) == false) {
                //DDLogDebug("***** opened-filtered [%@] from filter.states %@", issue.number, self.filter!.states)
                return true
            }
            if (issue.state == "closed" && aFilter.states.contains(IssueStoreIssueState_Closed) == false) {
                //DDLogDebug("****** closed-filtered [%@] from filter.states %@", issue.number, self.filter!.states)
                return true
            }
        }
        
        if aFilter.labels.count > 0 && (issue.labels == nil || issue.labels?.count == 0) {
            //DDLogDebug("**** filtered [%@] no matching label for labels %@", issue.number, aFilter.labels)
            return true
        }
        
        if aFilter.labels.count > 0 && issue.labels != nil && (issue.labels?.count)! > 0 {
            var foundOne: Bool = false
            for label in issue.labels! {
                if aFilter.labels.contains(label.name!) {
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
        
        if let mentions = aFilter.mentions.array as? [String] , mentions.count > 0 {
            let mentioned = QIssueStore.areTheseOwnerLogins(mentions, mentionedIn: issue)
            if mentioned == false {
                //DDLogDebug("**** filtered [%@] no matching mentions for %@", issue.number, aFilter.mentions)
                return true
            }
        }
        
        
        return false
    }
    
    fileprivate func sortIssue(_ elem1: QIssue, elem2: QIssue) -> Bool {
        switch(self.filter!.sortKey) {
        case kQIssueUpdatedDateSortKey:
            return  (self.filter!.ascending ? elem1.updatedAt.compare(elem2.updatedAt) == ComparisonResult.orderedAscending :  elem1.updatedAt.compare(elem2.updatedAt) == ComparisonResult.orderedDescending)
        case kQIssueClosedDateSortKey:
            guard let closedAt1 = elem1.closedAt, let closedAt2 = elem2.closedAt else {
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
            
            return  (self.filter!.ascending ? closedAt1.compare(closedAt2) == ComparisonResult.orderedAscending :  closedAt1.compare(closedAt2) == ComparisonResult.orderedDescending)
        case kQIssueCreatedDateSortKey:
            return  (self.filter!.ascending ? elem1.createdAt.compare(elem2.createdAt) == ComparisonResult.orderedAscending :  elem1.createdAt.compare(elem2.createdAt) == ComparisonResult.orderedDescending)
        case kQIssueIssueNumberSortKey:
            return  (self.filter!.ascending ? elem1.number.compare(elem2.number) == ComparisonResult.orderedAscending : elem1.number.compare(elem2.number) == ComparisonResult.orderedDescending)
        case kQIssueIssueStateSortKey:
            return  (self.filter!.ascending ? elem1.state.compare(elem2.state) == ComparisonResult.orderedAscending : elem1.state.compare(elem2.state) == ComparisonResult.orderedDescending)
        case kQIssueTitleSortKey:
            return  (self.filter!.ascending ? elem1.title.compare(elem2.title) == ComparisonResult.orderedAscending : elem1.title.compare(elem2.title) == ComparisonResult.orderedDescending)
        case kQIssueAssigneeSortKey:
            let assignee1 = elem1.assignee?.login ?? ""
            let assignee2 = elem2.assignee?.login ?? ""
            return  (self.filter!.ascending ? assignee1.compare(assignee2) == ComparisonResult.orderedAscending : assignee1.compare(assignee2) == ComparisonResult.orderedDescending)
        default:
            assert(false, "Invalid sort key")
        }
        return true
    }
    
}


extension QIssuesViewDataSource: QStoreObserver {
    
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {
        self.serialQueue.async(flags: .barrier, execute: { () -> Void in
            
            if let issue = record as? QIssue , self.shouldFilterOutIssue(issue) == false && !self.issuesSet.contains(issue) {
                self.insertNewIssues([issue])
            }
        }) 
    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        self.serialQueue.async(flags: .barrier, execute: { () -> Void in
            
            if let updatedIssue = record as? QIssue, let index = self.issues.index(of: updatedIssue) {
                self.issues[index] = updatedIssue
            }
            
        }) 
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {
        self.serialQueue.async(flags: .barrier, execute: { () -> Void in
            if let repository = record as? QRepository {
                let removalIndexes = self.issues.enumerated().flatMap({ (index: Int, issue: QIssue) -> (index: Int, issue: QIssue)? in
                    if issue.repository.isEqual(repository) {
                        return (index: index, issue: issue)
                    }
                    return nil
                })
                
                guard removalIndexes.count > 0 else { return }
                
                let indexSet = NSMutableIndexSet()
                for removal in removalIndexes {
                    indexSet.add(removal.index)
                    if let index = self.issues.index(of: removal.issue) {
                        self.issues.remove(at: index)
                    }
                }
                
                if let delegate = self.dataSourceDelegate {
                    delegate.dataSource(self, didDeleteIndexSet: indexSet as IndexSet, forFilter: self.filter!)
                }
                
                
                
            }
        }) 
    }
}


