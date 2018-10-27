//
//  AccountsPreferenceDataSource.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/2/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class AccountsPreferenceDataSource: NSObject {

    fileprivate var accounts = [QAccount]()
    
    func reloadData() {
        accounts = QAccountStore.accounts()
    }
    
    var numberOfRows: Int {
        get {
            return accounts.count
        }
    }
    
    func itemAtIndex(_ index: Int) -> QAccount {
        return accounts[index]
    }
    
    
}
