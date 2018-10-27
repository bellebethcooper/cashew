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

    fileprivate static let padding: CGFloat = 6.0
    fileprivate static let orgIcon: NSImage = {
        return NSImage(named:NSImage.Name(rawValue: "organization"))!.withTintColor(NSColor(calibratedWhite: 111/255.0, alpha: 1))
    }()
    
    fileprivate let label = BaseLabel()
    fileprivate let separatorView = BaseSeparatorView()
    fileprivate let imageView = NSImageView()
    // private var cursorTrackingArea: NSTrackingArea?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init() {
        super.init(frame: NSRect.zero)
        setup()
    }
    
    
    fileprivate func setup() {
        //separatorView.backgroundColor = NSColor(calibratedWhite: 0.90, alpha: 1)
        addSubview(separatorView)
        
        addSubview(imageView)
        imageView.image = OrganizationPrivateRepositoryPermissionTableRowView.orgIcon
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 14).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        imageView.leftAnchor.constraint(equalTo: leftAnchor, constant: OrganizationPrivateRepositoryPermissionTableRowView.padding).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addSubview(label)
        label.stringValue = "Cannot find your organization private repositories? Click here for more details."
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .vertical)
        label.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        label.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .vertical)
        label.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: OrganizationPrivateRepositoryPermissionTableRowView.padding).isActive = true
        label.rightAnchor.constraint(equalTo: rightAnchor, constant: -OrganizationPrivateRepositoryPermissionTableRowView.padding).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.font = NSFont.boldSystemFont(ofSize: 12)
        
        label.usesSingleLineMode = false
        label.cell?.lineBreakMode = .byWordWrapping
        
        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(OrganizationPrivateRepositoryPermissionTableRowView.didClickRow)))
    }
    
    @objc
    fileprivate func didClickRow() {
        if let url = URL(string: "http://www.cashewapp.co/help/private_organization_repositories") {
            NSWorkspace.shared.open(url)
        }
    }
    
    override func layout() {
        let padding = OrganizationPrivateRepositoryPermissionTableRowView.padding
        separatorView.frame = CGRectIntegralMake(x: padding, y: bounds.height - 1, width: bounds.width - padding, height: 1)
        super.layout()
    }

    

    
}
