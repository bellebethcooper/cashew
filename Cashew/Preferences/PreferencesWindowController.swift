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
    case General = 1
    case Accounts = 2
    case IssueExtensions = 3
}

@objc(SRPreferencesWindowController)
class PreferencesWindowController: NSWindowController {
    
    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet weak var accountsToolbarItem: NSToolbarItem!
    @IBOutlet weak var generalToolbarItem: NSToolbarItem!
    @IBOutlet weak var issueExtensionToolbarItem: NSToolbarItem!
    
    var onWindowLoadPreferenceTab: PreferencesTab = .General
    
    private(set) var selectedTab: PreferencesTab = .Accounts {
        didSet {
            DispatchOnMainQueue {
                switch self.selectedTab {
                case .General:
                    self.toolbar.selectedItemIdentifier = "GeneralToolbarItem"
                    self.showGeneralTab()
                    break
                case .Accounts:
                    self.toolbar.selectedItemIdentifier = "AccountsToolbarItem"
                    self.showAccountsTab()
                    break
                case .IssueExtensions:
                    self.toolbar.selectedItemIdentifier = "IssueExtensionsToolbarItem"
                    self.showIssueExtensionsTab()
                    break
                }
                
                
            }
        }
    }
    
    private var accountsViewController: AccountsPreferenceViewController?
    private var generalViewController: GeneralPreferenceViewController?
    private var issueExtensionsViewController: IssueExtensionsPreferenceViewController?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        selectedTab = onWindowLoadPreferenceTab
    }
    
    @IBAction func didClickIssueExtensionToolbarItem(sender: AnyObject) {
        selectedTab = .IssueExtensions
    }
    @IBAction func didClickGeneralToolbarItem(sender: AnyObject) {
        selectedTab = .General
    }
    
    @IBAction func didClickAccountsToolbarItem(sender: AnyObject) {
        selectedTab = .Accounts
    }
    
    // MARK: Tabs
    
    private func removeGeneralViewController() {
        self.generalViewController?.view.removeFromSuperview()
        self.generalViewController = nil;
    }
    
    private func removeIssueExtensionViewController() {
        self.issueExtensionsViewController?.view.removeFromSuperview()
        self.issueExtensionsViewController = nil;
    }
    
    private func removeAccountsViewController() {
        self.accountsViewController?.view.removeFromSuperview()
        self.accountsViewController = nil;
    }
    
    private func showIssueExtensionsTab() {
        guard let contentView = window?.contentView else { return }
        
        if let issueExtensionsViewController = IssueExtensionsPreferenceViewController(nibName: "IssueExtensionsPreferenceViewController", bundle: nil) {
            self.issueExtensionsViewController = issueExtensionsViewController
            
            contentView.addSubview(issueExtensionsViewController.view)
            issueExtensionsViewController.view.translatesAutoresizingMaskIntoConstraints = false
            issueExtensionsViewController.view.leftAnchor.constraintEqualToAnchor(contentView.leftAnchor, constant:  10).active = true
            issueExtensionsViewController.view.rightAnchor.constraintEqualToAnchor(contentView.rightAnchor, constant:  -10).active = true
            issueExtensionsViewController.view.topAnchor.constraintEqualToAnchor(contentView.topAnchor, constant:  10).active = true
            issueExtensionsViewController.view.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor, constant:  -10).active = true
        }
        
        removeGeneralViewController()
        removeAccountsViewController()
    }
    
    private func showGeneralTab() {
        guard let contentView = window?.contentView else { return }
        
        if let generalViewController = GeneralPreferenceViewController(nibName: "GeneralPreferenceViewController", bundle: nil) {
            self.generalViewController = generalViewController
            
            contentView.addSubview(generalViewController.view)
            generalViewController.view.translatesAutoresizingMaskIntoConstraints = false
            generalViewController.view.leftAnchor.constraintEqualToAnchor(contentView.leftAnchor, constant:  10).active = true
            generalViewController.view.rightAnchor.constraintEqualToAnchor(contentView.rightAnchor, constant:  -10).active = true
            generalViewController.view.topAnchor.constraintEqualToAnchor(contentView.topAnchor, constant:  10).active = true
            generalViewController.view.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor, constant:  -10).active = true
        }
        removeIssueExtensionViewController()
        removeAccountsViewController()
    }
    
    private func showAccountsTab() {
        guard let contentView = window?.contentView else { return }
        
        if let accountsViewController = AccountsPreferenceViewController(nibName: "AccountsPreferenceViewController", bundle: nil) {
            self.accountsViewController = accountsViewController
            
            contentView.addSubview(accountsViewController.view)
            accountsViewController.view.translatesAutoresizingMaskIntoConstraints = false
            accountsViewController.view.leftAnchor.constraintEqualToAnchor(contentView.leftAnchor, constant:  10).active = true
            accountsViewController.view.rightAnchor.constraintEqualToAnchor(contentView.rightAnchor, constant:  -10).active = true
            accountsViewController.view.topAnchor.constraintEqualToAnchor(contentView.topAnchor, constant:  10).active = true
            accountsViewController.view.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor, constant:  -10).active = true
        }
        removeGeneralViewController()
        removeIssueExtensionViewController()
    }
}
