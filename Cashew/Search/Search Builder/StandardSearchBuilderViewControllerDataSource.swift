//
//  StandardSearchBuilderViewControllerDataSource.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/26/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRStandardSearchBuilderViewControllerDataSource)
class StandardSearchBuilderViewControllerDataSource: NSObject, SearchBuilderViewControllerDataSource {
    
    var criteriaViewControllerDataSource: SearchBuilderCriteriaViewControllerDataSource = StandardSearchBuilderCriteriaViewControllerDataSource()
    
    func resetCache() {
        criteriaViewControllerDataSource.resetCachedValues()
    }
    
    
    func onSearch(_ results: [SearchBuilderResult]) {
        QContext.shared().currentFilter = filterFromResults(results)
    }
    
    func onSave(_ results: [SearchBuilderResult], searchName: String) {
        let filter = filterFromResults(results)
        QUserQueryStore.saveUserQuery(withQuery: filter.searchTokens(), account: filter.account, name: searchName, externalId: nil, updatedAt: nil)
    }
    
    fileprivate func filterFromResults(_ results: [SearchBuilderResult]) -> QIssueFilter {
        let filter = QIssueFilter()
        var text: String = ""
        
        let issueNumbers = NSMutableOrderedSet()
        let issueStates = NSMutableOrderedSet()
        let assignees = NSMutableOrderedSet()
        let authors = NSMutableOrderedSet()
        let mentions = NSMutableOrderedSet()
        let repos = NSMutableOrderedSet()
        let milestones = NSMutableOrderedSet()
        let labels = NSMutableOrderedSet()
        
        
        let assigneeExcludes = NSMutableOrderedSet()
        let authorExcludes = NSMutableOrderedSet()
        let mentionExcludes = NSMutableOrderedSet()
        let repoExcludes = NSMutableOrderedSet()
        let milestoneExcludes = NSMutableOrderedSet()
        let labelExcludes = NSMutableOrderedSet()
        
        results.forEach { (result) in
            guard let criteriaType = StandardSearchBuilderCriteriaType(rawValue: result.criteriaType) else { return }
            
            switch(criteriaType) {
            case .IssueState:
                if let val = result.criteriaValue {
                    if val == "open" {
                        issueStates.add(NSNumber(value: IssueStoreIssueState_Open))
                    } else if val == "closed" {
                        issueStates.add(NSNumber(value: IssueStoreIssueState_Closed))
                    }
                }
            case .IssueNumber:
                if let val = result.criteriaValue , (val as NSString).trimmedString().length > 0 {
                    issueNumbers.add(val)
                }
            case .Text:
                if let val = result.criteriaValue , (val as NSString).trimmedString().length > 0 {
                    text = "\(text) \(val)"
                }
            case .Assignee:
                guard let partOfSpeech = result.partOfSpeech, let pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                if pos == .Unspecified {
                    assignees.add(NSNull())
                } else {
                    let set = pos == .Equals ? assignees : assigneeExcludes
                    if let val = result.criteriaValue , (val as NSString).trimmedString().length > 0 {
                        set.add(val)
                    }
                }
            case .Author:
                guard let partOfSpeech = result.partOfSpeech, let pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                let set = pos == .Equals ? authors : authorExcludes
                if let val = result.criteriaValue , (val as NSString).trimmedString().length > 0 {
                    set.add(val)
                }
            case .Mentions:
                guard let partOfSpeech = result.partOfSpeech, let pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                let set = pos == .Equals ? mentions : mentionExcludes
                if let val = result.criteriaValue , (val as NSString).trimmedString().length > 0 {
                    set.add(val)
                }
            case .Repository:
                guard let partOfSpeech = result.partOfSpeech, let pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                let set = pos == .Equals ? repos : repoExcludes
                if let val = result.criteriaValue , (val as NSString).trimmedString().length > 0 {
                    set.add(val)
                }
            case .Milestone:
                guard let partOfSpeech = result.partOfSpeech, let pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                if pos == .Unspecified {
                    milestones.add(NSNull())
                } else {
                    let set = pos == .Equals ? milestones : milestoneExcludes
                    if let val = result.criteriaValue , (val as NSString).trimmedString().length > 0 {
                        set.add(val)
                    }
                }
            case .Label:
                guard let partOfSpeech = result.partOfSpeech, let pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                if pos == .Unspecified {
                    labels.add(NSNull())
                } else {
                    let set = pos == .Equals ? labels : labelExcludes
                    if let val = result.criteriaValue , (val as NSString).trimmedString().length > 0 {
                        set.add(val)
                    }
                }
            }
        }
        
        filter.issueNumbers = issueNumbers
        filter.states = issueStates
        filter.query = text
        filter.assignees = assignees
        filter.assigneeExcludes = assigneeExcludes
        filter.authors = authors
        filter.authorExcludes = authorExcludes
        filter.mentions = mentions
        filter.mentionExcludes = mentionExcludes
        filter.repositories = repos
        filter.repositorieExcludes = repoExcludes
        filter.milestones = milestones
        filter.milestoneExcludes = milestoneExcludes
        filter.labels = labels
        filter.labelExcludes = labelExcludes
        
        filter.account = QContext.shared().currentAccount
        
        return filter
    }
    
}
