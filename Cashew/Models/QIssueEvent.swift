//
//  QIssueEvent.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/26/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class QIssueEvent: NSObject, IssueEventInfo, SRIssueDetailItem {
    
    var identifier: NSNumber!
    var actor: QOwner!
    var issueNumber: NSNumber!
    var createdAt: Date!
    var event: NSString?
    var commitId: NSString?
    var label: QLabel?
    var assignee: QOwner?
    var milestone: QMilestone?
    var renameFrom: NSString?
    var renameTo: NSString?
    var account: QAccount? {
        didSet {
            if let anAccount = account {
                self.repository?.account = anAccount
                self.actor?.account = anAccount
                self.assignee?.account = anAccount
                self.milestone?.account = anAccount
                self.label?.account = anAccount
            } else {
                self.repository?.account = nil
                self.actor?.account = nil
                self.assignee?.account = nil
                self.milestone?.account = nil
                self.label?.account = nil
            }
        }
    }
    
    var repository: QRepository? {
        didSet {
            
            if let aRepository = repository {
                self.milestone?.repository = aRepository
                self.label?.repository = aRepository
            } else {
                self.milestone?.repository = nil
                self.label?.repository = nil
            }
        }
    }
    
    func sortDate() -> Date! {
        return self.createdAt
    }
    
    var additions: NSMutableOrderedSet {
        get {
            guard let event = event else { return NSMutableOrderedSet() }
            
            if let labelName = label?.name , event == "labeled" {
                return [labelName]
            } else if let milestoneName = milestone?.title , event == "milestoned" {
                return NSMutableOrderedSet(array: [milestoneName])
            }
            return NSMutableOrderedSet()
        }
    }
    
    var removals: NSMutableOrderedSet  {
        get {
            guard let event = event else { return NSMutableOrderedSet() }
            
            if let labelName = label?.name , event == "unlabeled" {
                return [labelName]
            } else if let milestoneName = milestone?.title , event == "demilestoned" {
                return NSMutableOrderedSet(array: [milestoneName])
            }
            return NSMutableOrderedSet()
        }
    }
    
    override var description: String {
        return "IssueEvent: actor=\(actor.login) createdAt=\(createdAt) event=\(event) label=\(label) milestone=\(milestone?.title) renameFrom=\(renameFrom) renameTo=\(renameTo)"
    }
    
    static func fromJSON(_ json: NSDictionary) -> QIssueEvent {
        let event = QIssueEvent()
        
        event.identifier = json["id"] as! NSNumber
        event.actor = QOwner.fromJSON(json["actor"] as? [AnyHashable: Any])
        
        let createdAt = json["created_at"] as! String
        event.createdAt = Date.githubDateFormatter.date(from: createdAt)
        
        event.event = json["event"] as? NSString
        
        if let theCommitId = json["commit_id"] as? String {
            event.commitId = theCommitId as NSString?
        }
        
        if let anAssignee = json["assignee"] as? [AnyHashable: Any] {
            event.assignee = QOwner.fromJSON(anAssignee)
        }
        
        if let aMilestone = json["milestone"] as? [AnyHashable: Any] {
            event.milestone = QMilestone.fromJSON(aMilestone)
        }
        
        if let rename = json["rename"] as? [String: Any] {
            event.renameFrom = rename["from"] as? NSString
            event.renameTo = rename["to"] as? NSString
        }
        
        if let aLabel = json["label"] as? [AnyHashable: Any] {
            event.label = QLabel.fromJSON(aLabel)
        }
        
        //        if let labelsJSONArray = json["label"] as? [AnyObject] {
        //            event.labels = []
        //            for labelJSON in labelsJSONArray {
        //                let label = QLabel.fromJSON(labelJSON as! [NSObject : AnyObject])
        //                event.labels?.append(label)
        //            }
        //        }
        
        return event
    }
    
    
}
