//
//  AccountsPreferenceViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/2/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class AccountsPreferenceViewController: NSViewController {
    
    let dataSource = AccountsPreferenceDataSource()

    @IBOutlet var tableView: BaseTableView!
    @IBOutlet var addAccountButton: NSButton!
    @IBOutlet var removeAccountButton: NSButton!
    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var bottomBarContainerView: BaseView!
    @IBOutlet weak var bottomBarTopSeparatorView: BaseSeparatorView!
    @IBOutlet weak var clipView: BaseClipView!
    
    deinit {
        QAccountStore.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.disableThemeObserver = true
        tableView.backgroundColor = NSColor.whiteColor()
        
        clipView.disableThemeObserver = true
        clipView.backgroundColor = NSColor.whiteColor()
        
        bottomBarContainerView.disableThemeObserver = true
        bottomBarContainerView.backgroundColor = NSColor.whiteColor()
        
        bottomBarTopSeparatorView.disableThemeObserver = true
        bottomBarTopSeparatorView.backgroundColor = LightModeColor.sharedInstance.separatorColor()
        
        removeAccountButton.enabled = false
        
        QAccountStore.addObserver(self)
        tableView.registerAdapter(AccountsPreferenceTableViewAdapter(), forClass: QAccount.self)
        dataSource.reloadData()
        tableView.reloadData()
        tableView.action = #selector(AccountsPreferenceViewController.didSelectRow)
        tableView.target = self;
        
        
        containerView.wantsLayer = true
        containerView.layer?.borderColor = NSColor(calibratedWhite: 164/255.0, alpha: 1).CGColor
        containerView.layer?.borderWidth = 1
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    @objc
    private func didSelectRow() {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 {
            removeAccountButton.enabled = true
        } else {
            removeAccountButton.enabled = false
        }
    }
    
    // MARK: Actions
    
    @IBAction func didClickRemoveButton(sender: AnyObject) {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else { return }
        
        let account = dataSource.itemAtIndex(selectedRow)
        NSAlert.showWarningMessage("Are you sure you want to remove \"\(account.username)\" account?", onConfirmation: { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.addAccountButton.enabled = false
            strongSelf.removeAccountButton.enabled = false
            
            QAccountStore.deleteAccount(account)
            
            strongSelf.addAccountButton.enabled = true
            strongSelf.removeAccountButton.enabled = true
        });
    }
    
    @IBAction func didClickAddButton(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(kSRShowAddAccountNotification, object: nil)
    }
}

extension AccountsPreferenceViewController: QStoreObserver {
    
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {
        dispatch_async(dispatch_get_main_queue()) {
        self.dataSource.reloadData()
        self.tableView.reloadData()
        }
    }
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.dataSource.reloadData()
            self.tableView.reloadData()
        }
    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.dataSource.reloadData()
            self.tableView.reloadData()
        }
    }

}

extension AccountsPreferenceViewController: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return dataSource.numberOfRows
    }
}

extension AccountsPreferenceViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil;
    }
    
    func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        if row > dataSource.numberOfRows - 1 {
            return nil
        }
        
        let item = dataSource.itemAtIndex(row)
        return self.tableView.adaptForItem(item, row: row, owner: self)
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let item = dataSource.itemAtIndex(row)
        return self.tableView.heightForItem(item, row: row)
    }
    

}
