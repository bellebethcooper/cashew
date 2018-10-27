//
//  NSDate+Formats.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/23/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


public extension Date {
    
    // MARK: full date formatter
    fileprivate static var fullDateFormatterToken: Int = 0
    fileprivate static var fullDateFormatterInstance: DateFormatter?
    
    public static var fullDateFormatter: DateFormatter = {
        fullDateFormatterInstance = DateFormatter()
        fullDateFormatterInstance?.dateFormat = "M/d/yy"
        return fullDateFormatterInstance!
    }()
    
    func toFullDateString() -> NSString {
        return Date.fullDateFormatter.string(from: self) as NSString
    }
    
    
    // MARK: github date formatter
    fileprivate static var githubDateFormatterToken: Int = 0
    fileprivate static var githubDateFormatterInstance: DateFormatter?
    
    public static var githubDateFormatter: DateFormatter = {
        githubDateFormatterInstance = DateFormatter()
        githubDateFormatterInstance?.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return githubDateFormatterInstance!
    }()
    
    func toGithubDateString() -> NSString {
        return Date.fullDateFormatter.string(from: self) as NSString
    }

    
}
