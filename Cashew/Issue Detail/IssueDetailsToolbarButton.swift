//
//  IssueDetailsToolbarButton.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/28/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class IssueDetailsToolbarButton: BaseView {
    fileprivate var cursorTrackingArea: NSTrackingArea?
    
    var enabled = true
    
    override func updateTrackingAreas() {
        if let cursorTrackingArea = cursorTrackingArea {
            removeTrackingArea(cursorTrackingArea)
        }
        
        guard enabled  else { return }
        
        let trackingArea = NSTrackingArea(rect: bounds, options: [NSTrackingArea.Options.cursorUpdate, NSTrackingArea.Options.activeAlways] , owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea);
        self.cursorTrackingArea = trackingArea
    }
    
    override func cursorUpdate(with event: NSEvent) {
        guard enabled else { return }
        NSCursor.pointingHand.set()
    }
    
    override func awakeFromNib() {
        setup()
    }
    
    fileprivate func setup() {
//        borderColor = NSColor(calibratedWhite: 103/255.0, alpha: 1)
//        cornerRadius = 3
    }
}
