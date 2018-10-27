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
    fileprivate var results = [QOwner]()
    fileprivate var selectedAssignee: QOwner? {
        guard let selectionMap = selectionMap else {
            return nil
        }
        let assignees = Array(selectionMap.values).filter({ $0.count > 0 })
        return assignees.first?.first
    }
    
    fileprivate(set) var selectionMap: [QIssue: Set<QOwner>]?
    fileprivate(set) var userToRepositoryMap: [QOwner: Set<QRepository>]?
    
    var repository: QRepository?
    var numberOfRows: Int {
        return results.count
    }
    
    var mode: SearchablePickerDataSourceMode  = .searchResults {
        didSet {
            switch mode {
            case .selectedItems:
                if let selectedassignee = selectedAssignee {
                    results = [selectedassignee]
                }
                
            default:
                results = [QOwner]()
            }
        }
    }
    
    var selectedIndexes: IndexSet {
        if let selectedassignee = selectedAssignee, let index = results.index(of: selectedassignee) {
            let indexSet = NSMutableIndexSet()
            indexSet.add(index)
            return indexSet as IndexSet
        }
        return IndexSet()
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
        let repos = Array(Set(issues.flatMap { $0.repository })).sorted(by: { $0.fullName.compare($1.fullName) == .orderedAscending })
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
    
    func itemAtIndex(_ index: Int) -> AnyObject {
        return results[index]
    }
    
    func search(_ string: String, onCompletion: @escaping ()->()) {
        mode = .searchResults
        guard let repository = self.repository else {
            self.results = []
            onCompletion()
            return
        }
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async {
            if let results = QOwnerStore.searchUser(withQuery: String(format:"%@*", string), forAccountId: repository.account.identifier, repositoryId: repository.identifier) as AnyObject as? [QOwner] {
                self.results = results
            }
            onCompletion()
        }
    }
    
    func defaults(_ onCompletion: @escaping ()->()) {
        mode = .defaultResults
        guard let repository = self.repository else {
            self.results = []
            onCompletion()
            return
        }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async {
            if let results = QOwnerStore.owners(forAccountId: repository.account.identifier, repositoryId: repository.identifier) as AnyObject as? [QOwner] {
                
                self.results = results.sorted(by: { (owner1, owner2) -> Bool in
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
    
    
    func selectItem(_ item: AnyObject) {
        guard let assignee = item as? QOwner else {
            return
        }
        tappedAssignee(assignee)
    }
    
    func unselectItem(_ item: AnyObject) {
        guard let assignee = item as? QOwner else {
            return
        }
        tappedAssignee(assignee)
    }
    
    fileprivate func tappedAssignee(_ assignee: QOwner) {
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
    
    func isSelectedItem(_ item: AnyObject) -> Bool {
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
            issues = QContext.shared().currentIssues
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
            QOwnerStore.owners(forAccountId: repository.account.identifier, repositoryId: repository.identifier).forEach({ (owner) in
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
    
    func isPartialSelection(_ assignee: QOwner) -> Bool {
        guard let selectionMap = selectionMap, let userToRepositoryMap = userToRepositoryMap, let ownerRepositories = userToRepositoryMap[assignee], let repository = repository else { return false }
        
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
    
    func isFullSelection(_ assignee: QOwner) -> Bool {
        guard let selectionMap = selectionMap, let userToRepositoryMap = userToRepositoryMap, let ownerRepositories = userToRepositoryMap[assignee], let repository = repository else { return false }
        
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
