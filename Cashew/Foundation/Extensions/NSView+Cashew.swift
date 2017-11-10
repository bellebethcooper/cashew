//
//  NSView+Cashew.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


extension NSView {
    
    public func pinAnchorsToSuperview() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        leftAnchor.constraintEqualToAnchor(superview.leftAnchor).active = true
        rightAnchor.constraintEqualToAnchor(superview.rightAnchor).active = true
        bottomAnchor.constraintEqualToAnchor(superview.bottomAnchor).active = true
        topAnchor.constraintEqualToAnchor(superview.topAnchor).active = true
    }
    
    
    func isMouseOver() -> Bool {
        guard let window = window else { return false }
        
        let mouseLocationInWindow = window.mouseLocationOutsideOfEventStream
        let mouseLocationInView = convertPoint(mouseLocationInWindow, fromView: nil)
        let isMouseOverCurrentView = mouse(mouseLocationInView, inRect: bounds)
        
        return isMouseOverCurrentView;
    }
}