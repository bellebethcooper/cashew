//
//  IssueEventInfo.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/25/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation


enum IssueEventTypeInfo: String {
    case GroupedLabel = "_cashew_grouped_labels";
    case GroupedMilestone = "_cashew_grouped_milestones";
    case GroupedAssignee = "_cashew_grouped_assignee";
}

@objc(SRIssueEventInfo)
protocol IssueEventInfo: NSObjectProtocol, SRIssueDetailItem {
    var actor: QOwner! { get set }
    var event: NSString? { get set }
    var createdAt: NSDate! { get set }
    
    var additions: NSMutableOrderedSet { get }
    var removals: NSMutableOrderedSet { get }
}