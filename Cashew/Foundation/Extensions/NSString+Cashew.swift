//
//  NSString+Cashew.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


extension NSString {
    
    
    @objc
    public func textSizeForWithAttributes(attrs: [String : AnyObject], containerSize: CGSize = CGSizeMake(CGFloat.max, CGFloat.max)) -> NSSize {
        let attributedStr = NSMutableAttributedString(string: String(self), attributes: attrs)
        return attributedStr.textSize(containerSize: containerSize)
    }
    
    @objc
    public func trimmedString() -> NSString {
        return (self as NSString).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    
    @objc
    public func isURL() -> Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        let matches = detector.matchesInString(self as String, options: [], range: NSRange(location: 0, length: (self as String).utf16.count))
        
        var matched = false
        for match in matches {
            let url = (self as NSString).substringWithRange(match.range)
            if url == self {
                matched = true
            }
            break
        }
        
        return matched
    }
}

