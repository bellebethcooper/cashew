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
        
        selectionType = .Checkbox
        
        didSetMilestone()
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else{ return }
            let selected = strongSelf.selected
            strongSelf.selected = selected
        }
    }
    
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    override var selected: Bool {
        didSet {
            needsLayout = true
            layoutSubtreeIfNeeded()
            if NSUserDefaults.themeMode() == .Dark {
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
    private func didSetMilestone() {
        titleLabel.stringValue = milestone.title
        
        var subtitle = [String]()
        if milestone.dueOn != nil {
            let formatter = NSDateFormatter()
            formatter.dateStyle = .LongStyle
            formatter.timeStyle = .NoStyle
            let dateString = formatter.stringFromDate(milestone.dueOn)
            subtitle.append("Due by \(dateString)")
        }
        
        if milestone.desc != nil {
            let desc = (milestone.desc.stringByReplacingOccurrencesOfString("\n", withString: " ").stringByReplacingOccurrencesOfString("\r", withString: " ") as NSString).trimmedString()
            if desc.length > 0 {
                subtitle.append(desc as String)
            }
        }
        
        if subtitle.count > 0 {
            subtitleLabel.stringValue = subtitle.joinWithSeparator(" • ")
        } else {
            subtitleLabel.stringValue = ""
        }
    }
    
}
