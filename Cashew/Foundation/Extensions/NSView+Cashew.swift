//
//  NSView+Cashew.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


extension NSView {
    
    @objc public func pinAnchorsToSuperview() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
        topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
    }
    
    
    func isMouseOver() -> Bool {
        guard let window = window else { return false }
        
        let mouseLocationInWindow = window.mouseLocationOutsideOfEventStream
        let mouseLocationInView = convert(mouseLocationInWindow, from: nil)
        let isMouseOverCurrentView = isMousePoint(mouseLocationInView, in: bounds)
        
        return isMouseOverCurrentView;
    }
}
