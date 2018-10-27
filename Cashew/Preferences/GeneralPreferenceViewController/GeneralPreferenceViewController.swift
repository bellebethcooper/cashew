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
        
        self.themePopupButton.selectItem(withTitle: UserDefaults.themeMode() == .dark ? "Dark mode" : "Light mode")
        self.notificationPopupButton.selectItem(withTitle: UserDefaults.notificationPreference().rawValue)
        self.milestoneSearchPopupButton.selectItem(withTitle: UserDefaults.milestoneSearchPreference().stringValue())
        self.repositorySearchPopupButton.selectItem(withTitle: UserDefaults.repositorySearchPreference().stringValue())
        self.milestoneIssueCreationButton.selectItem(withTitle: UserDefaults.milestoneIssueCreationPreference().stringValue())
        self.closeIssuePopupButton.selectItem(withTitle: UserDefaults.closeIssueWarningPreference().stringValue())
        self.layoutPopupButton.selectItem(withTitle: UserDefaults.layoutModePreference().stringValue())
    }
    
    @IBAction func didClickLayoutButton(_ sender: AnyObject) {
        if let rawValue = self.layoutPopupButton.selectedItem?.title, let value = LayoutPreference.preferenceFromString(rawValue) {
            UserDefaults.setLayoutModePreference(value)
        }
    }
    
    @IBAction func didClickCloseIssueWarningButton(_ sender: AnyObject) {
        if let rawValue = self.closeIssuePopupButton.selectedItem?.title, let value = CloseIssueWarningPreference.preferenceFromString(rawValue) {
            UserDefaults.setCloseIssueWarningPreference(value)
        }
    }
    
    @IBAction func didClickMilestoneIssueCreationButton(_ sender: AnyObject) {
        if let rawValue = self.milestoneIssueCreationButton.selectedItem?.title, let value = MilestoneIssueCreationPreference.preferenceFromString(rawValue) {
            UserDefaults.setMilestoneIssueCreationPreference(value)
        }
    }
    
    @IBAction func didClickRepositorySearchButton(_ sender: AnyObject) {
        if let rawValue = self.repositorySearchPopupButton.selectedItem?.title, let value = RepositorySearchPreference.preferenceFromString(rawValue) {
            UserDefaults.setRepositorySearchPreference(value)
        }
    }
    
    @IBAction func didClickMilestonSearchButton(_ sender: AnyObject) {
        if let rawValue = self.milestoneSearchPopupButton.selectedItem?.title, let value = MilestoneSearchPreference.preferenceFromString(rawValue) {
            UserDefaults.setMilestoneSearchPreference(value)
        }
    }
    
    @IBAction func didClickNotificationButton(_ sender: AnyObject) {
        if let rawValue = self.notificationPopupButton.selectedItem?.title, let value = NotificationPreference(rawValue: rawValue) {
            UserDefaults.setNotificationPreference(value)
        }
    }
    
    @IBAction func didClickThemeButton(_ sender: AnyObject) {
        if let selectedTitle =  self.themePopupButton.selectedItem?.title {
            if selectedTitle == "Dark mode" {
                UserDefaults.setThemeMode(.dark)
            } else {
                UserDefaults.setThemeMode(.light)
            }
        }
    }
}
