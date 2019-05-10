//
//  BaseButton.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/29/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc
class BaseButton: BaseView {
    
    fileprivate let textLabel = BaseLabel()
    fileprivate let button = BaseView()
    fileprivate var cursorTrackingArea: NSTrackingArea?
    
    var enabledBackgroundColor = NSColor(calibratedRed: 33/255.0, green: 201/255.0, blue: 115/255.0, alpha: 1.0) {
        didSet {
            button.backgroundColor = enabledBackgroundColor
        }
    }
    
    var pressedStateColor: NSColor?
    
    var disabledFontColor = NSColor.white
    
    var textColor: NSColor  = NSColor.white {
        didSet {
            textLabel.textColor = textColor
        }
    }
    
    @objc var onClick: (()->())?
    
    var enabled: Bool = true {
        didSet {
            if enabled {
                button.backgroundColor = enabledBackgroundColor
                textLabel.textColor = textColor
            } else {
                button.backgroundColor = NSColor.gray
                textLabel.textColor = disabledFontColor
            }
        }
    }
    
    @objc var text: String = "" {
        didSet {
            textLabel.stringValue = text
        }
    }
    
    @objc
    class func greenButton() -> BaseButton {
        let button = BaseButton()
        
        button.enabledBackgroundColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1) //NSColor(calibratedRed: 33/255.0, green: 201/255.0, blue: 115/255.0, alpha: 1.0)
        button.pressedStateColor = NSColor(calibratedRed: 64/255.0, green: 129/255.0, blue: 43/255.0, alpha: 1.0)
        button.textColor = NSColor.white
        button.button.borderColor = NSColor.clear
        
        return button
    }
    
    class func whiteButton() -> BaseButton {
        let button = BaseButton()
        
        button.enabledBackgroundColor = NSColor.white
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
        
        textLabel.font = NSFont.systemFont(ofSize: 14)
        textLabel.backgroundColor  = NSColor.clear
        textLabel.textColor = NSColor.white
        textLabel.alignment = .center
        
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
            
            if mode == .dark {
                strongSelf.appearance = NSAppearance(named:NSAppearance.Name.vibrantDark);
                strongSelf.textLabel.appearance = NSAppearance(named:NSAppearance.Name.vibrantDark);
                strongSelf.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                strongSelf.appearance = NSAppearance(named:NSAppearance.Name.vibrantLight);
                strongSelf.textLabel.appearance = NSAppearance(named:NSAppearance.Name.vibrantLight);
                strongSelf.backgroundColor = CashewColor.backgroundColor()
            }
            
            let enabled = strongSelf.enabled
            strongSelf.enabled = enabled
        }
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseUp(with theEvent: NSEvent) {
        guard enabled else { return }
        
        if let onClick = onClick , isMouseOver() {
            onClick()
        }
        if enabled {
            button.backgroundColor = enabledBackgroundColor
        } else {
            button.backgroundColor = NSColor.gray
        }
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        guard let pressedStateColor = pressedStateColor , enabled else { return }
        button.backgroundColor = pressedStateColor
    }
    
    override func layout() {
        let textLabelSize = (text as NSString).textSizeForWithAttributes([kCTFontAttributeName as NSAttributedString.Key: textLabel.font!])
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
        
        let trackingArea = NSTrackingArea(rect: bounds, options: [.cursorUpdate, .activeAlways] , owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea);
        self.cursorTrackingArea = trackingArea
    }
    
    override func cursorUpdate(with event: NSEvent) {
        guard enabled else { return }
        NSCursor.pointingHand.set()
    }
    
}
