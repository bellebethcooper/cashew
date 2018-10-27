//
//  AssigneeSearchResultTableRowView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/2/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class AssigneeSearchResultTableRowView: BaseTableRowView {
    
    fileprivate static let imageSize = CGSize(width: 20, height: 20)
    fileprivate static let padding: CGFloat = 6.0
    
    fileprivate let imageView = BaseView()
    
    var owner: QOwner {
        didSet {
            didSetOwner()
        }
    }
    
    required init(owner: QOwner) {
        self.owner = owner
        super.init()
        
        selectionType = .checkbox
        
        contentView.addSubview(imageView)
        imageView.backgroundColor = NSColor(calibratedWhite: 0.90, alpha: 1)
        imageView.cornerRadius = AssigneeSearchResultTableRowView.imageSize.height / 2.0
        
        
        didSetOwner()
    
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
    
    override func layout() {
        super.layout()
        
        let circleTop = bounds.height / 2.0 - AssigneeSearchResultTableRowView.imageSize.height / 2.0
        imageView.frame = CGRectIntegralMake(x: AssigneeSearchResultTableRowView.padding, y: circleTop, width: AssigneeSearchResultTableRowView.imageSize.width, height: AssigneeSearchResultTableRowView.imageSize.height)
        
        let titleLabelTop = bounds.height / 2.0 - titleLabel.frame.height / 2.0
        titleLabel.frame = CGRectIntegralMake(x: imageView.frame.maxX + AssigneeSearchResultTableRowView.padding, y: titleLabelTop, width: titleLabel.frame.width - (imageView.frame.maxX + AssigneeSearchResultTableRowView.padding), height: titleLabel.frame.height)
    }
    
    
    // MARK: Setup
    fileprivate func didSetOwner() {
        titleLabel.stringValue = owner.login
        subtitleLabel.stringValue = ""
        imageView.setImageURL(owner.avatarURL)
    }
    
}
