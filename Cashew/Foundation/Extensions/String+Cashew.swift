//
//  String+Cashew.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/31/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation


extension String {
    
    func hasPrefixMatchingRegex(_ pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let matches = regex.matches(in: self, options: .reportCompletion, range: NSMakeRange(0, self.characters.count))
            return matches.count > 0
        } catch {
            DDLogDebug("error hasPrefixMatchingRegex.pattern -> \(pattern) error -> \(error)")
        }
        
        return false
    }
    
    
    func stringByReplaceOccurrencesOfRegex(_ pattern: String, withTemplate template: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            return regex.stringByReplacingMatches(in: self, options: .reportCompletion, range: NSMakeRange(0, self.characters.count), withTemplate: template)
            
        } catch {
            DDLogDebug("error hasPrefixMatchingRegex.pattern -> \(pattern) error -> \(error)")
        }
        return self
    }
    
}
