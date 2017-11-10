//
//  CreateIssueRequest.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 3/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class CreateIssueRequest: NSObject {
    
    var repositoryFullName: String?
    var milestoneNumber: NSNumber?
    var assigneeLogin: String?
    var labels: [String]?

}
