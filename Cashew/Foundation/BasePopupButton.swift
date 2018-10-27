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
    
    fileprivate static let chevronAndLabelPadding: CGFloat = 5.0
    fileprivate static let chevronImageSize = NSMakeSize(8, 5)
    
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
            return CGSize(width: width, height: height)
        }
    }
    
    fileprivate func setup() {
        wantsLayer = true
        
        addSubview(label)
//        label.layer?.borderWidth = 1
//        label.layer?.borderColor = NSColor.redColor().CGColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        label.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .vertical)
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .vertical)
        
        addSubview(chevronImageView)
        chevronImageView.wantsLayer = true
//        chevronImageView.layer?.borderWidth = 1
//        chevronImageView.layer?.borderColor = NSColor.redColor().CGColor
        chevronImageView.imageScaling = .scaleProportionallyUpOrDown
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.leftAnchor.constraint(equalTo: label.rightAnchor, constant: BasePopupButton.chevronAndLabelPadding).isActive = true
        chevronImageView.centerYAnchor.constraint(equalTo: label.centerYAnchor, constant:  0).isActive = true
        chevronImageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        chevronImageView.widthAnchor.constraint(equalToConstant: BasePopupButton.chevronImageSize.width).isActive = true
        chevronImageView.heightAnchor.constraint(equalToConstant: BasePopupButton.chevronImageSize.height).isActive = true
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
            
            if mode == .dark {
               // strongSelf.appearance = NSAppearance(named:NSAppearanceNameVibrantDark)
            } else {
               // strongSelf.appearance = NSAppearance(named:NSAppearanceNameVibrantLight)
            }

            strongSelf.chevronImageView.image = strongSelf.chevronImage()
            strongSelf.backgroundColor = CashewColor.backgroundColor()
        }
    }
    
    func chevronImage(_ color: NSColor = CashewColor.foregroundColor()) -> NSImage {
        let image = NSImage(named: NSImage.Name(rawValue: "chevron-down"))!.withTintColor(color)
        image?.size = BasePopupButton.chevronImageSize
        return image!
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        didClickMenuButton()
    }
    
    func didClickMenuButton() {
        guard let event = NSApp.currentEvent else { return }
        let menu = SRMenu()
        
        for item in menuItems {
            menu.addItem(item)
        }
        
        let pointInWindow = convert(CGPoint.zero, to: nil)
        let point = NSPoint(x: pointInWindow.x + frame.width - menu.size.width, y: pointInWindow.y - frame.height * 1.5)
        if let windowNumber = window?.windowNumber, let popupEvent = NSEvent.mouseEvent(with: .leftMouseUp, location: point, modifierFlags: event.modifierFlags, timestamp: 0, windowNumber: windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0) {
            SRMenu.popUpContextMenu(menu, with: popupEvent, for: self)
        }
    }
    
    override var isFlipped: Bool {
        get {
            return true
        }
    }
    
}
