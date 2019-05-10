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
    @objc var displayName: String
    @objc var query: String
    var externalId: String?
    var updatedAt: Date?
    
    @objc required init(identifier: NSNumber?, account: QAccount, displayName: String, query: String) {
        self.identifier = identifier
        self.account = account
        self.displayName = displayName
        self.query = query
        super.init()
    }
    
    override var description: String {
        return "identifier=\(identifier), displayName=\(displayName), query=\(query), accountId=\(account.identifier)"
        
    }
    
  override var hash: Int {
        if let identifier = identifier {
            return account.identifier.hashValue ^ identifier.hashValue
        }
        return account.identifier.hashValue ^ query.hashValue
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? UserQuery else { return false }
        return object.identifier == self.identifier && object.query == self.query
    }
}

func ==(lhs: UserQuery, rhs: UserQuery) -> Bool {
    return lhs.account.identifier == rhs.account.identifier && lhs.identifier == rhs.identifier
}


