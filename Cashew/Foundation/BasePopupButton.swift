//
//  BasePopupButton.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/9/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRBasePopupButton)
class BasePopupButton: BaseView {
    
    private static let chevronAndLabelPadding: CGFloat = 5.0
    private static let chevronImageSize = NSMakeSize(8, 5)
    
    let label = BaseLabel()
    let chevronImageView = NSImageView()
    var menuItems = [NSMenuItem]()
    
    var font: NSFont? {
        didSet {
            label.font = font
            invalidateIntrinsicContentSize()
        }
    }
    
    var textColor: NSColor? {
        didSet {
            label.textColor = textColor
        }
    }
    
    var stringValue: String = "" {
        didSet {
            label.stringValue = stringValue
            invalidateIntrinsicContentSize()
        }
    }
    
    override var disableThemeObserver: Bool {
        didSet {
            label.disableThemeObserver = disableThemeObserver
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    override var intrinsicContentSize: NSSize {
        get {
            let height = max(label.intrinsicContentSize.height, BasePopupButton.chevronImageSize.height)
            let width = label.intrinsicContentSize.width + BasePopupButton.chevronAndLabelPadding + BasePopupButton.chevronImageSize.width
            return CGSizeMake(width, height)
        }
    }
    
    private func setup() {
        wantsLayer = true
        
        addSubview(label)
//        label.layer?.borderWidth = 1
//        label.layer?.borderColor = NSColor.redColor().CGColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leftAnchor.constraintEqualToAnchor(leftAnchor).active = true
        label.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        label.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        label.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        label.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        label.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        
        addSubview(chevronImageView)
        chevronImageView.wantsLayer = true
//        chevronImageView.layer?.borderWidth = 1
//        chevronImageView.layer?.borderColor = NSColor.redColor().CGColor
        chevronImageView.imageScaling = .ScaleProportionallyUpOrDown
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.leftAnchor.constraintEqualToAnchor(label.rightAnchor, constant: BasePopupButton.chevronAndLabelPadding).active = true
        chevronImageView.centerYAnchor.constraintEqualToAnchor(label.centerYAnchor, constant:  0).active = true
        chevronImageView.rightAnchor.constraintEqualToAnchor(rightAnchor).active = true
        chevronImageView.widthAnchor.constraintEqualToConstant(BasePopupButton.chevronImageSize.width).active = true
        chevronImageView.heightAnchor.constraintEqualToConstant(BasePopupButton.chevronImageSize.height).active = true
//        chevronImageView.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
//        chevronImageView.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
//        chevronImageView.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
//        chevronImageView.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        
        
        if disableThemeObserver {
            return;
        }
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(strongSelf)
                return;
            }
            
            if mode == .Dark {
               // strongSelf.appearance = NSAppearance(named:NSAppearanceNameVibrantDark)
            } else {
               // strongSelf.appearance = NSAppearance(named:NSAppearanceNameVibrantLight)
            }

            strongSelf.chevronImageView.image = strongSelf.chevronImage()
            strongSelf.backgroundColor = CashewColor.backgroundColor()
        }
    }
    
    func chevronImage(color: NSColor = CashewColor.foregroundColor()) -> NSImage {
        let image = NSImage(named: "chevron-down")!.imageWithTintColor(color)
        image.size = BasePopupButton.chevronImageSize
        return image
    }
    
    override func mouseDown(theEvent: NSEvent) {
        didClickMenuButton()
    }
    
    func didClickMenuButton() {
        guard let event = NSApp.currentEvent else { return }
        let menu = SRMenu()
        
        for item in menuItems {
            menu.addItem(item)
        }
        
        let pointInWindow = convertPoint(CGPoint.zero, toView: nil)
        let point = NSPoint(x: pointInWindow.x + frame.width - menu.size.width, y: pointInWindow.y - frame.height * 1.5)
        if let windowNumber = window?.windowNumber, popupEvent = NSEvent.mouseEventWithType(.LeftMouseUp, location: point, modifierFlags: event.modifierFlags, timestamp: 0, windowNumber: windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0) {
            SRMenu.popUpContextMenu(menu, withEvent: popupEvent, forView: self)
        }
    }
    
    override var flipped: Bool {
        get {
            return true
        }
    }
    
}
