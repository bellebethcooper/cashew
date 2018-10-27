//
//  BaseWindow.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/26/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRBaseWindow)
class BaseWindow: NSWindow {

    override func makeFirstResponder(_ aResponder: NSResponder?) -> Bool {
        //DDLogDebug("current first responder -> \(aResponder)")
        let didBecomeFirstResponder = super.makeFirstResponder(aResponder)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name.didBecomeFirstResponder, object: aResponder)
        }
        
        return didBecomeFirstResponder
    }
}
