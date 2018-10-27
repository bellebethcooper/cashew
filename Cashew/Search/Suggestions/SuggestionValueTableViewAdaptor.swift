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
            let selected = strongSelf.isSelected
            strongSelf.isSelected = selected
        }
    }
    
    override var isSelected: Bool {
        didSet {
            accessoryView?.isHidden = true
            if isSelected {
                contentView.backgroundColor = BaseTableRowView.selectionColor
                titleLabel.textColor = NSColor.white
            } else {
                if UserDefaults.themeMode() == .dark {
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
    
    fileprivate static let foregroundFont: NSFont = NSFont.systemFont(ofSize: 13, weight: NSFont.Weight.regular)
    
    func height(_ item: AnyObject, index: Int) -> CGFloat {
        return 22
    }
    
    func adapt(_ view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView? {
        
        guard let value = item as? SearchSuggestionResultItemValue else { return nil }
        
        let rowView: SuggestionValueTableRowView
        if let view = view as? SuggestionValueTableRowView {
            rowView = view
        } else {
            rowView = SuggestionValueTableRowView()
            rowView.subtitleLabel.stringValue = ""
            rowView.selectionType = .highlight
            rowView.checked = false
            rowView.separatorView.isHidden = true
            rowView.titleLabel.font = SuggestionValueTableViewAdaptor.foregroundFont
        }
        
        rowView.titleLabel.stringValue = value.title
        
        
        return rowView
    }
}
