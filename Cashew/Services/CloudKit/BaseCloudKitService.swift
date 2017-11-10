//
//  BaseCloudKitService.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/1/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import CloudKit

enum CloudRecordType: String {
    // legacy
    case LegacySourceListRepository2 = "Repositories"
    case LegacySourceListRepository1 = "SLRepository"
    case LegacySourceListUserQuery1 = "UserQueries"
    case LegacySourceListUserQuery2 = "SLUserQuery"
    
    // new
    case UserQuery = "UserQuery"
    case Repository = "Repository"
    case CodeExtension = "CodeExtension"
}

typealias CloudOnCompletion = ((AnyObject?, NSError?) -> Void)


class BaseCloudKitService: NSObject {

}
