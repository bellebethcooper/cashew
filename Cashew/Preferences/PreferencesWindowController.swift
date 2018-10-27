//
//  PreferencesWindowController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/2/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRPreferencesTab)
enum PreferencesTab: UInt {
    case general = 1
    case accounts = 2
    case issueExtensions = 3
}

@objc(SRPreferencesWindowController)
class PreferencesWindowController: NSWindowController {
    
    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet weak var accountsToolbarItem: NSToolbarItem!
    @IBOutlet weak var generalToolbarItem: NSToolbarItem!
    @IBOutlet weak var issueExtensionToolbarItem: NSToolbarItem!
    
    var onWindowLoadPreferenceTab: PreferencesTab = .general
    
    fileprivate(set) var selectedTab: PreferencesTab = .accounts {
        didSet {
            DispatchOnMainQueue {
                switch self.selectedTab {
                case .general:
                    self.toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "GeneralToolbarItem")
                    self.showGeneralTab()
                    break
                case .accounts:
                    self.toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "AccountsToolbarItem")
                    self.showAccountsTab()
                    break
                case .issueExtensions:
                    self.toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "IssueExtensionsToolbarItem")
                    self.showIssueExtensionsTab()
                    break
                }
                
                
            }
        }
    }
    
    fileprivate var accountsViewController: AccountsPreferenceViewController?
    fileprivate var generalViewController: GeneralPreferenceViewController?
    fileprivate var issueExtensionsViewController: IssueExtensionsPreferenceViewController?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        selectedTab = onWindowLoadPreferenceTab
    }
    
    @IBAction func didClickIssueExtensionToolbarItem(_ sender: AnyObject) {
        selectedTab = .issueExtensions
    }
    @IBAction func didClickGeneralToolbarItem(_ sender: AnyObject) {
        selectedTab = .general
    }
    
    @IBAction func didClickAccountsToolbarItem(_ sender: AnyObject) {
        selectedTab = .accounts
    }
    
    // MARK: Tabs
    
    fileprivate func removeGeneralViewController() {
        self.generalViewController?.view.removeFromSuperview()
        self.generalViewController = nil;
    }
    
    fileprivate func removeIssueExtensionViewController() {
        self.issueExtensionsViewController?.view.removeFromSuperview()
        self.issueExtensionsViewController = nil;
    }
    
    fileprivate func removeAccountsViewController() {
        self.accountsViewController?.view.removeFromSuperview()
        self.accountsViewController = nil;
    }
    
    fileprivate func showIssueExtensionsTab() {
        guard let contentView = window?.contentView else { return }
        
        let issueExtensionsViewController = IssueExtensionsPreferenceViewController(nibName: NSNib.Name(rawValue: "IssueExtensionsPreferenceViewController"), bundle: nil)
        self.issueExtensionsViewController = issueExtensionsViewController
        
        contentView.addSubview(issueExtensionsViewController.view)
        issueExtensionsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        issueExtensionsViewController.view.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant:  10).isActive = true
        issueExtensionsViewController.view.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant:  -10).isActive = true
        issueExtensionsViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor, constant:  10).isActive = true
        issueExtensionsViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant:  -10).isActive = true
        
        removeGeneralViewController()
        removeAccountsViewController()
    }
    
    fileprivate func showGeneralTab() {
        guard let contentView = window?.contentView else { return }
        
        let generalViewController = GeneralPreferenceViewController(nibName: NSNib.Name(rawValue: "GeneralPreferenceViewController"), bundle: nil)
        self.generalViewController = generalViewController
        
        contentView.addSubview(generalViewController.view)
        generalViewController.view.translatesAutoresizingMaskIntoConstraints = false
        generalViewController.view.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant:  10).isActive = true
        generalViewController.view.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant:  -10).isActive = true
        generalViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor, constant:  10).isActive = true
        generalViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant:  -10).isActive = true
        removeIssueExtensionViewController()
        removeAccountsViewController()
    }
    
    fileprivate func showAccountsTab() {
        guard let contentView = window?.contentView else { return }
        
        let accountsViewController = AccountsPreferenceViewController(nibName: NSNib.Name(rawValue: "AccountsPreferenceViewController"), bundle: nil)
        self.accountsViewController = accountsViewController
        
        contentView.addSubview(accountsViewController.view)
        accountsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        accountsViewController.view.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant:  10).isActive = true
        accountsViewController.view.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant:  -10).isActive = true
        accountsViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor, constant:  10).isActive = true
        accountsViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant:  -10).isActive = true
        removeGeneralViewController()
        removeIssueExtensionViewController()
    }
}
