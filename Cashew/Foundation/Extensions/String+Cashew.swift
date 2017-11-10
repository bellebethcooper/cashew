//
//  String+Cashew.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/31/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation


extension String {
    
    func hasPrefixMatchingRegex(pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.CaseInsensitive, .DotMatchesLineSeparators])
            let matches = regex.matchesInString(self, options: .ReportCompletion, range: NSMakeRange(0, self.characters.count))
            return matches.count > 0
        } catch {
            DDLogDebug("error hasPrefixMatchingRegex.pattern -> \(pattern) error -> \(error)")
        }
        
        return false
    }
    
    
    func stringByReplaceOccurrencesOfRegex(pattern: String, withTemplate template: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.CaseInsensitive, .DotMatchesLineSeparators])
            return regex.stringByReplacingMatchesInString(self, options: .ReportCompletion, range: NSMakeRange(0, self.characters.count), withTemplate: template)
            
        } catch {
            DDLogDebug("error hasPrefixMatchingRegex.pattern -> \(pattern) error -> \(error)")
        }
        return self
    }
    
}