//
//  BaseSeparatorView.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/8/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRBaseSeparatorView)
class BaseSeparatorView: BaseView {
    
    static let separatorLineSelectedColor =  NSColor(calibratedWhite: 255/255.0, alpha: 0.05)
    
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setupSeparator()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupSeparator()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupSeparator()
    }
    
    var selected: Bool = false {
        didSet {
            if selected {
                self.backgroundColor = BaseSeparatorView.separatorLineSelectedColor
            } else {
                self.backgroundColor = CashewColor.separatorColor()
            }
        }
    }
    
    private func setupSeparator() {
        self.wantsLayer = true
        self.selected = false
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            let selected = strongSelf.selected
            strongSelf.selected = selected
        }
    }
    
    
}
