//
//  MilestoneSearchablePickerDataSource.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/1/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class MilestoneSearchablePickerDataSource: NSObject, SearchablePickerDataSource {
    
    var sourceIssue: QIssue?
    fileprivate var results = [QMilestone]()
    fileprivate var selectedMilestone: QMilestone? {
        guard let selectionMap = selectionMap else {
            return nil
        }
        let milestones = Array(selectionMap.values).filter({ $0.count > 0 })
        return milestones.first?.first
        //        if let milestone = milestones.first {
        //            return milestone
        //        }
        //        return nil
    }
    
    fileprivate(set) var selectionMap: [QIssue: Set<QMilestone>]?
    
    var repository: QRepository?
    var numberOfRows: Int {
        return results.count
    }
    
    var mode: SearchablePickerDataSourceMode  = .searchResults {
        didSet {
            switch mode {
            case .selectedItems:
                if let selectedMilestone = selectedMilestone {
                    results = [selectedMilestone]
                }
                
            default:
                results = [QMilestone]()
            }
        }
    }
    
    var selectedIndexes: IndexSet {
        if let selectedMilestone = selectedMilestone, let index = results.index(of: selectedMilestone) {
            let indexSet = NSMutableIndexSet()
            indexSet.add(index)
            return indexSet as IndexSet
        }
        return IndexSet()
    }
    var selectionCount: Int {
        if let _ = selectedMilestone {
            return 1
        }
        return 0
    }
    
    var listOfRepositories: [QRepository] {
        guard let selectionMap = selectionMap else {
            return [QRepository]()
        }
        let issues = Array(selectionMap.keys)
        let repos = Array(Set(issues.compactMap { $0.repository })).sorted(by: { $0.fullName.compare($1.fullName) == .orderedAscending })
        return repos
//        guard let currentIssues = self.sourceIssue != nil ? [self.sourceIssue!] : QContext.shared().currentIssues else  {
//            return [QRepository]()
//        }
//        return currentIssues.flatMap { $0.repository }
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
            if let results = QMilestoneStore.searchMilestone(withQuery: String(format:"%@*", string), forAccountId: repository.account.identifier, repositoryId: repository.identifier) as AnyObject as? [QMilestone] {
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
            if let results = QMilestoneStore.milestones(forAccountId: repository.account.identifier, repositoryId: repository.identifier, includeHidden: false) as AnyObject as? [QMilestone] {
                
                self.results = results.sorted(by: { (repo1, repo2) -> Bool in
                    if self.isSelectedItem(repo1) && self.isSelectedItem(repo2) {
                        return repo1.title < repo2.title
                    } else  if self.isSelectedItem(repo1) {
                        return true
                    } else  if self.isSelectedItem(repo2) {
                        return false
                    } else {
                        return repo1.title < repo2.title
                    }
                })
            }
            onCompletion()
        }
        
    }
    
    
    func selectItem(_ item: AnyObject) {
        guard let milestone = item as? QMilestone else {
            return
        }
        tappedMilestone(milestone)
    }
    
    func unselectItem(_ item: AnyObject) {
        guard let milestone = item as? QMilestone else {
            return
        }
        tappedMilestone(milestone)
    }
    
    fileprivate func tappedMilestone(_ milestone: QMilestone) {
        guard var selectionMap = selectionMap else { return }
        
        if isFullSelection(milestone) {
            for (k, _) in selectionMap {
                if k.repository == milestone.repository {
                    selectionMap[k] = Set<QMilestone>()
                }
            }
        } else {
            for (k, _) in selectionMap {
                if k.repository == milestone.repository {
                    var set = Set<QMilestone>()
                    set.insert(milestone)
                    selectionMap[k] = set
                }
            }
        }
       //DDLogDebug("selection -> \(selectionMap)")
        self.selectionMap = selectionMap
    }
    
    func isSelectedItem(_ item: AnyObject) -> Bool {
        if let milestone = item as? QMilestone {
            return isFullSelection(milestone) || isPartialSelection(milestone)
        }
        return false
    }
    
    func clearSelection() {
        guard let selectionMap = selectionMap else {
            self.selectionMap = [QIssue: Set<QMilestone>]()
            return
        }
        
        var newSelectionMap = [QIssue: Set<QMilestone>]()
        for (k,_) in selectionMap {
            newSelectionMap[k] = nil
        }
        self.selectionMap = newSelectionMap
    }
    
    
    func resetToOriginal() {
        results.removeAll()
        repository = nil
        
        var multiSelectionMap = [QIssue: Set<QMilestone>]()
        
        let issues: [QIssue]
        if let sourceIssue = sourceIssue {
            issues = [sourceIssue]
        } else {
            issues = QContext.shared().currentIssues
        }
        
        issues.forEach { (issue) in
            if let milestone = issue.milestone {
                var set = Set<QMilestone>()
                set.insert(milestone)
                multiSelectionMap[issue] = set
            } else {
                let set = Set<QMilestone>()
                multiSelectionMap[issue] = set
            }
        }
        self.selectionMap = multiSelectionMap
    }
    
    func isPartialSelection(_ milestone: QMilestone) -> Bool {
        guard let selectionMap = selectionMap else { return false }
        
        //DDLogDebug("label=\(label) filter -> \(selectionMap.filter({ $1.contains(label) }))")
        let total: Int = selectionMap.filter({ $0.1.contains(milestone) && $0.0.repository == milestone.repository }).count
        let repoTotal: Int = selectionMap.filter({ $0.0.repository == milestone.repository }).count
        return total > 0 && total != repoTotal
    }
    
    func isFullSelection(_ milestone: QMilestone) -> Bool {
        if let issues = selectionMap?.keys , issues.count > 0 {
            for issue in issues {
                if let labels = selectionMap?[issue] , !labels.contains(milestone) && issue.repository == milestone.repository {
                    return false
                }
            }
        } else {
            return false
        }
        return true
    }
}
