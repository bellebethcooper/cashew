//
//  NewIssueAssigneeTokenFieldDelegate.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 3/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class NewIssueAssigneeTokenFieldDelegate: NSObject {
    var repository: QRepository?  {
        didSet {
            resetResults()
        }
    }
    
    var recentResults = [QOwner]()
    
    fileprivate func resetResults() {
        recentResults.removeAll()
        guard let repository = repository else {
            return
        }
        recentResults = QOwnerStore.owners(forAccountId: repository.account.identifier, repositoryId: repository.identifier)
    }
}


extension NewIssueAssigneeTokenFieldDelegate: NSTokenFieldDelegate {
    
    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
        //print("completionsForSubstring = \(substring) selectedIndex = \(selectedIndex)")
        
        let trimmedSubstring = substring.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if let repo = self.repository , trimmedSubstring.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            if let users = QOwnerStore.searchUser(withQuery: "\(trimmedSubstring)*", forAccountId: repo.account.identifier, repositoryId: repo.identifier) {
                let userStrings = users.map({ (user) -> AnyObject in
                    return user.login as AnyObject
                })
                self.recentResults = users
                // print("userStrings = \(userStrings)")
                return userStrings
            }
        }
        
        return []
    }
    
    
    override func controlTextDidEndEditing(_ notification: Notification) {
        if let tokenField = notification.object as? NSTokenField {
            var exists: Bool = false
            if let tokens = tokenField.objectValue as? [String], let token = tokens.last {
                for owner in self.recentResults {
                    if owner.login == token {
                        exists = true
                        break;
                    }
                }
            }
            if !exists {
                tokenField.objectValue = []
            }
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        if let lastToken = tokens.last as? String, let existingTokens = tokenField.objectValue as? [String] {
            if existingTokens.count > 1 {
                return []
            }
            
            var exists: Bool = false
            for owner in self.recentResults {
                if owner.login == lastToken {
                    exists = true
                    break;
                }
            }
            
            if exists {
                return [lastToken]
            } else {
                return []
            }
        }
        return []
    }
    
}
