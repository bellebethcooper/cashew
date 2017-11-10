//
//  OrganizationPrivateRepositoryPermissionTableRowView.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/28/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa


class OrganizationPrivateRepositoryPermissionViewModel: NSObject { }

class OrganizationPrivateRepositoryPermissionTableRowView: NSTableRowView {

    private static let padding: CGFloat = 6.0
    private static let orgIcon: NSImage = {
       return NSImage(named:"organization")!.imageWithTintColor(NSColor(calibratedWhite: 111/255.0, alpha: 1))
    }()
    
    private let label = BaseLabel()
    private let separatorView = BaseSeparatorView()
    private let imageView = NSImageView()
    // private var cursorTrackingArea: NSTrackingArea?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init() {
        super.init(frame: NSRect.zero)
        setup()
    }
    
    
    private func setup() {
        //separatorView.backgroundColor = NSColor(calibratedWhite: 0.90, alpha: 1)
        addSubview(separatorView)
        
        addSubview(imageView)
        imageView.image = OrganizationPrivateRepositoryPermissionTableRowView.orgIcon
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraintEqualToConstant(14).active = true
        imageView.widthAnchor.constraintEqualToConstant(16).active = true
        imageView.leftAnchor.constraintEqualToAnchor(leftAnchor, constant: OrganizationPrivateRepositoryPermissionTableRowView.padding).active = true
        imageView.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        
        addSubview(label)
        label.stringValue = "Cannot find your organization private repositories? Click here for more details."
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        label.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        label.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        label.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        label.leftAnchor.constraintEqualToAnchor(imageView.rightAnchor, constant: OrganizationPrivateRepositoryPermissionTableRowView.padding).active = true
        label.rightAnchor.constraintEqualToAnchor(rightAnchor, constant: -OrganizationPrivateRepositoryPermissionTableRowView.padding).active = true
        label.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        label.font = NSFont.boldSystemFontOfSize(12)
        
        label.usesSingleLineMode = false
        label.cell?.lineBreakMode = .ByWordWrapping
        
        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(OrganizationPrivateRepositoryPermissionTableRowView.didClickRow)))
    }
    
    @objc
    private func didClickRow() {
        if let url = NSURL(string: "http://www.cashewapp.co/help/private_organization_repositories") {
            NSWorkspace.sharedWorkspace().openURL(url)
        }
    }
    
    override func layout() {
        let padding = OrganizationPrivateRepositoryPermissionTableRowView.padding
        separatorView.frame = CGRectIntegralMake(x: padding, y: bounds.height - 1, width: bounds.width - padding, height: 1)
        super.layout()
    }

    

    
}
