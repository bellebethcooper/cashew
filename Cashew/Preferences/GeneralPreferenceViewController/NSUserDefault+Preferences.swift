//
//  NSUserDefault+Preferences.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/22/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

enum NotificationPreference: String {
    case Enabled = "Enabled"
    case Disabled = "Disabled"
}

@objc(SRLayoutPreference)
enum LayoutPreference: NSInteger {
    case Standard = 0
    case NoAssigneeImage = 1
    case Classic = 2
    
    func stringValue() -> String {
        switch self {
        case .Standard:
            return "Standard"
        case .NoAssigneeImage:
            return "Hide Assignee Photo"
        case .Classic:
            return "Classic"
        }
    }
    
    static func preferenceFromString(stringValue: String) -> LayoutPreference? {
        if "Standard" == stringValue {
            return .Standard
        } else if "Hide Assignee Photo" == stringValue {
            return .NoAssigneeImage
        } else if "Classic" == stringValue {
            return .Classic
        }
        return nil
    }
}

enum CloseIssueWarningPreference: NSInteger {
    case Enabled = 0
    case Disabled = 1
    
    func stringValue() -> String {
        switch self {
        case .Enabled:
            return "Enabled"
        case .Disabled:
            return "Disabled"
        }
    }
    
    static func preferenceFromString(stringValue: String) -> CloseIssueWarningPreference? {
        if "Disabled" == stringValue {
            return .Disabled
        } else if "Enabled" == stringValue {
            return .Enabled
        }
        return nil
    }
}


enum MilestoneSearchPreference: NSInteger {
    case All = 0
    case Open = 1
    
    func stringValue() -> String {
        switch self {
        case .All:
            return "Both open & closed"
        case Open:
            return "Only open"
        }
    }
    
    static func preferenceFromString(stringValue: String) -> MilestoneSearchPreference? {
        if "Both open & closed" == stringValue {
            return .All
        } else if "Only open" == stringValue {
            return .Open
        }
        return nil
    }
}

enum MilestoneIssueCreationPreference: NSInteger {
    case All = 0
    case Open = 1
    
    func stringValue() -> String {
        switch self {
        case .All:
            return "Both open & closed"
        case Open:
            return "Only open"
        }
    }
    
    static func preferenceFromString(stringValue: String) -> MilestoneIssueCreationPreference? {
        if "Both open & closed" == stringValue {
            return .All
        } else if "Only open" == stringValue {
            return .Open
        }
        return nil
    }
}


enum RepositorySearchPreference: NSInteger {
    case All = 0
    case Open = 1
    
    func stringValue() -> String {
        switch self {
        case .All:
            return "Both open & closed"
        case Open:
            return "Only open"
        }
    }
    
    static func preferenceFromString(stringValue: String) -> RepositorySearchPreference? {
        if "Both open & closed" == stringValue {
            return .All
        } else if "Only open" == stringValue {
            return .Open
        }
        return nil
    }
}

extension NSUserDefaults {
    
    struct PreferenceConstant {
        static let notification = "notificationPreference"
        static let closeIssueWarning = "closeIssueWarningPreference"
        static let milestoneSearch = "milestoneSearchPreference"
        static let milestoneIssueCreation = "milestoneIssueCreationPreference"
        static let repositorySearch = "repositorySearchPreference"
        static let layoutMode = "layoutModePreference"
    }

    class func layoutModePreference() -> LayoutPreference {
        let value = NSUserDefaults.standardUserDefaults().integerForKey(NSUserDefaults.PreferenceConstant.layoutMode)
        return LayoutPreference(rawValue: value) ?? LayoutPreference.Standard
    }
    
    class func setLayoutModePreference(value: LayoutPreference) {
        NSUserDefaults.standardUserDefaults().setInteger(value.rawValue, forKey: NSUserDefaults.PreferenceConstant.layoutMode)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func closeIssueWarningPreference() -> CloseIssueWarningPreference {
        let value = NSUserDefaults.standardUserDefaults().integerForKey(NSUserDefaults.PreferenceConstant.closeIssueWarning)
        return CloseIssueWarningPreference(rawValue: value) ?? CloseIssueWarningPreference.Enabled
    }
    
    class func setCloseIssueWarningPreference(value: CloseIssueWarningPreference) {
        NSUserDefaults.standardUserDefaults().setInteger(value.rawValue, forKey: NSUserDefaults.PreferenceConstant.closeIssueWarning)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    
    class func notificationPreference() -> NotificationPreference {
        guard let value = NSUserDefaults.standardUserDefaults().stringForKey(NSUserDefaults.PreferenceConstant.notification) else { return NotificationPreference.Enabled }
        return NotificationPreference(rawValue: value) ?? NotificationPreference.Enabled
    }
    
    class func setNotificationPreference(value: NotificationPreference) {
        NSUserDefaults.standardUserDefaults().setObject(value.rawValue, forKey: NSUserDefaults.PreferenceConstant.notification)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func milestoneSearchPreference() -> MilestoneSearchPreference {
        let value = NSUserDefaults.standardUserDefaults().integerForKey(NSUserDefaults.PreferenceConstant.milestoneSearch)
        return MilestoneSearchPreference(rawValue: value) ?? MilestoneSearchPreference.All
    }
    
    class func setMilestoneSearchPreference(value: MilestoneSearchPreference) {
        NSUserDefaults.standardUserDefaults().setInteger(value.rawValue, forKey: NSUserDefaults.PreferenceConstant.milestoneSearch)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func repositorySearchPreference() -> RepositorySearchPreference {
        let value = NSUserDefaults.standardUserDefaults().integerForKey(NSUserDefaults.PreferenceConstant.repositorySearch)
        return RepositorySearchPreference(rawValue: value) ?? RepositorySearchPreference.All
    }
    
    class func setRepositorySearchPreference(value: RepositorySearchPreference) {
        NSUserDefaults.standardUserDefaults().setInteger(value.rawValue, forKey: NSUserDefaults.PreferenceConstant.repositorySearch)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    class func milestoneIssueCreationPreference() -> MilestoneIssueCreationPreference {
        let value = NSUserDefaults.standardUserDefaults().integerForKey(NSUserDefaults.PreferenceConstant.milestoneIssueCreation)
        return MilestoneIssueCreationPreference(rawValue: value) ?? MilestoneIssueCreationPreference.All
    }
    
    class func setMilestoneIssueCreationPreference(value: MilestoneIssueCreationPreference) {
        NSUserDefaults.standardUserDefaults().setInteger(value.rawValue, forKey: NSUserDefaults.PreferenceConstant.milestoneIssueCreation)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
}

extension NSUserDefaults {
    
    class func shouldShowBothOpenAndClosedInRepositorySearch() -> Bool {
        return NSUserDefaults.repositorySearchPreference() == .All
    }

    class func shouldShowBothOpenAndClosedInMilestoneSearch() -> Bool {
        return NSUserDefaults.milestoneSearchPreference() == .All
    }
    
    class func shouldShowOnlyOpenInRepositorySearch() -> Bool {
        return NSUserDefaults.repositorySearchPreference() == .Open
    }
    
    class func shouldShowOnlyOpenInMilestoneSearch() -> Bool {
        return NSUserDefaults.milestoneSearchPreference() == .Open
    }
    
    class func shouldShowOnlyOpenMilestonesInIssueCreation() -> Bool {
        return NSUserDefaults.milestoneIssueCreationPreference() == .Open
    }
    
    class func shouldShowIssueCloseWarning() -> Bool {
        return NSUserDefaults.closeIssueWarningPreference() == .Enabled
    }
    
    class func layoutModeKeyPath() -> String {
        return NSUserDefaults.PreferenceConstant.layoutMode
    }
}

