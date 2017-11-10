//
//  GeneralPreferenceViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/10/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class GeneralPreferenceViewController: NSViewController {
    
    @IBOutlet weak var themePopupButton: NSPopUpButton!
    @IBOutlet weak var notificationPopupButton: NSPopUpButton!
    @IBOutlet weak var milestoneSearchPopupButton: NSPopUpButton!
    @IBOutlet weak var repositorySearchPopupButton: NSPopUpButton!
    @IBOutlet weak var milestoneIssueCreationButton: NSPopUpButton!
    
    @IBOutlet weak var closeIssuePopupButton: NSPopUpButton!
    @IBOutlet weak var closeIssueWarningContainerView: NSView!
    
    @IBOutlet weak var layoutPopupButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.themePopupButton.selectItemWithTitle(NSUserDefaults.themeMode() == .Dark ? "Dark mode" : "Light mode")
        self.notificationPopupButton.selectItemWithTitle(NSUserDefaults.notificationPreference().rawValue)
        self.milestoneSearchPopupButton.selectItemWithTitle(NSUserDefaults.milestoneSearchPreference().stringValue())
        self.repositorySearchPopupButton.selectItemWithTitle(NSUserDefaults.repositorySearchPreference().stringValue())
        self.milestoneIssueCreationButton.selectItemWithTitle(NSUserDefaults.milestoneIssueCreationPreference().stringValue())
        self.closeIssuePopupButton.selectItemWithTitle(NSUserDefaults.closeIssueWarningPreference().stringValue())
        self.layoutPopupButton.selectItemWithTitle(NSUserDefaults.layoutModePreference().stringValue())
    }
    
    @IBAction func didClickLayoutButton(sender: AnyObject) {
        if let rawValue = self.layoutPopupButton.selectedItem?.title, value = LayoutPreference.preferenceFromString(rawValue) {
            NSUserDefaults.setLayoutModePreference(value)
        }
    }
    
    @IBAction func didClickCloseIssueWarningButton(sender: AnyObject) {
        if let rawValue = self.closeIssuePopupButton.selectedItem?.title, value = CloseIssueWarningPreference.preferenceFromString(rawValue) {
            NSUserDefaults.setCloseIssueWarningPreference(value)
        }
    }
    
    @IBAction func didClickMilestoneIssueCreationButton(sender: AnyObject) {
        if let rawValue = self.milestoneIssueCreationButton.selectedItem?.title, value = MilestoneIssueCreationPreference.preferenceFromString(rawValue) {
            NSUserDefaults.setMilestoneIssueCreationPreference(value)
        }
    }
    
    @IBAction func didClickRepositorySearchButton(sender: AnyObject) {
        if let rawValue = self.repositorySearchPopupButton.selectedItem?.title, value = RepositorySearchPreference.preferenceFromString(rawValue) {
            NSUserDefaults.setRepositorySearchPreference(value)
        }
    }
    
    @IBAction func didClickMilestonSearchButton(sender: AnyObject) {
        if let rawValue = self.milestoneSearchPopupButton.selectedItem?.title, value = MilestoneSearchPreference.preferenceFromString(rawValue) {
            NSUserDefaults.setMilestoneSearchPreference(value)
        }
    }
    
    @IBAction func didClickNotificationButton(sender: AnyObject) {
        if let rawValue = self.notificationPopupButton.selectedItem?.title, value = NotificationPreference(rawValue: rawValue) {
            NSUserDefaults.setNotificationPreference(value)
        }
    }
    
    @IBAction func didClickThemeButton(sender: AnyObject) {
        if let selectedTitle =  self.themePopupButton.selectedItem?.title {
            if selectedTitle == "Dark mode" {
                NSUserDefaults.setThemeMode(.Dark)
            } else {
                NSUserDefaults.setThemeMode(.Light)
            }
        }
    }
}
