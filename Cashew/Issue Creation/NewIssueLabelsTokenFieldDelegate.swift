//
//  NewIssueLabelsTokenFieldDelegate.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 3/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa
import os.log

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
    
    private func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<UnsafeMutablePointer<Int>>?) -> [Any]? {
        os_log("NewIssueLabelsTokenFieldDelegate completionsForSubstring - %@ selectedIndex = %d", log: .default, type: .debug, substring, selectedIndex?.pointee.pointee ?? "")
        let trimmedSubstring = substring.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if let repo = self.repository,
            trimmedSubstring.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            let labels = QLabelStore.searchLabels(withQuery: "\(trimmedSubstring)*",
                forAccountId: repo.account.identifier,
                repositoryId: repo.identifier) as! [QLabel]
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
    
    func controlTextDidEndEditing(_ notification: Notification) {
        os_log("NewIssueLabelsTokenFieldDelegate controlTextDidEnd", log: .default, type: .debug)
        if let tokenField = notification.object as? NSTokenField {
            var finalTokenList = [String]()
            
            if let tokens = tokenField.objectValue as? [String] { //, let repo = self.repository {
                tokens.forEach({ (token) in
//                    let labels = QLabelStore.searchLabels(withQuery: token,
//                                                          forAccountId: repo.account.identifier,
//                                                          repositoryId: repo.identifier) as! [QLabel]
//                    for label in labels {
//                        if label.name == token {
                            finalTokenList.append(token)
//                            break
//                        }
//                    }
                })
            }
            
            tokenField.objectValue = finalTokenList
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        os_log("NewIssueLabelsTokenFieldDelegate tokenField shouldAdd - tokens = %@ index = %d", log: .default, type: .debug, tokens, index)

        guard let stringTokens = tokens as? [String] else { return tokens }
        var uniqueTokens = Set<String>()
        var countOfDups: Int = 0
        for token in stringTokens {
            if let existingTokens = tokenField.objectValue as? [String] {
                os_log("NewIssueLabelsTokenFieldDelegate shouldAdd - existing tokens: %@", log: .default, type: .debug, existingTokens)
                existingTokens.forEach { (existingToken) in
                    if (existingToken == token) {
                        os_log("NewIssueLabelsTokenFieldDelegate shouldAdd - found dup of: %@ in existing tokens: %@", log: .default, type: .debug, token, existingTokens)
                        countOfDups += 1
                    }
                }
            }
            if countOfDups < 2 {
                uniqueTokens.insert(token)
            }
        }
        
        let resultTokens = Array(uniqueTokens)
        os_log("NewIssueLabelsDelegate shouldAdd - returning: %@", log: .default, type: .debug, resultTokens)
        return resultTokens
        
    }
    
}
