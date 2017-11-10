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
    
    
    func onSearch(results: [SearchBuilderResult]) {
        QContext.sharedContext().currentFilter = filterFromResults(results)
    }
    
    func onSave(results: [SearchBuilderResult], searchName: String) {
        let filter = filterFromResults(results)
        QUserQueryStore.saveUserQueryWithQuery(filter.searchTokens(), account: filter.account, name: searchName, externalId: nil, updatedAt: nil)
    }
    
    private func filterFromResults(results: [SearchBuilderResult]) -> QIssueFilter {
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
                        issueStates.addObject(NSNumber(integer: IssueStoreIssueState_Open))
                    } else if val == "closed" {
                        issueStates.addObject(NSNumber(integer: IssueStoreIssueState_Closed))
                    }
                }
            case .IssueNumber:
                if let val = result.criteriaValue where (val as NSString).trimmedString().length > 0 {
                    issueNumbers.addObject(val)
                }
            case .Text:
                if let val = result.criteriaValue where (val as NSString).trimmedString().length > 0 {
                    text = "\(text) \(val)"
                }
            case .Assignee:
                guard let partOfSpeech = result.partOfSpeech, pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                if pos == .Unspecified {
                    assignees.addObject(NSNull())
                } else {
                    let set = pos == .Equals ? assignees : assigneeExcludes
                    if let val = result.criteriaValue where (val as NSString).trimmedString().length > 0 {
                        set.addObject(val)
                    }
                }
            case .Author:
                guard let partOfSpeech = result.partOfSpeech, pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                let set = pos == .Equals ? authors : authorExcludes
                if let val = result.criteriaValue where (val as NSString).trimmedString().length > 0 {
                    set.addObject(val)
                }
            case .Mentions:
                guard let partOfSpeech = result.partOfSpeech, pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                let set = pos == .Equals ? mentions : mentionExcludes
                if let val = result.criteriaValue where (val as NSString).trimmedString().length > 0 {
                    set.addObject(val)
                }
            case .Repository:
                guard let partOfSpeech = result.partOfSpeech, pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                let set = pos == .Equals ? repos : repoExcludes
                if let val = result.criteriaValue where (val as NSString).trimmedString().length > 0 {
                    set.addObject(val)
                }
            case .Milestone:
                guard let partOfSpeech = result.partOfSpeech, pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                if pos == .Unspecified {
                    milestones.addObject(NSNull())
                } else {
                    let set = pos == .Equals ? milestones : milestoneExcludes
                    if let val = result.criteriaValue where (val as NSString).trimmedString().length > 0 {
                        set.addObject(val)
                    }
                }
            case .Label:
                guard let partOfSpeech = result.partOfSpeech, pos = StandardSearchBuilderPartOfSpeech(rawValue: partOfSpeech) else { return }
                if pos == .Unspecified {
                    labels.addObject(NSNull())
                } else {
                    let set = pos == .Equals ? labels : labelExcludes
                    if let val = result.criteriaValue where (val as NSString).trimmedString().length > 0 {
                        set.addObject(val)
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
        
        filter.account = QContext.sharedContext().currentAccount
        
        return filter
    }
    
}
