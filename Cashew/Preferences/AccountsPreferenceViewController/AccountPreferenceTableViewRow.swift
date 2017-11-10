//
//  AccountPreferenceTableViewRow.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/2/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class AccountPreferenceTableViewRow: BaseTableRowView {
    
    private static let imageSize = CGSizeMake(20, 20)
    private static let padding: CGFloat = 6.0
    
    private let imageView = BaseView()
    
    var account: QAccount {
        didSet {
            didSetAccount()
        }
    }
    
    required init(account: QAccount) {
        self.account = account
        super.init()
        disableThemeObserver = true
        selectionType = .Highlight
        
        contentView.addSubview(imageView)
        imageView.backgroundColor = NSColor(calibratedWhite: 0.90, alpha: 1)
        imageView.cornerRadius = AccountPreferenceTableViewRow.imageSize.height / 2.0
        backgroundColor = NSColor.whiteColor()
        contentView.backgroundColor = NSColor.whiteColor()
        titleLabel.textColor = LightModeColor.sharedInstance.foregroundColor()
        
        didSetAccount()
    }
    
    override var selected: Bool {
        didSet {
            if selected {
                backgroundColor = BaseTableRowView.selectionColor
                contentView.backgroundColor = BaseTableRowView.selectionColor
                titleLabel.textColor = NSColor.whiteColor()
            } else {
                backgroundColor = NSColor.whiteColor()
                contentView.backgroundColor = NSColor.whiteColor()
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
    private func didSetAccount() {
        let owner = QOwnerStore.ownerForAccountId(account.identifier, identifier: account.userId)
        titleLabel.stringValue = account.username
        subtitleLabel.stringValue = ""
        imageView.setImageURL(owner.avatarURL)
    }
    
}

