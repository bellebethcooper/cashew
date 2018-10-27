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
        QAccountStore.remove(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.disableThemeObserver = true
        tableView.backgroundColor = NSColor.white
        
        clipView.disableThemeObserver = true
        clipView.backgroundColor = NSColor.white
        
        bottomBarContainerView.disableThemeObserver = true
        bottomBarContainerView.backgroundColor = NSColor.white
        
        bottomBarTopSeparatorView.disableThemeObserver = true
        bottomBarTopSeparatorView.backgroundColor = LightModeColor.sharedInstance.separatorColor()
        
        removeAccountButton.isEnabled = false
        
        QAccountStore.add(self)
        tableView.registerAdapter(AccountsPreferenceTableViewAdapter(), forClass: QAccount.self)
        dataSource.reloadData()
        tableView.reloadData()
        tableView.action = #selector(AccountsPreferenceViewController.didSelectRow)
        tableView.target = self;
        
        
        containerView.wantsLayer = true
        containerView.layer?.borderColor = NSColor(calibratedWhite: 164/255.0, alpha: 1).cgColor
        containerView.layer?.borderWidth = 1
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    @objc
    fileprivate func didSelectRow() {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 {
            removeAccountButton.isEnabled = true
        } else {
            removeAccountButton.isEnabled = false
        }
    }
    
    // MARK: Actions
    
    @IBAction func didClickRemoveButton(_ sender: AnyObject) {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else { return }
        
        let account = dataSource.itemAtIndex(selectedRow)
        NSAlert.showWarningMessage("Are you sure you want to remove \"\(account.username)\" account?", onConfirmation: { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.addAccountButton.isEnabled = false
            strongSelf.removeAccountButton.isEnabled = false
            
            QAccountStore.deleteAccount(account)
            
            strongSelf.addAccountButton.isEnabled = true
            strongSelf.removeAccountButton.isEnabled = true
        });
    }
    
    @IBAction func didClickAddButton(_ sender: AnyObject) {
        NotificationCenter.default.post(name: NSNotification.Name.srShowAddAccount, object: nil)
    }
}

extension AccountsPreferenceViewController: QStoreObserver {
    
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {
        DispatchQueue.main.async {
        self.dataSource.reloadData()
        self.tableView.reloadData()
        }
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {
        DispatchQueue.main.async {
            self.dataSource.reloadData()
            self.tableView.reloadData()
        }
    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        DispatchQueue.main.async {
            self.dataSource.reloadData()
            self.tableView.reloadData()
        }
    }

}

extension AccountsPreferenceViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataSource.numberOfRows
    }
}

extension AccountsPreferenceViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil;
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        if row > dataSource.numberOfRows - 1 {
            return nil
        }
        
        let item = dataSource.itemAtIndex(row)
        return self.tableView.adaptForItem(item, row: row, owner: self)
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let item = dataSource.itemAtIndex(row)
        return self.tableView.heightForItem(item, row: row)
    }
    

}
