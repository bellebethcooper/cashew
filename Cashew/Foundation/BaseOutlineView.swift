//
//  BaseOutlineView.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRBaseOutlineView)
class BaseOutlineView: NSOutlineView {
    
    var disableThemeObserver = false {
        didSet {
            ThemeObserverController.sharedInstance.removeThemeObserver(self)
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
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    

    fileprivate func setup() {
        self.wantsLayer = true
        setupThemeObserver()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func setupThemeObserver() {
        
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
            
            if mode == .light {
                self?.backgroundColor = LightModeColor.sharedInstance.backgroundColor()
            } else if mode == .dark {
                self?.backgroundColor = DarkModeColor.sharedInstance.backgroundColor()
            }
        }
    }
    
}
