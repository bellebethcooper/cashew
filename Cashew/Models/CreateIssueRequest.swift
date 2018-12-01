//
//  CreateIssueRequest.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 3/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class CreateIssueRequest: NSObject {
    
    @objc var repositoryFullName: String?
    @objc var milestoneNumber: NSNumber?
    @objc var assigneeLogin: String?
    @objc var labels: [String]?

}
