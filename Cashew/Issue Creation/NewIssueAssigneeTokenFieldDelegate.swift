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
    
    private func resetResults() {
        recentResults.removeAll()
        guard let repository = repository else {
            return
        }
        recentResults = QOwnerStore.ownersForAccountId(repository.account.identifier, repositoryId: repository.identifier)
    }
}


extension NewIssueAssigneeTokenFieldDelegate: NSTokenFieldDelegate {
    
    func tokenField(tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>) -> [AnyObject]? {
        //print("completionsForSubstring = \(substring) selectedIndex = \(selectedIndex)")
        
        let trimmedSubstring = substring.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if let repo = self.repository where trimmedSubstring.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            let users = QOwnerStore.searchUserWithQuery("\(trimmedSubstring)*", forAccountId: repo.account.identifier, repositoryId: repo.identifier)
            let userStrings = users.map({ (user) -> AnyObject in
                return user.login!
            })
            self.recentResults = users
            // print("userStrings = \(userStrings)")
            return userStrings
        }
        
        return []
    }
    
    
    override func controlTextDidEndEditing(notification: NSNotification) {
        if let tokenField = notification.object as? NSTokenField {
            var exists: Bool = false
            if let tokens = tokenField.objectValue as? [String], token = tokens.last {
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
    
    func tokenField(tokenField: NSTokenField, shouldAddObjects tokens: [AnyObject], atIndex index: Int) -> [AnyObject] {
        if let lastToken = tokens.last as? String, existingTokens = tokenField.objectValue as? [String] {
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