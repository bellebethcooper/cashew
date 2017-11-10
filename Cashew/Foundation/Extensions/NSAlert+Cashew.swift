//
//  NSAlert+Cashew.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/5/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


extension NSAlert {
    
    class func showWarningMessage(message: String, body: String, onConfirmation: dispatch_block_t) {
        let alert = NSAlert()
        
        alert.addButtonWithTitle("OK")
        alert.addButtonWithTitle("Cancel")
        alert.messageText = message
        alert.informativeText = body ?? ""
        alert.alertStyle = .Warning // .Warning
        
        if alert.runModal() == NSAlertFirstButtonReturn {
            onConfirmation()
        }
    }
    
    class func showWarningMessage(message: String, onConfirmation: dispatch_block_t) {
        let alert = NSAlert()
        
        alert.addButtonWithTitle("OK")
        alert.addButtonWithTitle("Cancel")
        alert.messageText = message
        alert.alertStyle = .Warning // .Warning
        
        if alert.runModal() == NSAlertFirstButtonReturn {
            onConfirmation()
        }
    }
    
    
    class func showOKWarningMessage(message: String, onCompletion: dispatch_block_t? = nil) {
        let alert = NSAlert()
        
        alert.addButtonWithTitle("OK")
        alert.messageText = message
        alert.alertStyle = .Warning // .Warning
        
        if alert.runModal() == NSAlertFirstButtonReturn {
            if let onCompletion = onCompletion {
                onCompletion()
            }
        }
    }
    
    class func showOKMessage(message: String, body: String? = nil, onCompletion: dispatch_block_t? = nil) {
        let alert = NSAlert()
        
        alert.addButtonWithTitle("OK")
        alert.messageText = message
        alert.informativeText = body ?? ""
        alert.alertStyle = .Warning // .Warning
        
        if alert.runModal() == NSAlertFirstButtonReturn {
            if let onCompletion = onCompletion {
                onCompletion()
            }
        }
    }
    
}
