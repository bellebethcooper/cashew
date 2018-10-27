//
//  IssueEventViewModel.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/25/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRIssueEventViewModel)
class IssueEventViewModel: NSObject, IssueEventInfo {

    var actor: QOwner!
    var createdAt: Date!
    var event: NSString?
    var additions: NSMutableOrderedSet
    var removals: NSMutableOrderedSet
    
    required init(actor: QOwner, createdAt: Date, event: NSString) {
        self.actor = actor
        self.createdAt = createdAt
        self.event = event
        self.additions = NSMutableOrderedSet()
        self.removals = NSMutableOrderedSet()
        super.init()
    }
}


extension IssueEventViewModel: SRIssueDetailItem {
    func sortDate() -> Date! {
        return self.createdAt
    }
}
