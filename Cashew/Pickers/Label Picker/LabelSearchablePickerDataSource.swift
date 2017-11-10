//
//  LabelSearchablePickerDataSource.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/30/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class LabelSearchablePickerDataSource: NSObject, SearchablePickerDataSource {
    
    var sourceIssue: QIssue?
    private var results = [QLabel]()
    var allowResetToOriginal: Bool = true
    var repository: QRepository? = nil {
        didSet {
            
        }
    }
    private(set) var selectionMap: [QIssue: Set<QLabel>]?
    
    required init(sourceIssue: QIssue?) {
        self.sourceIssue = sourceIssue
        super.init()
        resetToOriginal()
    }
    
    func resetToOriginal() {
        results.removeAll()
        repository = nil
        
        var multiSelectionMap = [QIssue: Set<QLabel>]()
        let issues: [QIssue]
        
        if let sourceIssue = sourceIssue {
            issues = [sourceIssue]
        } else {
            issues = QContext.sharedContext().currentIssues
        }
        
        issues.forEach { (issue) in
            if let labels = issue.labels {
                multiSelectionMap[issue] = Set(labels)
            } else {
                multiSelectionMap[issue] = Set()
            }
        }
        self.selectionMap = multiSelectionMap
    }
    
    var listOfRepositories: [QRepository] {
        guard let selectionMap = selectionMap else {
            return [QRepository]()
        }
        let issues = Array(selectionMap.keys)
        let repos = Array(Set(issues.flatMap { $0.repository })).sort({ $0.fullName.compare($1.fullName) == .OrderedAscending })
        return repos
    }
    
    func isPartialSelection(label: QLabel) -> Bool {
        guard let selectionMap = selectionMap else { return false }
        
        let total:Int = selectionMap.filter({ $0.1.contains(label) && $0.0.repository == label.repository }).count
        let repoTotal: Int = selectionMap.filter({ $0.0.repository == label.repository }).count
       // DDLogDebug("[\(label)] total => \(total) repoTotal => \(repoTotal) isPartial = \(total > 0 && total != repoTotal)")
        return total > 0 && total != repoTotal
    }
    
    func isFullSelection(label: QLabel) -> Bool {
        if let issues = selectionMap?.keys where issues.count > 0 {
            for issue in issues {
                if let labels = selectionMap?[issue] where !labels.contains(label) && label.repository == issue.repository {
                    return false
                }
            }
        } else {
            return false
        }
        return true
    }
    
    // MARK: SearchablePickerDataSource
    var mode: SearchablePickerDataSourceMode = .SearchResults {
        didSet {
            switch mode {
            case .SelectedItems:
                if let selectionMap = selectionMap {
                    var selectedItems = Set<QLabel>()
                    for (k, v) in selectionMap {
                        if (k.repository == self.repository) {
                            v.forEach({
                                selectedItems.insert($0)
                            })
                        }
                    }
                    results = Array(selectedItems)
                }
                
            default:
                results = [QLabel]()
            }
        }
    }
    
    var numberOfRows: Int {
        return results.count
    }
    
    var selectedIndexes: NSIndexSet {
        let set = NSMutableIndexSet()
        for (i , _) in results.enumerate() {
            if selectedLabelSet.contains(results[i]) {
                set.addIndex(i)
            }
        }
        return set
    }
    
    var selectedLabels: [QLabel] {
        return Array(selectedLabelSet)
    }
    
    private var selectedLabelSet: Set<QLabel> {
        guard let selectionMap = selectionMap else { return Set<QLabel>() }
        var selectedLabelSet = Set<QLabel>()
        for (_, v) in selectionMap {
            v.forEach { selectedLabelSet.insert($0) }
        }
        return selectedLabelSet
    }
    
    var selectionCount: Int {
        return selectedLabelSet.count
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
            if let results = QLabelStore.searchLabelsWithQuery("\(string)*", forAccountId: repository.account.identifier, repositoryId: repository.identifier) as NSArray as? [QLabel] {
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
            if let results = QLabelStore.labelsForAccountId(repository.account.identifier, repositoryId: repository.identifier, includeHidden: false) as NSArray as? [QLabel] {
                
                self.results = results.sort({ (repo1, repo2) -> Bool in
                    if self.isSelectedItem(repo1) && self.isSelectedItem(repo2) {
                        return repo1.name < repo2.name
                    } else  if self.isSelectedItem(repo1) {
                        return true
                    } else  if self.isSelectedItem(repo2) {
                        return false
                    } else {
                        return repo1.name < repo2.name
                    }
                })
            }
            onCompletion()
        }
        
    }
    
    func selectItem(item: AnyObject) {
        if let label = item as? QLabel {
            tappedLabel(label)
        }
    }
    
    func unselectItem(item: AnyObject) {
        if let label = item as? QLabel {
            tappedLabel(label)
        }
    }
    
    func isSelectedItem(item: AnyObject) -> Bool {
        if let label = item as? QLabel {
            return isFullSelection(label) || isPartialSelection(label)
        }
        return false
    }
    
    func clearSelection() {
        guard let selectionMap = selectionMap else {
            self.selectionMap = [QIssue: Set<QLabel>]()
            return
        }
        
        var newSelectionMap = [QIssue: Set<QLabel>]()
        for (k,_) in selectionMap {
            newSelectionMap[k] = Set<QLabel>()
        }
        self.selectionMap = newSelectionMap
    }
    
    private func tappedLabel(label: QLabel) {
        guard var selectionMap = selectionMap else { return }
        if isPartialSelection(label) {
            for (k, v) in selectionMap {
                if k.repository == label.repository {
                    var labels = Set<QLabel>(v)
                    labels.insert(label)
                    selectionMap[k] = labels
                }
            }
        } else if isFullSelection(label) {
            for (k, v) in selectionMap {
                if k.repository == label.repository {
                    var labels = Set<QLabel>(v)
                    labels.remove(label)
                    selectionMap[k] = labels
                }
            }
        } else {
            for (k, v) in selectionMap {
                if k.repository == label.repository {
                    var labels = Set<QLabel>(v)
                    labels.insert(label)
                    selectionMap[k] = labels
                }
            }
        }
        self.selectionMap = selectionMap
    }
}
