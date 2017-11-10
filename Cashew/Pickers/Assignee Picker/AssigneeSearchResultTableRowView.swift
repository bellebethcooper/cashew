//
//  AssigneeSearchResultTableRowView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/2/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class AssigneeSearchResultTableRowView: BaseTableRowView {
    
    private static let imageSize = CGSizeMake(20, 20)
    private static let padding: CGFloat = 6.0
    
    private let imageView = BaseView()
    
    var owner: QOwner {
        didSet {
            didSetOwner()
        }
    }
    
    required init(owner: QOwner) {
        self.owner = owner
        super.init()
        
        selectionType = .Checkbox
        
        contentView.addSubview(imageView)
        imageView.backgroundColor = NSColor(calibratedWhite: 0.90, alpha: 1)
        imageView.cornerRadius = AssigneeSearchResultTableRowView.imageSize.height / 2.0
        
        
        didSetOwner()
    
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
    
    override func layout() {
        super.layout()
        
        let circleTop = bounds.height / 2.0 - AssigneeSearchResultTableRowView.imageSize.height / 2.0
        imageView.frame = CGRectIntegralMake(x: AssigneeSearchResultTableRowView.padding, y: circleTop, width: AssigneeSearchResultTableRowView.imageSize.width, height: AssigneeSearchResultTableRowView.imageSize.height)
        
        let titleLabelTop = bounds.height / 2.0 - titleLabel.frame.height / 2.0
        titleLabel.frame = CGRectIntegralMake(x: imageView.frame.maxX + AssigneeSearchResultTableRowView.padding, y: titleLabelTop, width: titleLabel.frame.width - (imageView.frame.maxX + AssigneeSearchResultTableRowView.padding), height: titleLabel.frame.height)
    }
    
    
    // MARK: Setup
    private func didSetOwner() {
        titleLabel.stringValue = owner.login
        subtitleLabel.stringValue = ""
        imageView.setImageURL(owner.avatarURL)
    }
    
}
