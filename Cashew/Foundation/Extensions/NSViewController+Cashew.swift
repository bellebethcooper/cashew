//
//  NSViewController+Cashew.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


extension NSViewController {
    
    
    @objc
    public func presentViewControllerInWindowControllerModallyWithTitle(title: String) {
        self.presentViewControllerInWindowControllerModallyWithTitle(title, onCompletion: nil)
    }
    
    @objc
    public func presentViewControllerInWindowControllerModallyWithTitle(title: String, onCompletion: dispatch_block_t? = nil) {
        let appDelegate = AppDelegate.sharedCashewAppDelegate();
        appDelegate.presentWindowWithViewController(self, title: title, onCompletion: onCompletion)
    }
    
    
}