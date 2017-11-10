//
//  RepositorySearchResultTableRowView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class RepositorySearchResultTableRowView: BaseTableRowView {
    
    var repository: QRepository {
        didSet {
            didSetRepository()
        }
    }
    
    required init(repository: QRepository) {
        self.repository = repository
        super.init()
        
        selectionType = .Checkbox
        
        didSetRepository()
        
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
    
    
    private var _checked = false
    override var checked: Bool {
        set(newValue) {
            if newValue {
                accessoryView = GreenCheckboxView()
            } else {
                accessoryView = EmptyCheckboxView()
            }
            accessoryView?.hidden = false
            accessoryView?.disableThemeObserver = true
            accessoryView?.backgroundColor = NSColor.clearColor()
            _checked = newValue
            needsLayout = true
            layoutSubtreeIfNeeded()
        }
        get {
            return _checked
        }
    }
    
    // MARK: Setup
    private func didSetRepository() {
        titleLabel.stringValue = repository.fullName
        subtitleLabel.stringValue = repository.desc ?? ""
    }
    
}
