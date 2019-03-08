//
//  QIssueComment.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/24/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class QIssueComment: NSObject, QIssueCommentInfo, SRIssueDetailItem {
    
    @objc var identifier: NSNumber!
    @objc var repository: QRepository?
    @objc var account: QAccount? {
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
    @objc var body: String!
    @objc var issueNumber: NSNumber!
    @objc var createdAt: Date!
    @objc var updatedAt: Date!
    @objc var user: QOwner!
    @objc var htmlURL: URL?
    
    @objc var thumbsUpCount: Int = 0
    @objc var thumbsDownCount: Int = 0
    @objc var laughCount: Int = 0
    @objc var hoorayCount: Int = 0
    @objc var confusedCount: Int = 0
    @objc var heartCount: Int = 0
    
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
    
    func sortDate() -> Date! {
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
    
    func commentUpdatedAt() -> Date {
        return updatedAt
    }
    
    @objc static func fromJSON(_ json: NSDictionary) -> QIssueComment {
        
        let issueComment = QIssueComment()
        
        issueComment.identifier = json["id"] as! NSNumber
        issueComment.body = json["body"] as! String
        
        let createdAt = json["created_at"] as! String
        let updatedAt = json["updated_at"] as! String
        
        issueComment.createdAt = Date.githubDateFormatter.date(from: createdAt)
        issueComment.updatedAt = Date.githubDateFormatter.date(from: updatedAt)
        
        issueComment.user = QOwner.fromJSON(json["user"] as! [AnyHashable: Any])
        
        if let htmlUrlString = json["html_url"] as? String {
            issueComment.htmlURL = URL(string: htmlUrlString)
        }
        
        if let reactionsJSON = json["reactions"] as? [AnyHashable: Any] {
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
    
    override func isEqual(_ object: Any?) -> Bool {
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
    
    func usernameAvatarURL() -> URL {
        return self.user.avatarURL
    }
    
    func commentedOn() -> Date {
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
