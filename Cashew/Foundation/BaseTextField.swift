//
//  BaseTextField.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/10/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRBaseTextField)
class BaseTextField: NSTextField {

    
    override func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()
        
        if let fieldEditor = window?.fieldEditor(true, forObject: self) as? NSTextView where success {
           // fieldEditor.insertionPointColor = CashewColor.foregroundColor()
            if NSUserDefaults.themeMode() == .Dark {
                fieldEditor.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
            } else {
                fieldEditor.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
            }
        }
        
        return success
    }
    
}
