//
//  SuggestionValueTableViewAdaptor.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/17/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class SuggestionValueTableRowView: BaseTableRowView {
    
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
                titleLabel.textColor = CashewColor.foregroundColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SuggestionValueTableViewAdaptor: NSObject, BaseTableViewAdapter {
    
    private static let foregroundFont: NSFont = NSFont.systemFontOfSize(13, weight: NSFontWeightRegular)
    
    func height(item: AnyObject, index: Int) -> CGFloat {
        return 22
    }
    
    func adapt(view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView? {
        
        guard let value = item as? SearchSuggestionResultItemValue else { return nil }
        
        let rowView: SuggestionValueTableRowView
        if let view = view as? SuggestionValueTableRowView {
            rowView = view
        } else {
            rowView = SuggestionValueTableRowView()
            rowView.subtitleLabel.stringValue = ""
            rowView.selectionType = .Highlight
            rowView.checked = false
            rowView.separatorView.hidden = true
            rowView.titleLabel.font = SuggestionValueTableViewAdaptor.foregroundFont
        }
        
        rowView.titleLabel.stringValue = value.title
        
        
        return rowView
    }
}
