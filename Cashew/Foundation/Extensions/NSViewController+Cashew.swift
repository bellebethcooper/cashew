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
    public func presentViewControllerInWindowControllerModallyWithTitle(_ title: String) {
        self.presentViewControllerInWindowControllerModallyWithTitle(title, onCompletion: nil)
    }
    
    @objc
    public func presentViewControllerInWindowControllerModallyWithTitle(_ title: String, onCompletion: (() -> ())? = nil) {
        let appDelegate = AppDelegate.sharedCashewAppDelegate();
        appDelegate.presentWindow(with: self, title: title, onCompletion: onCompletion)
    }
    
    
}
