//
//  MilestoneSearchResultTableRowView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/1/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class MilestoneSearchResultTableRowView: BaseTableRowView {
    
    var milestone: QMilestone {
        didSet {
            didSetMilestone()
        }
    }
    
    required init(milestone: QMilestone) {
        self.milestone = milestone
        super.init()
        
        selectionType = .checkbox
        
        didSetMilestone()
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else{ return }
            let selected = strongSelf.isSelected
            strongSelf.isSelected = selected
        }
    }
    
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    override var isSelected: Bool {
        didSet {
            needsLayout = true
            layoutSubtreeIfNeeded()
            if UserDefaults.themeMode() == .dark {
                backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                backgroundColor = CashewColor.backgroundColor()
            }
            
            contentView.backgroundColor = backgroundColor
            titleLabel.textColor = CashewColor.foregroundColor()
            
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    // MARK: Setup
    fileprivate func didSetMilestone() {
        titleLabel.stringValue = milestone.title
        
        var subtitle = [String]()
        if milestone.dueOn != nil {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            let dateString = formatter.string(from: milestone.dueOn)
            subtitle.append("Due by \(dateString)")
        }
        
        if milestone.desc != nil {
            let desc = (milestone.desc.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\r", with: " ") as NSString).trimmedString()
            if desc.length > 0 {
                subtitle.append(desc as String)
            }
        }
        
        if subtitle.count > 0 {
            subtitleLabel.stringValue = subtitle.joined(separator: " • ")
        } else {
            subtitleLabel.stringValue = ""
        }
    }
    
}
