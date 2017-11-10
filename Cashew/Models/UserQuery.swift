//
//  QUserQuery.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/31/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(QUserQuery)
class UserQuery: NSObject {
    
    var identifier: NSNumber?
    var account: QAccount
    var displayName: String
    var query: String
    var externalId: String?
    var updatedAt: NSDate?
    
    required init(identifier: NSNumber?, account: QAccount, displayName: String, query: String) {
        self.identifier = identifier
        self.account = account
        self.displayName = displayName
        self.query = query
        super.init()
    }
    
    override var description: String {
        return "identifier=\(identifier), displayName=\(displayName), query=\(query), accountId=\(account.identifier)"
        
    }
    
    override var hashValue: Int {
        if let identifier = identifier {
            return account.identifier.hashValue ^ identifier.hashValue
        }
        return account.identifier.hashValue ^ query.hashValue
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        guard let object = object as? UserQuery else { return false }
        return object.identifier == self.identifier && object.query == self.query
    }
}

func ==(lhs: UserQuery, rhs: UserQuery) -> Bool {
    return lhs.account.identifier == rhs.account.identifier && lhs.identifier == rhs.identifier
}


