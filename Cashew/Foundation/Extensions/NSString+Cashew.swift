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
    public func textSizeForWithAttributes(_ attrs: [NSAttributedString.Key : Any], containerSize: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)) -> NSSize {
        let attributedStr = NSMutableAttributedString(string: String(self), attributes: attrs)
        return attributedStr.textSize(containerSize: containerSize)
    }
    
    @objc
    public func trimmedString() -> NSString {
        return (self as NSString).trimmingCharacters(in: CharacterSet.whitespaces) as NSString
    }
    
    
    @objc
    public func isURL() -> Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector.matches(in: self as String, options: [], range: NSRange(location: 0, length: (self as String).utf16.count))
        
        var matched = false
        for match in matches {
            let url = (self as NSString).substring(with: match.range)
            if url == self as String {
                matched = true
            }
            break
        }
        
        return matched
    }
}

