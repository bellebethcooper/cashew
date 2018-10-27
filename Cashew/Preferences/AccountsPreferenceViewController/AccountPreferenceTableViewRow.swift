//
//  AccountPreferenceTableViewRow.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/2/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class AccountPreferenceTableViewRow: BaseTableRowView {
    
    fileprivate static let imageSize = CGSize(width: 20, height: 20)
    fileprivate static let padding: CGFloat = 6.0
    
    fileprivate let imageView = BaseView()
    
    var account: QAccount {
        didSet {
            didSetAccount()
        }
    }
    
    required init(account: QAccount) {
        self.account = account
        super.init()
        disableThemeObserver = true
        selectionType = .highlight
        
        contentView.addSubview(imageView)
        imageView.backgroundColor = NSColor(calibratedWhite: 0.90, alpha: 1)
        imageView.cornerRadius = AccountPreferenceTableViewRow.imageSize.height / 2.0
        backgroundColor = NSColor.white
        contentView.backgroundColor = NSColor.white
        titleLabel.textColor = LightModeColor.sharedInstance.foregroundColor()
        
        didSetAccount()
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                backgroundColor = BaseTableRowView.selectionColor
                contentView.backgroundColor = BaseTableRowView.selectionColor
                titleLabel.textColor = NSColor.white
            } else {
                backgroundColor = NSColor.white
                contentView.backgroundColor = NSColor.white
                titleLabel.textColor = LightModeColor.sharedInstance.foregroundColor()
            }
            
            separatorView.backgroundColor = LightModeColor.sharedInstance.separatorColor()
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
        
        let circleTop = bounds.height / 2.0 - AccountPreferenceTableViewRow.imageSize.height / 2.0
        imageView.frame = CGRectIntegralMake(x: AccountPreferenceTableViewRow.padding, y: circleTop, width: AccountPreferenceTableViewRow.imageSize.width, height: AccountPreferenceTableViewRow.imageSize.height)
        
        let titleLabelTop = bounds.height / 2.0 - titleLabel.frame.height / 2.0
        titleLabel.frame = CGRectIntegralMake(x: imageView.frame.maxX + AccountPreferenceTableViewRow.padding, y: titleLabelTop, width: titleLabel.frame.width - (imageView.frame.maxX + AccountPreferenceTableViewRow.padding), height: titleLabel.frame.height)
    }
    
    
    // MARK: Setup
    fileprivate func didSetAccount() {
        let owner = QOwnerStore.owner(forAccountId: account.identifier, identifier: account.userId)
        titleLabel.stringValue = account.username
        subtitleLabel.stringValue = ""
        imageView.setImageURL(owner?.avatarURL)
    }
    
}

