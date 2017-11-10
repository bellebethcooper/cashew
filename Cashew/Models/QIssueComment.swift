//
//  QIssueComment.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/24/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class QIssueComment: NSObject, QIssueCommentInfo, SRIssueDetailItem {
    
    var identifier: NSNumber!
    var repository: QRepository?
    var account: QAccount? {
        didSet {
            if let anAccount = account {
                self.repository?.account = anAccount
                self.user?.account = anAccount
            } else {
                self.repository?.account = nil
                self.user?.account = nil
            }
        }
    }
    var body: String!
    var issueNumber: NSNumber!
    var createdAt: NSDate!
    var updatedAt: NSDate!
    var user: QOwner!
    var htmlURL: NSURL?
    
    var thumbsUpCount: Int = 0
    var thumbsDownCount: Int = 0
    var laughCount: Int = 0
    var hoorayCount: Int = 0
    var confusedCount: Int = 0
    var heartCount: Int = 0
    
    func toExtensionModel() -> NSDictionary {
        let dict = NSMutableDictionary()
        
        dict["identifier"] = identifier
        dict["repository"] = repository?.toExtensionModel()
        dict["body"] = body
        dict["issueNumber"] = issueNumber
        dict["createdAt"] = createdAt
        dict["updatedAt"] = updatedAt ?? NSNull()
        
        return dict
    }
    
    func author() -> QOwner? {
        return user
    }
    
    func sortDate() -> NSDate! {
        return self.createdAt
    }
    
    func issueNum() -> NSNumber {
        return issueNumber
    }
    
    override var hashValue: Int {
        get {
            return (account?.hashValue ?? 0) ^ (repository?.hashValue ?? 0) ^ issueNumber.hashValue ^ identifier.hashValue
        }
    }
    
    func commentUpdatedAt() -> NSDate {
        return updatedAt
    }
    
    static func fromJSON(json: NSDictionary) -> QIssueComment {
        
        let issueComment = QIssueComment()
        
        issueComment.identifier = json["id"] as! NSNumber
        issueComment.body = json["body"] as! String
        
        let createdAt = json["created_at"] as! String
        let updatedAt = json["updated_at"] as! String
        
        issueComment.createdAt = NSDate.githubDateFormatter().dateFromString(createdAt)
        issueComment.updatedAt = NSDate.githubDateFormatter().dateFromString(updatedAt)
        
        issueComment.user = QOwner.fromJSON(json["user"] as! [NSObject : AnyObject])
        
        if let htmlUrlString = json["html_url"] as? String {
            issueComment.htmlURL = NSURL(string: htmlUrlString)
        }
        
        if let reactionsJSON = json["reactions"] as? [NSObject: AnyObject] {
            if let count = reactionsJSON["+1"] as? Int {
                issueComment.thumbsUpCount = count
            }
            if let count = reactionsJSON["-1"] as? Int {
                issueComment.thumbsDownCount = count
            }
            if let count = reactionsJSON["laugh"] as? Int {
                issueComment.laughCount = count
            }
            if let count = reactionsJSON["confused"] as? Int {
                issueComment.confusedCount = count
            }
            if let count = reactionsJSON["heart"] as? Int {
                issueComment.heartCount = count
            }
            if let count = reactionsJSON["hooray"] as? Int {
                issueComment.hoorayCount = count
            }
        }
        return issueComment
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        guard let other = object as? QIssueComment else { return false }
        return other.account == self.account && other.repository == self.repository && other.identifier == self.identifier
    }
    
    
    override var description: String {
        return String(format: "issueNumber = [%@], commentBody = [%@]", issueNumber, body)
    }
    
    // MARK: - QIssueCommentInfo
    func username() -> String {
        return self.user.login
    }
    
    func commentBody() -> String {
        return self.body ?? ""
    }
    
    func usernameAvatarURL() -> NSURL {
        return self.user.avatarURL
    }
    
    func commentedOn() -> NSDate {
        return self.createdAt
    }
    
    
    func repo() -> QRepository {
        return self.repository!
    }
    
    func markdownCacheKey() -> String {
        return "issue_comment_\(self.account?.identifier)_\(self.repository?.identifier)_\(self.issueNumber)_\(self.identifier)_\(self.updatedAt)"
    }
}

func ==(lhs: QIssueComment, rhs: QIssueComment) -> Bool {
    return lhs.account == rhs.account && lhs.identifier == rhs.identifier && lhs.repository == rhs.repository
}
