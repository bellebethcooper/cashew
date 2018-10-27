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
        
        if let fieldEditor = window?.fieldEditor(true, for: self) as? NSTextView , success {
           // fieldEditor.insertionPointColor = CashewColor.foregroundColor()
            if UserDefaults.themeMode() == .dark {
                fieldEditor.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
            } else {
                fieldEditor.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
            }
        }
        
        return success
    }
    
}
