//
//  BaseButton.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/29/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class BaseButton: BaseView {
    
    private let textLabel = BaseLabel()
    private let button = BaseView()
    private var cursorTrackingArea: NSTrackingArea?
    
    var enabledBackgroundColor = NSColor(calibratedRed: 33/255.0, green: 201/255.0, blue: 115/255.0, alpha: 1.0) {
        didSet {
            button.backgroundColor = enabledBackgroundColor
        }
    }
    
    var pressedStateColor: NSColor?
    
    var disabledFontColor = NSColor.whiteColor()
    
    var textColor: NSColor  = NSColor.whiteColor() {
        didSet {
            textLabel.textColor = textColor
        }
    }
    
    var onClick: dispatch_block_t?
    
    var enabled: Bool = true {
        didSet {
            if enabled {
                button.backgroundColor = enabledBackgroundColor
                textLabel.textColor = textColor
            } else {
                button.backgroundColor = NSColor.grayColor()
                textLabel.textColor = disabledFontColor
            }
        }
    }
    
    var text: String = "" {
        didSet {
            textLabel.stringValue = text
        }
    }
    
    class func greenButton() -> BaseButton {
        let button = BaseButton()
        
        button.enabledBackgroundColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1) //NSColor(calibratedRed: 33/255.0, green: 201/255.0, blue: 115/255.0, alpha: 1.0)
        button.pressedStateColor = NSColor(calibratedRed: 64/255.0, green: 129/255.0, blue: 43/255.0, alpha: 1.0)
        button.textColor = NSColor.whiteColor()
        button.button.borderColor = NSColor.clearColor()
        
        return button
    }
    
    class func whiteButton() -> BaseButton {
        let button = BaseButton()
        
        button.enabledBackgroundColor = NSColor.whiteColor()
        button.pressedStateColor = NSColor(calibratedWhite: 211/255.0, alpha: 1.0)
        button.textColor = NSColor(white: 0.6, alpha: 1)
        button.button.borderColor = NSColor(white: 0.9, alpha: 1)
        
        return button
    }
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    //    override func drawRect(dirtyRect: NSRect) {
    //        DarkModeColor.sharedInstance.popoverBackgroundColor().set()
    //        NSRectFill(bounds)
    //    }
    
    init() {
        super.init(frame: CGRect.zero)
        
        textLabel.shouldAllowVibrancy = false
        shouldAllowVibrancy = false
        button.shouldAllowVibrancy = false
        
        addSubview(button)
        button.pinAnchorsToSuperview()
        button.layer?.cornerRadius = 3.0
        button.layer?.masksToBounds = true
        
        textLabel.font = NSFont.systemFontOfSize(14)
        textLabel.backgroundColor  = NSColor.clearColor()
        textLabel.textColor = NSColor.whiteColor()
        textLabel.alignment = .Center
        
        self.canDrawConcurrently = true;
        
        allowMouseToMoveWindow = false
        
        addSubview(textLabel)
        
        //        shouldAllowVibrancy = true
        //        textLabel.shouldAllowVibrancy = true
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(strongSelf)
                return;
            }
            
            if mode == .Dark {
                strongSelf.appearance = NSAppearance(named:NSAppearanceNameVibrantDark);
                strongSelf.textLabel.appearance = NSAppearance(named:NSAppearanceNameVibrantDark);
                strongSelf.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                strongSelf.appearance = NSAppearance(named:NSAppearanceNameVibrantLight);
                strongSelf.textLabel.appearance = NSAppearance(named:NSAppearanceNameVibrantLight);
                strongSelf.backgroundColor = CashewColor.backgroundColor()
            }
            
            let enabled = strongSelf.enabled
            strongSelf.enabled = enabled
        }
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseUp(theEvent: NSEvent) {
        guard enabled else { return }
        
        if let onClick = onClick where isMouseOver() {
            onClick()
        }
        if enabled {
            button.backgroundColor = enabledBackgroundColor
        } else {
            button.backgroundColor = NSColor.grayColor()
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        guard let pressedStateColor = pressedStateColor where enabled else { return }
        button.backgroundColor = pressedStateColor
    }
    
    override func layout() {
        let textLabelSize = (text as NSString).textSizeForWithAttributes([NSFontAttributeName: textLabel.font!])
        let textLabelLeft = bounds.width / 2.0 - textLabelSize.width / 2.0
        let textLabeltop = bounds.height / 2.0 - textLabelSize.height / 2.0
        
        textLabel.frame = CGRectIntegralMake(x: textLabelLeft, y: textLabeltop - 2, width: textLabelSize.width, height: textLabelSize.height)
        super.layout()
    }
    
    // MARK: Tracking Area
    override func updateTrackingAreas() {
        if let cursorTrackingArea = cursorTrackingArea {
            removeTrackingArea(cursorTrackingArea)
        }
        
        let trackingArea = NSTrackingArea(rect: bounds, options: [.CursorUpdate, .ActiveAlways] , owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea);
        self.cursorTrackingArea = trackingArea
    }
    
    override func cursorUpdate(event: NSEvent) {
        guard enabled else { return }
        NSCursor.pointingHandCursor().set()
    }
    
}
