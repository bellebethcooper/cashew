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
    private var results = [QMilestone]()
    private var selectedMilestone: QMilestone? {
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
    
    private(set) var selectionMap: [QIssue: Set<QMilestone>]?
    
    var repository: QRepository?
    var numberOfRows: Int {
        return results.count
    }
    
    var mode: SearchablePickerDataSourceMode  = .SearchResults {
        didSet {
            switch mode {
            case .SelectedItems:
                if let selectedMilestone = selectedMilestone {
                    results = [selectedMilestone]
                }
                
            default:
                results = [QMilestone]()
            }
        }
    }
    
    var selectedIndexes: NSIndexSet {
        if let selectedMilestone = selectedMilestone, index = results.indexOf(selectedMilestone) {
            let indexSet = NSMutableIndexSet()
            indexSet.addIndex(index)
            return indexSet
        }
        return NSIndexSet()
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
        let repos = Array(Set(issues.flatMap { $0.repository })).sort({ $0.fullName.compare($1.fullName) == .OrderedAscending })
        return repos
//        guard let currentIssues = self.sourceIssue != nil ? [self.sourceIssue!] : QContext.sharedContext().currentIssues else  {
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
            if let results = QMilestoneStore.searchMilestoneWithQuery(String(format:"%@*", string), forAccountId: repository.account.identifier, repositoryId: repository.identifier) as AnyObject as? [QMilestone] {
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
            if let results = QMilestoneStore.milestonesForAccountId(repository.account.identifier, repositoryId: repository.identifier, includeHidden: false) as AnyObject as? [QMilestone] {
                
                self.results = results.sort({ (repo1, repo2) -> Bool in
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
    
    
    func selectItem(item: AnyObject) {
        guard let milestone = item as? QMilestone else {
            return
        }
        tappedMilestone(milestone)
    }
    
    func unselectItem(item: AnyObject) {
        guard let milestone = item as? QMilestone else {
            return
        }
        tappedMilestone(milestone)
    }
    
    private func tappedMilestone(milestone: QMilestone) {
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
    
    func isSelectedItem(item: AnyObject) -> Bool {
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
            issues = QContext.sharedContext().currentIssues
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
    
    func isPartialSelection(milestone: QMilestone) -> Bool {
        guard let selectionMap = selectionMap else { return false }
        
        //DDLogDebug("label=\(label) filter -> \(selectionMap.filter({ $1.contains(label) }))")
        let total: Int = selectionMap.filter({ $0.1.contains(milestone) && $0.0.repository == milestone.repository }).count
        let repoTotal: Int = selectionMap.filter({ $0.0.repository == milestone.repository }).count
        return total > 0 && total != repoTotal
    }
    
    func isFullSelection(milestone: QMilestone) -> Bool {
        if let issues = selectionMap?.keys where issues.count > 0 {
            for issue in issues {
                if let labels = selectionMap?[issue] where !labels.contains(milestone) && issue.repository == milestone.repository {
                    return false
                }
            }
        } else {
            return false
        }
        return true
    }
}
