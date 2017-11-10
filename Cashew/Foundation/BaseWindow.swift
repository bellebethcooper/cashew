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

    override func makeFirstResponder(aResponder: NSResponder?) -> Bool {
        //DDLogDebug("current first responder -> \(aResponder)")
        let didBecomeFirstResponder = super.makeFirstResponder(aResponder)
        
        dispatch_async(dispatch_get_main_queue()) {
            NSNotificationCenter.defaultCenter().postNotificationName(kDidBecomeFirstResponderNotification, object: aResponder)
        }
        
        return didBecomeFirstResponder
    }
}
