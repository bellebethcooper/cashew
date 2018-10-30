//
//  NSUserDefaults+Conversions.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/24/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

extension UserDefaults {
    fileprivate static let embedLabelsInIssuesConversionDone = "embedLabelsInIssuesConversionDone"
    fileprivate static let repositoriesCloudKitSyncConversion = "repositoriesCloudKitSyncConversion"
    
    
    
    @objc class func didRunEmbedLabelsInIssuesConversion() -> Bool {
        let value = UserDefaults.standard.bool(forKey: UserDefaults.embedLabelsInIssuesConversionDone)
        return value
    }
    
    @objc class func embedLabelsInIssuesConversionCompleted() {
        UserDefaults.standard.set(true, forKey: UserDefaults.embedLabelsInIssuesConversionDone)
        UserDefaults.standard.synchronize()
    }
    
    class func didRunRepositoriesCloudKitSyncConversion() -> Bool {
        let value = UserDefaults.standard.bool(forKey: UserDefaults.repositoriesCloudKitSyncConversion)
        return value
    }
    
    class func repositoriesCloudKitSyncConversionCompleted() {
        UserDefaults.standard.set(true, forKey: UserDefaults.repositoriesCloudKitSyncConversion)
        UserDefaults.standard.synchronize()
    }
    
}
