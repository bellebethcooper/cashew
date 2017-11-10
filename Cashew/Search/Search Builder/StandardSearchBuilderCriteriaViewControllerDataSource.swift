//
//  StandardSearchBuilderCriteriaViewControllerDataSource.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/26/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

enum StandardSearchBuilderCriteriaType: String {
    
    case IssueState = "Issue state"
    case Assignee = "Assignee"
    case Author = "Author"
    case Mentions = "Mentions"
    case Repository = "Repository"
    case Milestone = "Milestone"
    case Label = "Label"
    case IssueNumber = "Issue number"
    case Text = "Text"
    
    static func allValues() -> [StandardSearchBuilderCriteriaType] {
        return [ Assignee, Author, IssueNumber, IssueState, Label, Mentions, Milestone, Repository, Text ]
    }
    
}

enum StandardSearchBuilderPartOfSpeech: String {
    case Equals = "is"
    case NotEquals = "is not"
    case Contains = "contains"
    case Unspecified = "unspecified"
}


class StandardSearchBuilderCriteriaViewControllerDataSource: NSObject, SearchBuilderCriteriaViewControllerDataSource {
    
    var users: [String]?
    var repositories: [String]?
    var milestones: [String]?
    var labels: [String]?
    
    func criteriaFields() -> [String] {
        return StandardSearchBuilderCriteriaType.allValues().map({ $0.rawValue })
    }
    
    func partsOfSpeechForCriteriaField(field: String) -> [String] {
        guard let type = StandardSearchBuilderCriteriaType(rawValue: field) else { return [] }
        
        switch type {
        case .Text:
            return [StandardSearchBuilderPartOfSpeech.Contains.rawValue]
        case .IssueState, .IssueNumber:
            return [StandardSearchBuilderPartOfSpeech.Equals.rawValue] //[StandardSearchBuilderPartOfSpeech.Equals.rawValue]
        case .Author, .Mentions, .Repository:
            return [StandardSearchBuilderPartOfSpeech.Equals.rawValue, StandardSearchBuilderPartOfSpeech.NotEquals.rawValue]
        case .Assignee, .Milestone, .Label:
            return [StandardSearchBuilderPartOfSpeech.Equals.rawValue, StandardSearchBuilderPartOfSpeech.NotEquals.rawValue, StandardSearchBuilderPartOfSpeech.Unspecified.rawValue]
        }
    }
    
    func shouldHideValueForPartOfSpeech(pos: String) -> Bool {
        guard let partOfSpeech = StandardSearchBuilderPartOfSpeech(rawValue: pos) where StandardSearchBuilderPartOfSpeech.Unspecified == partOfSpeech else { return false }
        return true
    }
    
    func valuesForCriteriaField(field: String) -> [String] {
        guard let type = StandardSearchBuilderCriteriaType(rawValue: field) else { return [] }
        return valuesForType(type)
    }
    
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        guard let comboBox = aComboBox as? SearchBuilderValueComboBox, typeString = comboBox.representedObject as? String, type = StandardSearchBuilderCriteriaType(rawValue: typeString) else { return 0 }
        let values = valuesForType(type)
        return values.count
    }
    
    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject? {
        guard let comboBox = aComboBox as? SearchBuilderValueComboBox, let typeString = comboBox.representedObject as? String, type = StandardSearchBuilderCriteriaType(rawValue: typeString) else { return 0 }
        let values = valuesForType(type)
        let value = values[index]
        return value
    }
    
    func resetCachedValues() {
        users = nil
        repositories = nil
        milestones = nil
        labels = nil
    }
    
    private func valuesForType(type: StandardSearchBuilderCriteriaType) -> [String] {
        let account = QContext.sharedContext().currentAccount
        switch type {
        case .IssueNumber, .Text:
            return []
        case .IssueState:
            return ["open", "closed"]
        case .Assignee, .Author, .Mentions:
            if let users = users {
                return users
            } else {
                self.users = QOwnerStore.ownersForAccountId(account.identifier).uniqueMap({ $0.login })
                return self.users!
            }
        case .Repository:
            if let repositories = repositories {
                return repositories
            } else {
                self.repositories = QRepositoryStore.repositoriesForAccountId(account.identifier).uniqueMap({ $0.fullName })
                return self.repositories!
            }
        case .Milestone:
            if let milestones = milestones {
                return milestones
            } else {
                self.milestones = QMilestoneStore.milestonesForAccountId(account.identifier).uniqueMap({ $0.title })
                return self.milestones!
            }
        case .Label:
            if let labels = labels {
                return labels
            } else {
                self.labels = QLabelStore.labelsForAccountId(account.identifier).uniqueMap({ $0.name })
                return self.labels!
            }
        }
    }
    
}
