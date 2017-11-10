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
    
    private var cursorTrackingArea: NSTrackingArea?
    
    var enabled: Bool = true
    
    var open: Bool {
        didSet {
            didSetOpen()
        }
    }
    
    var onClick: dispatch_block_t?
    
    private let contentContainerView = BaseView()
    private let imageView = NSImageView()
    private let label = NSTextField()
    
    required init(open: Bool) {
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
            return NSSize(width: 5 * 3 + imageView.intrinsicContentSize.width + label.intrinsicContentSize.width, height: 36)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func didSetOpen() {
        
        let font = NSFont.systemFontOfSize(13, weight: NSFontWeightSemibold)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.Center
        paragraphStyle.lineSpacing = 0
        paragraphStyle.maximumLineHeight = 15
        paragraphStyle.minimumLineHeight = 15
        let textColor = NSColor.whiteColor()
        
        let text: NSAttributedString
        if open {
            text = NSAttributedString(string: "Open", attributes: [NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: font])
            
            let image = NSImage(named: "issue-opened")
            image?.size = CGSize(width: 12.2, height: 14)
            imageView.image = image?.imageWithTintColor(NSColor.whiteColor())
            contentContainerView.backgroundColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1);
        } else {
            text = NSAttributedString(string: "Closed", attributes: [NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName: font])
            
            let image = NSImage(named: "issue-closed")
            image?.size = CGSize(width: 14, height: 14)
            imageView.image = image?.imageWithTintColor(NSColor.whiteColor())
            contentContainerView.backgroundColor = NSColor(calibratedRed: 175/255.0, green: 25/255.0, blue: 0/255.0, alpha: 1)
        }
        label.attributedStringValue = text
        backgroundColor = NSColor.clearColor() //contentContainerView.backgroundColor
        label.backgroundColor = NSColor.clearColor()
        invalidateIntrinsicContentSize()
    }
    
    
    override func mouseUp(theEvent: NSEvent) {
        guard enabled else { return }
        if let onClick = onClick where isMouseOver() {
            onClick()
        }
        
        if open {
            contentContainerView.backgroundColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1);
        } else {
            contentContainerView.backgroundColor = NSColor(calibratedRed: 175/255.0, green: 25/255.0, blue: 0/255.0, alpha: 1)
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
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
        contentContainerView.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        contentContainerView.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        contentContainerView.heightAnchor.constraintEqualToConstant(20).active = true
        contentContainerView.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
       // contentContainerView.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        contentContainerView.cornerRadius = 3
        
        label.editable = false
        label.selectable = false
        label.bordered = false
        label.textColor = NSColor.whiteColor()
        
        contentContainerView.addSubview(label)
        label.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
       // label.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.rightAnchor.constraintEqualToAnchor(contentContainerView.rightAnchor, constant: -5.0).active = true
        label.centerYAnchor.constraintEqualToAnchor(contentContainerView.centerYAnchor).active = true
        label.bottomAnchor.constraintEqualToAnchor(contentContainerView.bottomAnchor, constant: -2.0).active = true
        
        contentContainerView.addSubview(imageView)
        imageView.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
     //   imageView.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.leftAnchor.constraintEqualToAnchor(contentContainerView.leftAnchor, constant: 5.0).active = true
        imageView.rightAnchor.constraintEqualToAnchor(label.leftAnchor, constant: 0.0).active = true
        imageView.centerYAnchor.constraintEqualToAnchor(label.centerYAnchor).active = true
        
        imageView.wantsLayer = true
    }
    
    // MARK: Tracking Area
    override func updateTrackingAreas() {
        if let cursorTrackingArea = cursorTrackingArea {
            removeTrackingArea(cursorTrackingArea)
        }
        
        guard enabled else { return }
        
        let trackingArea = NSTrackingArea(rect: bounds, options: [.CursorUpdate, .ActiveAlways] , owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea);
        self.cursorTrackingArea = trackingArea
    }
    
    override func cursorUpdate(event: NSEvent) {
        guard enabled else { return }
        NSCursor.pointingHandCursor().set()
    }
}
