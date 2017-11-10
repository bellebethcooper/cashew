//
//  AssigneeSearchablePickerDataSource.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/2/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class AssigneeSearchablePickerDataSource: NSObject, SearchablePickerDataSource {
    
    var sourceIssue: QIssue?
    private var results = [QOwner]()
    private var selectedAssignee: QOwner? {
        guard let selectionMap = selectionMap else {
            return nil
        }
        let assignees = Array(selectionMap.values).filter({ $0.count > 0 })
        return assignees.first?.first
    }
    
    private(set) var selectionMap: [QIssue: Set<QOwner>]?
    private(set) var userToRepositoryMap: [QOwner: Set<QRepository>]?
    
    var repository: QRepository?
    var numberOfRows: Int {
        return results.count
    }
    
    var mode: SearchablePickerDataSourceMode  = .SearchResults {
        didSet {
            switch mode {
            case .SelectedItems:
                if let selectedassignee = selectedAssignee {
                    results = [selectedassignee]
                }
                
            default:
                results = [QOwner]()
            }
        }
    }
    
    var selectedIndexes: NSIndexSet {
        if let selectedassignee = selectedAssignee, index = results.indexOf(selectedassignee) {
            let indexSet = NSMutableIndexSet()
            indexSet.addIndex(index)
            return indexSet
        }
        return NSIndexSet()
    }
    var selectionCount: Int {
        if let _ = selectedAssignee {
            return 1
        }
        return 0
    }
    
    var listOfRepositories: [QRepository] {
        guard let selectionMap = selectionMap else {
            return [QRepository]()
        }
        let issues = Array(selectionMap.keys)
        let repos = Array(Set(issues.flatMap { $0.repository })).sort({ $0.fullName.compare($1.fullName) == .OrderedAscending })
        return repos
    }
    
    var allowResetToOriginal: Bool {
        return true
    }
    
    required init(sourceIssue: QIssue?) {
        self.sourceIssue = sourceIssue
        super.init()
        resetToOriginal()
    }
    
    func itemAtIndex(index: Int) -> AnyObject {
        return results[index]
    }
    
    func search(string: String, onCompletion: dispatch_block_t) {
        mode = .SearchResults
        guard let repository = self.repository else {
            self.results = []
            onCompletion()
            return
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            if let results = QOwnerStore.searchUserWithQuery(String(format:"%@*", string), forAccountId: repository.account.identifier, repositoryId: repository.identifier) as AnyObject as? [QOwner] {
                self.results = results
            }
            onCompletion()
        }
    }
    
    func defaults(onCompletion: dispatch_block_t) {
        mode = .DefaultResults
        guard let repository = self.repository else {
            self.results = []
            onCompletion()
            return
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            if let results = QOwnerStore.ownersForAccountId(repository.account.identifier, repositoryId: repository.identifier) as AnyObject as? [QOwner] {
                
                self.results = results.sort({ (owner1, owner2) -> Bool in
                    if self.isSelectedItem(owner1) && self.isSelectedItem(owner2) {
                        return owner1.login < owner2.login
                    } else  if self.isSelectedItem(owner1) {
                        return true
                    } else  if self.isSelectedItem(owner2) {
                        return false
                    } else {
                        return owner1.login < owner2.login
                    }
                })
            }
            onCompletion()
        }
        
    }
    
    
    func selectItem(item: AnyObject) {
        guard let assignee = item as? QOwner else {
            return
        }
        tappedAssignee(assignee)
    }
    
    func unselectItem(item: AnyObject) {
        guard let assignee = item as? QOwner else {
            return
        }
        tappedAssignee(assignee)
    }
    
    private func tappedAssignee(assignee: QOwner) {
        guard var selectionMap = selectionMap, let repository = repository else { return }
        
        if isFullSelection(assignee) {
            for (k, _) in selectionMap {
                if k.repository == repository {
                    selectionMap[k] = Set<QOwner>()
                }
            }
        } else {
            for (k, _) in selectionMap {
                if k.repository == repository {
                    var set = Set<QOwner>()
                    set.insert(assignee)
                    selectionMap[k] = set
                }
            }
        }
        self.selectionMap = selectionMap
    }
    
    func isSelectedItem(item: AnyObject) -> Bool {
        if let assignee = item as? QOwner {
            return isFullSelection(assignee) || isPartialSelection(assignee)
        }
        return false
    }
    
    func clearSelection() {
        guard let selectionMap = selectionMap else {
            self.selectionMap = [QIssue: Set<QOwner>]()
            return
        }
        
        var newSelectionMap = [QIssue: Set<QOwner>]()
        for (k,_) in selectionMap {
            newSelectionMap[k] = nil
        }
        self.selectionMap = newSelectionMap
    }
    
    
    func resetToOriginal() {
        results.removeAll()
        repository = nil
        
        var multiSelectionMap = [QIssue: Set<QOwner>]()
        
        let issues: [QIssue]
        if let sourceIssue = sourceIssue {
            issues = [sourceIssue]
        } else {
            issues = QContext.sharedContext().currentIssues
        }
        
        var repos = Set<QRepository>()
        issues.forEach { (issue) in
            repos.insert(issue.repository)
            if let assignee = issue.assignee {
                var set = Set<QOwner>()
                set.insert(assignee)
                multiSelectionMap[issue] = set
            } else {
                let set = Set<QOwner>()
                multiSelectionMap[issue] = set
            }
        }
        
        self.selectionMap = multiSelectionMap
        
        var mapping = [QOwner: Set<QRepository>]()
        repos.forEach { (repository) in
            QOwnerStore.ownersForAccountId(repository.account.identifier, repositoryId: repository.identifier).forEach({ (owner) in
                if var ownerRepositories = mapping[owner] {
                    ownerRepositories.insert(repository)
                    mapping[owner] = ownerRepositories
                } else {
                    mapping[owner] = Set<QRepository>([repository])
                }
            })
        }
        userToRepositoryMap = mapping
    }
    
    func isPartialSelection(assignee: QOwner) -> Bool {
        guard let selectionMap = selectionMap, userToRepositoryMap = userToRepositoryMap, ownerRepositories = userToRepositoryMap[assignee], repository = repository else { return false }
        
        // DDLogDebug("\n----\n assignee=\(assignee)")
        // DDLogDebug("selectionMap=\(selectionMap)")
        let total:Int = selectionMap.filter({
            //  DDLogDebug("PARTIAL\($0.1)->$0.1.contains(assignee)=\($0.1.contains(assignee)) && $0.0.repository == repository=\($0.0.repository == repository) && ownerRepositories.contains(repository)=\(ownerRepositories.contains(repository))")
            return $0.1.contains(assignee) && $0.0.repository == repository && ownerRepositories.contains(repository)
        }).count
        let repoTotal: Int = selectionMap.filter({ $0.0.repository == repository && ownerRepositories.contains(repository) }).count
       // DDLogDebug("IS_PARTIAL -> \(total > 0 && total != repoTotal) assignee=\(assignee)")
        return total > 0 && total != repoTotal
    }
    
    func isFullSelection(assignee: QOwner) -> Bool {
        guard let selectionMap = selectionMap, userToRepositoryMap = userToRepositoryMap, ownerRepositories = userToRepositoryMap[assignee], repository = repository else { return false }
        
        //   DDLogDebug("\n----\n assignee=\(assignee)")
        // DDLogDebug("selectionMap=\(selectionMap)")
        let total:Int = selectionMap.filter({
            // DDLogDebug("FULL: \($0.1)->$0.1.contains(assignee)=\($0.1.contains(assignee)) && $0.0.repository == repository=\($0.0.repository == repository) && ownerRepositories.contains(repository)=\(ownerRepositories.contains(repository))")
            return $0.1.contains(assignee) && $0.0.repository == repository && ownerRepositories.contains(repository)
        }).count
        let repoTotal: Int = selectionMap.filter({ $0.0.repository == repository && ownerRepositories.contains(repository) }).count
        //DDLogDebug("IS_FULL -> \(total > 0 && total == repoTotal) assignee=\(assignee)")
        return total > 0 && total == repoTotal
        
        //        if selectionMap.keys.count == 0 {
        //            return false
        //        }
        //
        //        for (issue, owners) in selectionMap {
        //            if !owners.contains(assignee) && issue.repository == repository && ownerRepositories.contains(repository) {
        //                return false
        //            }
        //        }
        //
        //        return true
    }
}