//
//  IssueStateBadgeView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/12/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation


@objc(SRIssueStateBadgeView)
class IssueStateBadgeView: BaseView {
    
    fileprivate var cursorTrackingArea: NSTrackingArea?
    
    @objc var enabled: Bool = true
    
    @objc var open: Bool {
        didSet {
            didSetOpen()
        }
    }
    
    @objc var onClick: (()->())?
    
    fileprivate let contentContainerView = BaseView()
    fileprivate let imageView = NSImageView()
    fileprivate let label = NSTextField()
    
    @objc required init(open: Bool) {
        self.open = open
        super.init(frame: NSRect.zero)
        disableThemeObserver = true
        contentContainerView.disableThemeObserver = true
        allowMouseToMoveWindow = false
        contentContainerView.allowMouseToMoveWindow = false
        setupContentContainerView()
        didSetOpen()
    }
    
    override var intrinsicContentSize: NSSize {
        get {
            return NSSize(width: 5 * 4 + imageView.intrinsicContentSize.width + label.intrinsicContentSize.width, height: 40)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    fileprivate func didSetOpen() {
        
        let font = NSFont.systemFont(ofSize: 13, weight: NSFont.Weight.semibold)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        paragraphStyle.lineSpacing = 0
        paragraphStyle.maximumLineHeight = 15
        paragraphStyle.minimumLineHeight = 15
        let textColor = NSColor.white
        
        let text: NSAttributedString
        if open {
            text = NSAttributedString(string: "Open", attributes: [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.paragraphStyle: paragraphStyle, NSAttributedStringKey.font: font])
            
            let image = NSImage(named: NSImage.Name(rawValue: "issue-opened"))
            image?.size = CGSize(width: 12.2, height: 14)
            imageView.image = image?.withTintColor(NSColor.white)
            contentContainerView.backgroundColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1);
        } else {
            text = NSAttributedString(string: "Closed", attributes: [NSAttributedStringKey.foregroundColor: textColor, NSAttributedStringKey.paragraphStyle: paragraphStyle, NSAttributedStringKey.font: font])
            
            let image = NSImage(named: NSImage.Name(rawValue: "issue-closed"))
            image?.size = CGSize(width: 14, height: 14)
            imageView.image = image?.withTintColor(NSColor.white)
            contentContainerView.backgroundColor = NSColor(calibratedRed: 175/255.0, green: 25/255.0, blue: 0/255.0, alpha: 1)
        }
        label.attributedStringValue = text
        backgroundColor = NSColor.clear //contentContainerView.backgroundColor
        label.backgroundColor = NSColor.clear
        invalidateIntrinsicContentSize()
    }
    
    
    override func mouseUp(with theEvent: NSEvent) {
        guard enabled else { return }
        if let onClick = onClick , isMouseOver() {
            onClick()
        }
        
        if open {
            contentContainerView.backgroundColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1);
        } else {
            contentContainerView.backgroundColor = NSColor(calibratedRed: 175/255.0, green: 25/255.0, blue: 0/255.0, alpha: 1)
        }
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        guard enabled else { return }
        if open {
            contentContainerView.backgroundColor = NSColor(calibratedRed: 64/255.0, green: 129/255.0, blue: 43/255.0, alpha: 1.0)
        } else {
            contentContainerView.backgroundColor = NSColor(calibratedRed: 121/255.0, green: 30/255.0, blue: 29/255.0, alpha: 1.0)
        }
    }
    
    // MARK: General Setup
    func setupContentContainerView() {
        guard contentContainerView.superview == nil  else { return }
        
        addSubview(contentContainerView)
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        contentContainerView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        contentContainerView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        contentContainerView.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .horizontal)
       // contentContainerView.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        contentContainerView.cornerRadius = 3
        
        label.isEditable = false
        label.isSelectable = false
        label.isBordered = false
        label.textColor = NSColor.white
        
        contentContainerView.addSubview(label)
        label.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .horizontal)
       // label.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.rightAnchor.constraint(equalTo: contentContainerView.rightAnchor, constant: -5.0).isActive = true
        label.centerYAnchor.constraint(equalTo: contentContainerView.centerYAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor, constant: -2.0).isActive = true
        
        contentContainerView.addSubview(imageView)
        imageView.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .horizontal)
     //   imageView.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.leftAnchor.constraint(equalTo: contentContainerView.leftAnchor, constant: 5.0).isActive = true
        imageView.rightAnchor.constraint(equalTo: label.leftAnchor, constant: 0.0).isActive = true
        imageView.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
        
        imageView.wantsLayer = true
    }
    
    // MARK: Tracking Area
    override func updateTrackingAreas() {
        if let cursorTrackingArea = cursorTrackingArea {
            removeTrackingArea(cursorTrackingArea)
        }
        
        guard enabled else { return }
        
        let trackingArea = NSTrackingArea(rect: bounds, options: [NSTrackingArea.Options.cursorUpdate, NSTrackingArea.Options.activeAlways] , owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea);
        self.cursorTrackingArea = trackingArea
    }
    
    override func cursorUpdate(with event: NSEvent) {
        guard enabled else { return }
        NSCursor.pointingHand.set()
    }
}
