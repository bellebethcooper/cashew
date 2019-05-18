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
    case standard = 0
    case noAssigneeImage = 1
    case classic = 2
    
    func stringValue() -> String {
        switch self {
        case .standard:
            return "Standard"
        case .noAssigneeImage:
            return "Hide Assignee Photo"
        case .classic:
            return "Classic"
        }
    }
    
    static func preferenceFromString(_ stringValue: String) -> LayoutPreference? {
        if "Standard" == stringValue {
            return .standard
        } else if "Hide Assignee Photo" == stringValue {
            return .noAssigneeImage
        } else if "Classic" == stringValue {
            return .classic
        }
        return nil
    }
}

enum CloseIssueWarningPreference: NSInteger {
    case enabled = 0
    case disabled = 1
    
    func stringValue() -> String {
        switch self {
        case .enabled:
            return "Enabled"
        case .disabled:
            return "Disabled"
        }
    }
    
    static func preferenceFromString(_ stringValue: String) -> CloseIssueWarningPreference? {
        if "Disabled" == stringValue {
            return .disabled
        } else if "Enabled" == stringValue {
            return .enabled
        }
        return nil
    }
}


enum MilestoneSearchPreference: NSInteger {
    case all = 0
    case open = 1
    
    func stringValue() -> String {
        switch self {
        case .all:
            return "Both open & closed"
        case .open:
            return "Only open"
        }
    }
    
    static func preferenceFromString(_ stringValue: String) -> MilestoneSearchPreference? {
        if "Both open & closed" == stringValue {
            return .all
        } else if "Only open" == stringValue {
            return .open
        }
        return nil
    }
}

enum MilestoneIssueCreationPreference: NSInteger {
    case all = 0
    case open = 1
    
    func stringValue() -> String {
        switch self {
        case .all:
            return "Both open & closed"
        case .open:
            return "Only open"
        }
    }
    
    static func preferenceFromString(_ stringValue: String) -> MilestoneIssueCreationPreference? {
        if "Both open & closed" == stringValue {
            return .all
        } else if "Only open" == stringValue {
            return .open
        }
        return nil
    }
}


enum RepositorySearchPreference: NSInteger {
    case all = 0
    case open = 1
    
    func stringValue() -> String {
        switch self {
        case .all:
            return "Both open & closed"
        case .open:
            return "Only open"
        }
    }
    
    static func preferenceFromString(_ stringValue: String) -> RepositorySearchPreference? {
        if "Both open & closed" == stringValue {
            return .all
        } else if "Only open" == stringValue {
            return .open
        }
        return nil
    }
}

extension UserDefaults {
    
    struct PreferenceConstant {
        static let notification = "notificationPreference"
        static let closeIssueWarning = "closeIssueWarningPreference"
        static let milestoneSearch = "milestoneSearchPreference"
        static let milestoneIssueCreation = "milestoneIssueCreationPreference"
        static let repositorySearch = "repositorySearchPreference"
        static let layoutMode = "layoutModePreference"
    }

    @objc class func layoutModePreference() -> LayoutPreference {
        let value = UserDefaults.standard.integer(forKey: UserDefaults.PreferenceConstant.layoutMode)
        return LayoutPreference(rawValue: value) ?? LayoutPreference.standard
    }
    
    class func setLayoutModePreference(_ value: LayoutPreference) {
        UserDefaults.standard.set(value.rawValue, forKey: UserDefaults.PreferenceConstant.layoutMode)
        UserDefaults.standard.synchronize()
    }
    
    class func closeIssueWarningPreference() -> CloseIssueWarningPreference {
        let value = UserDefaults.standard.integer(forKey: UserDefaults.PreferenceConstant.closeIssueWarning)
        return CloseIssueWarningPreference(rawValue: value) ?? CloseIssueWarningPreference.enabled
    }
    
    class func setCloseIssueWarningPreference(_ value: CloseIssueWarningPreference) {
        UserDefaults.standard.set(value.rawValue, forKey: UserDefaults.PreferenceConstant.closeIssueWarning)
        UserDefaults.standard.synchronize()
    }
    
    
    class func notificationPreference() -> NotificationPreference {
        guard let value = UserDefaults.standard.string(forKey: UserDefaults.PreferenceConstant.notification) else { return NotificationPreference.Enabled }
        return NotificationPreference(rawValue: value) ?? NotificationPreference.Enabled
    }
    
    class func setNotificationPreference(_ value: NotificationPreference) {
        UserDefaults.standard.set(value.rawValue, forKey: UserDefaults.PreferenceConstant.notification)
        UserDefaults.standard.synchronize()
    }
    
    class func milestoneSearchPreference() -> MilestoneSearchPreference {
        let value = UserDefaults.standard.integer(forKey: UserDefaults.PreferenceConstant.milestoneSearch)
        return MilestoneSearchPreference(rawValue: value) ?? MilestoneSearchPreference.all
    }
    
    class func setMilestoneSearchPreference(_ value: MilestoneSearchPreference) {
        UserDefaults.standard.set(value.rawValue, forKey: UserDefaults.PreferenceConstant.milestoneSearch)
        UserDefaults.standard.synchronize()
    }
    
    class func repositorySearchPreference() -> RepositorySearchPreference {
        let value = UserDefaults.standard.integer(forKey: UserDefaults.PreferenceConstant.repositorySearch)
        return RepositorySearchPreference(rawValue: value) ?? RepositorySearchPreference.all
    }
    
    class func setRepositorySearchPreference(_ value: RepositorySearchPreference) {
        UserDefaults.standard.set(value.rawValue, forKey: UserDefaults.PreferenceConstant.repositorySearch)
        UserDefaults.standard.synchronize()
    }
    
    class func milestoneIssueCreationPreference() -> MilestoneIssueCreationPreference {
        let value = UserDefaults.standard.integer(forKey: UserDefaults.PreferenceConstant.milestoneIssueCreation)
        return MilestoneIssueCreationPreference(rawValue: value) ?? MilestoneIssueCreationPreference.all
    }
    
    class func setMilestoneIssueCreationPreference(_ value: MilestoneIssueCreationPreference) {
        UserDefaults.standard.set(value.rawValue, forKey: UserDefaults.PreferenceConstant.milestoneIssueCreation)
        UserDefaults.standard.synchronize()
    }
    
}

extension UserDefaults {
    
    @objc
    class func shouldShowBothOpenAndClosedInRepositorySearch() -> Bool {
        return UserDefaults.repositorySearchPreference() == .all
    }

    @objc
    class func shouldShowBothOpenAndClosedInMilestoneSearch() -> Bool {
        return UserDefaults.milestoneSearchPreference() == .all
    }
    
    @objc
    class func shouldShowOnlyOpenInRepositorySearch() -> Bool {
        return UserDefaults.repositorySearchPreference() == .open
    }

    @objc
    class func shouldShowOnlyOpenInMilestoneSearch() -> Bool {
        return UserDefaults.milestoneSearchPreference() == .open
    }
    
    @objc
    class func shouldShowOnlyOpenMilestonesInIssueCreation() -> Bool {
        return UserDefaults.milestoneIssueCreationPreference() == .open
    }

    @objc
    class func shouldShowIssueCloseWarning() -> Bool {
        return UserDefaults.closeIssueWarningPreference() == .enabled
    }
    
    @objc
    class func layoutModeKeyPath() -> String {
        return UserDefaults.PreferenceConstant.layoutMode
    }
}

