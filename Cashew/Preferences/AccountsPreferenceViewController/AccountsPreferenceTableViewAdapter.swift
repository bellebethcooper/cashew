//
//  AccountsPreferenceTableViewAdapter.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/2/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class AccountsPreferenceTableViewAdapter: NSObject, BaseTableViewAdapter {

    func height(_ item: AnyObject, index: Int) -> CGFloat {
        return 30.0
    }
    
    func adapt(_ view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView? {
        guard let account = item as? QAccount else { return nil }
        
        let rowView: AccountPreferenceTableViewRow
        if let view = view as? AccountPreferenceTableViewRow {
            rowView = view
            rowView.account = account
        } else {
            rowView = AccountPreferenceTableViewRow(account: account)
        }
        
        return rowView
    }
}
