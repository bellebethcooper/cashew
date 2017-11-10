//
//  SuggestionHeaderTableViewAdaptor.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/17/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa


class SuggestionHeaderTableRowView: BaseTableRowView {
    
    private var unselectedTitleColor: NSColor = NSColor.blackColor()
    
    override var titleLabelColor: NSColor {
        return unselectedTitleColor
    }
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    required init() {
        super.init()
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else{ return }
            let selected = strongSelf.selected
            strongSelf.selected = selected
        }
    }
    
    override var selected: Bool {
        didSet {
            
            accessoryView?.hidden = true
            if selected {
                contentView.backgroundColor = BaseTableRowView.selectionColor
                titleLabel.textColor = NSColor.whiteColor()
            } else {
                if NSUserDefaults.themeMode() == .Dark {
                    backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
                } else {
                    backgroundColor = CashewColor.backgroundColor()
                }
                contentView.backgroundColor = backgroundColor
                titleLabel.textColor = CashewColor.foregroundSecondaryColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SuggestionHeaderTableViewAdaptor: NSObject, BaseTableViewAdapter {
    
    private static let foregroundColor: NSColor = NSColor(calibratedWhite: 130/255.0, alpha: 0.85)
    private static let foregroundFont: NSFont = NSFont.systemFontOfSize(10, weight: NSFontWeightSemibold)
    
    func height(item: AnyObject, index: Int) -> CGFloat {
        return 16
    }
    
    func adapt(view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView? {
        guard let value = item as? SearchSuggestionResultItemHeader else { return nil }
        
        let rowView: SuggestionHeaderTableRowView
        if let view = view as? SuggestionHeaderTableRowView {
            rowView = view
        } else {
            rowView = SuggestionHeaderTableRowView()
            rowView.titleLabel.font = SuggestionHeaderTableViewAdaptor.foregroundFont
            rowView.subtitleLabel.stringValue = ""
            rowView.checked = false
            rowView.separatorView.hidden = true
        }
        
        rowView.titleLabel.stringValue = value.title
        
        return rowView
    }
}
