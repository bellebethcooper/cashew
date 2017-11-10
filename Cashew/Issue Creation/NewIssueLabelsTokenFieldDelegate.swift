//
//  NewIssueLabelsTokenFieldDelegate.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 3/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class NewIssueLabelsTokenFieldDelegate: NSObject {
    var repository: QRepository? {
        didSet {
            resetResults()
        }
    }
    
    var recentResults = [QLabel]()
    
    private func resetResults() {
        recentResults.removeAll()
    }
}


extension NewIssueLabelsTokenFieldDelegate: NSTokenFieldDelegate {
    
    func tokenField(tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>) -> [AnyObject]? {
        // print("completionsForSubstring = \(substring) selectedIndex = \(selectedIndex)")
        let trimmedSubstring = substring.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if let repo = self.repository where trimmedSubstring.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            let labels = QLabelStore.searchLabelsWithQuery("\(trimmedSubstring)*", forAccountId: repo.account.identifier, repositoryId: repo.identifier) as NSArray as! [QLabel]
            self.recentResults = labels
            let labelStrings = self.recentResults.map({ (label) -> AnyObject in
                return label.name!
            })
            print("result = \(labelStrings)")
            return labelStrings
        } else {
            return []
        }
    }
    
    override func controlTextDidEndEditing(notification: NSNotification) {
        if let tokenField = notification.object as? NSTokenField {
            var finalTokenList = [String]()
            
            if let tokens = tokenField.objectValue as? [String], repo = self.repository {
                tokens.forEach({ (token) in
                    let labels = QLabelStore.searchLabelsWithQuery(token, forAccountId: repo.account.identifier, repositoryId: repo.identifier) as NSArray as! [QLabel]
                    for label in labels {
                        if label.name == token {
                            finalTokenList.append(token)
                            break
                        }
                    }
                })
            }
            
            tokenField.objectValue = finalTokenList
        }
    }
    
    func tokenField(tokenField: NSTokenField, shouldAddObjects tokens: [AnyObject], atIndex index: Int) -> [AnyObject] {
        //print("tokens = \(tokens) index = \(index)")
        
        var uniqueTokens = Set<String>()
        for label in self.recentResults {
            if let stringTokens = tokens as? [String], name = label.name where stringTokens.contains(name) {
                
                var countOfDups: Int = 0
                if let existingTokens = tokenField.objectValue as? [String] {
                    existingTokens.forEach { (existingToken) in
                        if (existingToken == name) {
                            countOfDups += 1
                        }
                    }
                }
                //print("existingTokens =\(tokenField.objectValue) and countOfDups = \(countOfDups)")
                if countOfDups == 1 || countOfDups == 0 {
                    uniqueTokens.insert(name)
                }
            }
        }
        
        let resultTokens = Array(uniqueTokens)
        
        return resultTokens
    }
    
}