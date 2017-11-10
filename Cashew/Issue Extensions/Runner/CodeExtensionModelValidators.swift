//
//  CodeExtensionModelValidators.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class CodeExtensionModelValidators: NSObject {

    
    class func validateRepository(dictionary: NSDictionary?) -> Bool {
        guard let repo = dictionary else { return false }
        guard let _ = repo["identifier"] as? NSNumber, _ = repo["fullName"] as? String else { return false }
        return true
    }
    
    class func validateIssue(dictionary: NSDictionary?) -> Bool {
        guard let issue = dictionary else { return false }
        guard let _ = issue["identifier"] as? NSNumber, _ = issue["number"] as? NSNumber, repo = issue["repository"] as? NSDictionary where CodeExtensionModelValidators.validateRepository(repo) else { return false }
        return true
    }
    
    class func validateMilestone(dictionary: NSDictionary?) -> Bool {
        guard let milestone = dictionary else { return false }
        guard let _ = milestone["identifier"] as? NSNumber, _ = milestone["number"] as? NSNumber, repo = milestone["repository"] as? NSDictionary where CodeExtensionModelValidators.validateRepository(repo) else { return false }
        return true
    }
    
    class func validateOwner(dictionary: NSDictionary?) -> Bool {
        guard let owner = dictionary else { return false }
        guard let _ = owner["identifier"] as? NSNumber, _ = owner["login"] as? String else { return false }
        return true
    }
    
    class func validateLabel(dictionary: NSDictionary?) -> Bool {
        guard let label = dictionary else { return false }
        guard let _ = label["name"] as? String else { return false }
        return true
    }
    
    class func validateLabels(labels: NSArray?) -> Bool {
        guard let labels = labels else { return false }
        
        for label in labels {
            if let label = label as? NSDictionary where CodeExtensionModelValidators.validateLabel(label) == false {
                return false
            }
        }
        
        return true
    }
    
}
