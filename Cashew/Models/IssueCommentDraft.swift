//
//  IssueCommentDraft.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/13/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRIssueCommentDraftType)
enum IssueCommentDraftType: NSInteger {
    case issue
    case comment
}

@objc(SRIssueCommentDraft)
class IssueCommentDraft: NSObject {

    let account: QAccount
    let repository: QRepository
    let issueCommentId: NSNumber?
    let issueNumber: NSNumber
    @objc let body: String
    let type: IssueCommentDraftType
    
    @objc required init(account: QAccount, repository: QRepository, issueCommentId: NSNumber?, issueNumber: NSNumber, body: String, type: IssueCommentDraftType) {
        self.account = account
        self.repository = repository
        self.issueCommentId = issueCommentId
        self.issueNumber = issueNumber
        self.body = body
        self.type = type
        super.init()
    }
}
