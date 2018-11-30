//
//  BaseLabel.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class BaseLabelCell: NSTextFieldCell {
    
//    override func titleRectForBounds(theRect: NSRect) -> NSRect {
//        return CGRectOffset(super.titleRectForBounds(theRect), 0, -7)
//    }
}

@objc(SRBaseLabel)
class BaseLabel: NSTextField {
    
    var disableThemeObserver: Bool = false  {
        didSet {
            if disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(self)
            }
        }
    }

    required init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    var shouldAllowVibrancy: Bool = true
    
    override var allowsVibrancy: Bool {
        get {
            return shouldAllowVibrancy
        }
    }
    
   
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    fileprivate func setup() {
        cell = BaseLabelCell()
        wantsLayer = true
        focusRingType = .none
        isBordered = false
        isSelectable = false
        isBezeled = false
        //bezelStyle = .SquareBezel
        usesSingleLineMode = true
        cell?.lineBreakMode = .byTruncatingTail
        
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
            
            strongSelf.backgroundColor = CashewColor.backgroundColor()
            strongSelf.textColor = CashewColor.foregroundSecondaryColor()
        }
    }
    
}
