//
//  QAccount+Cashew.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/25/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation


extension QAccount {
    
    class func isCurrentUserCollaboratorOfRepository(repository: QRepository) -> Bool {
        let account = QContext.sharedContext().currentAccount
        return account.isCollaboratorOfRepository(repository)
    }
    
    func isCollaboratorOfRepository(repository: QRepository) -> Bool {
        return QOwnerStore.isCollaboratorUserId(userId, forAccountId: identifier, repositoryId: repository.identifier)
    }
    
}