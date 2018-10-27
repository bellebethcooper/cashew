//
//  SuggestionHeaderTableViewAdaptor.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/17/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa


class SuggestionHeaderTableRowView: BaseTableRowView {
    
    fileprivate var unselectedTitleColor: NSColor = NSColor.black
    
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
                titleLabel.textColor = CashewColor.foregroundSecondaryColor()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SuggestionHeaderTableViewAdaptor: NSObject, BaseTableViewAdapter {
    
    fileprivate static let foregroundColor: NSColor = NSColor(calibratedWhite: 130/255.0, alpha: 0.85)
    fileprivate static let foregroundFont: NSFont = NSFont.systemFont(ofSize: 10, weight: .semibold)
    
    func height(_ item: AnyObject, index: Int) -> CGFloat {
        return 16
    }
    
    func adapt(_ view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView? {
        guard let value = item as? SearchSuggestionResultItemHeader else { return nil }
        
        let rowView: SuggestionHeaderTableRowView
        if let view = view as? SuggestionHeaderTableRowView {
            rowView = view
        } else {
            rowView = SuggestionHeaderTableRowView()
            rowView.titleLabel.font = SuggestionHeaderTableViewAdaptor.foregroundFont
            rowView.subtitleLabel.stringValue = ""
            rowView.checked = false
            rowView.separatorView.isHidden = true
        }
        
        rowView.titleLabel.stringValue = value.title
        
        return rowView
    }
}
