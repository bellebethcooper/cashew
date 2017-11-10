//
//  NSDate+Formats.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/23/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


public extension NSDate {
    
    // MARK: full date formatter
    private static var fullDateFormatterToken: dispatch_once_t = 0
    private static var fullDateFormatterInstance: NSDateFormatter?
    
    public static func fullDateFormatter() -> NSDateFormatter! {
        dispatch_once(&fullDateFormatterToken) {
            fullDateFormatterInstance = NSDateFormatter()
            fullDateFormatterInstance?.dateFormat = "M/d/yy"
        }
        return fullDateFormatterInstance
    }
    
    func toFullDateString() -> NSString {
        return NSDate.fullDateFormatter().stringFromDate(self)
    }
    
    
    // MARK: github date formatter
    private static var githubDateFormatterToken: dispatch_once_t = 0
    private static var githubDateFormatterInstance: NSDateFormatter?
    
    public static func githubDateFormatter() -> NSDateFormatter! {
        dispatch_once(&githubDateFormatterToken) {
            githubDateFormatterInstance = NSDateFormatter()
            githubDateFormatterInstance?.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        }
        return githubDateFormatterInstance
    }
    
    func toGithubDateString() -> NSString {
        return NSDate.fullDateFormatter().stringFromDate(self)
    }

    
}