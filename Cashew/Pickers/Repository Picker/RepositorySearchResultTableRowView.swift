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
        
        selectionType = .checkbox
        
        didSetRepository()
        
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
    
    
    fileprivate var _checked = false
    override var checked: Bool {
        set(newValue) {
            if newValue {
                accessoryView = GreenCheckboxView()
            } else {
                accessoryView = EmptyCheckboxView()
            }
            accessoryView?.isHidden = false
            accessoryView?.disableThemeObserver = true
            accessoryView?.backgroundColor = NSColor.clear
            _checked = newValue
            needsLayout = true
            layoutSubtreeIfNeeded()
        }
        get {
            return _checked
        }
    }
    
    // MARK: Setup
    fileprivate func didSetRepository() {
        titleLabel.stringValue = repository.fullName
        subtitleLabel.stringValue = repository.desc ?? ""
    }
    
}
