//
//  NSAlert+Cashew.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/5/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


extension NSAlert {

    @objc
    class func showWarningMessage(_ message: String, body: String, onConfirmation: (() -> ())) {
        let alert = NSAlert()
        
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = message
        alert.informativeText = body
        alert.alertStyle = .warning // .Warning
        
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            onConfirmation()
        }
    }

    @objc
    class func showWarningMessage(_ message: String, onConfirmation: (() -> ())) {
        let alert = NSAlert()
        
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = message
        alert.alertStyle = .warning // .Warning
        
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            onConfirmation()
        }
    }
    
    @objc
    class func showOKWarningMessage(_ message: String, onCompletion: (() -> ())? = nil) {
        let alert = NSAlert()
        
        alert.addButton(withTitle: "OK")
        alert.messageText = message
        alert.alertStyle = .warning // .Warning
        
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            if let onCompletion = onCompletion {
                onCompletion()
            }
        }
    }

    @objc
    class func showOKMessage(_ message: String, body: String? = nil, onCompletion: (() -> ())? = nil) {
        let alert = NSAlert()
        
        alert.addButton(withTitle: "OK")
        alert.messageText = message
        alert.informativeText = body ?? ""
        alert.alertStyle = .warning // .Warning
        
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            if let onCompletion = onCompletion {
                onCompletion()
            }
        }
    }
    
}
