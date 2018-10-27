//
//  QAccount+Cashew.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/25/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation


extension QAccount {
    
    class func isCurrentUserCollaboratorOfRepository(_ repository: QRepository) -> Bool {
        let account = QContext.shared().currentAccount
        return (account?.isCollaboratorOfRepository(repository))!
    }
    
    func isCollaboratorOfRepository(_ repository: QRepository) -> Bool {
        return QOwnerStore.isCollaboratorUserId(userId, forAccountId: identifier, repositoryId: repository.identifier)
    }
    
}
