//
//  NSUserDefaults+Conversions.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/24/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

extension NSUserDefaults {
    private static let embedLabelsInIssuesConversionDone = "embedLabelsInIssuesConversionDone"
    private static let repositoriesCloudKitSyncConversion = "repositoriesCloudKitSyncConversion"
    
    
    
    class func didRunEmbedLabelsInIssuesConversion() -> Bool {
        let value = NSUserDefaults.standardUserDefaults().boolForKey(NSUserDefaults.embedLabelsInIssuesConversionDone)
        return value
    }
    
    class func embedLabelsInIssuesConversionCompleted() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: NSUserDefaults.embedLabelsInIssuesConversionDone)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func didRunRepositoriesCloudKitSyncConversion() -> Bool {
        let value = NSUserDefaults.standardUserDefaults().boolForKey(NSUserDefaults.repositoriesCloudKitSyncConversion)
        return value
    }
    
    class func repositoriesCloudKitSyncConversionCompleted() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: NSUserDefaults.repositoriesCloudKitSyncConversion)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
}