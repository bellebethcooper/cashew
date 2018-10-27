//
//  Organization.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

//(SROrganization)
class Organization: NSObject {
    
    let login: String
    let identifier: NSNumber
    let avatarURL: NSURL?
    let desc: String?
    let account: QAccount
    
    required init (account: QAccount, identifier: NSNumber, login: String, avatarURL: NSURL?, desc: String?) {
        self.identifier = identifier
        self.login = login
        self.avatarURL = avatarURL
        self.desc = desc
        self.account = account;
        super.init()
    }

    class func fromJSON(_ dict: NSDictionary, account: QAccount) -> Organization? {
        guard let login = dict["login"] as? String, let identifier = dict["id"] as? NSNumber else {
            return nil
        }
        
        let desc = dict["description"] as? String
        let avatarURL: NSURL?
        if let avatarURLString = dict["avatar_url"] as? String {
            avatarURL = NSURL(string: avatarURLString)
        } else {
            avatarURL = nil
        }
        
        return Organization(account: account, identifier: identifier, login: login, avatarURL: avatarURL, desc: desc)
    }
    
}
