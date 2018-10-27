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
    
    fileprivate func resetResults() {
        recentResults.removeAll()
    }
}


extension NewIssueLabelsTokenFieldDelegate: NSTokenFieldDelegate {
    
    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<UnsafeMutablePointer<Int>>?) -> [Any]? {
        // print("completionsForSubstring = \(substring) selectedIndex = \(selectedIndex)")
        let trimmedSubstring = substring.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if let repo = self.repository , trimmedSubstring.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            let labels = QLabelStore.searchLabels(withQuery: "\(trimmedSubstring)*", forAccountId: repo.account.identifier, repositoryId: repo.identifier) as NSArray as! [QLabel]
            self.recentResults = labels
            let labelStrings = self.recentResults.map({ (label) -> Any in
                return label.name!
            })
            print("result = \(labelStrings)")
            return labelStrings
        } else {
            return []
        }
    }
    
    override func controlTextDidEndEditing(_ notification: Notification) {
        if let tokenField = notification.object as? NSTokenField {
            var finalTokenList = [String]()
            
            if let tokens = tokenField.objectValue as? [String], let repo = self.repository {
                tokens.forEach({ (token) in
                    let labels = QLabelStore.searchLabels(withQuery: token, forAccountId: repo.account.identifier, repositoryId: repo.identifier) as NSArray as! [QLabel]
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
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        //print("tokens = \(tokens) index = \(index)")
        
        var uniqueTokens = Set<String>()
        for label in self.recentResults {
            if let stringTokens = tokens as? [String], let name = label.name , stringTokens.contains(name) {
                
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
