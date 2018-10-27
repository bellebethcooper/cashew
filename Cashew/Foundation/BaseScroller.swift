//
//  BaseScroller.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/9/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRBaseScroller)
@IBDesignable class BaseScroller: NSScroller {
    
    
    @IBInspectable var shouldAllowVibrancy = true
    
    override var allowsVibrancy: Bool {
        return shouldAllowVibrancy
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    
    fileprivate func setup() {
        
        wantsLayer = true
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            if mode == .dark {
                self?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
            } else {
                self?.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
            }
            
            self?.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
    
//    override class func isCompatibleWithOverlayScrollers() -> Bool {
//        return true
//    }
 
}
