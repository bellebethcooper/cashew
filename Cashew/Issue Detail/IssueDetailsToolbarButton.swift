//
//  IssueDetailsToolbarButton.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/28/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class IssueDetailsToolbarButton: BaseView {
    private var cursorTrackingArea: NSTrackingArea?
    
    var enabled = true
    
    override func updateTrackingAreas() {
        if let cursorTrackingArea = cursorTrackingArea {
            removeTrackingArea(cursorTrackingArea)
        }
        
        guard enabled  else { return }
        
        let trackingArea = NSTrackingArea(rect: bounds, options: [.CursorUpdate, .ActiveAlways] , owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea);
        self.cursorTrackingArea = trackingArea
    }
    
    override func cursorUpdate(event: NSEvent) {
        guard enabled else { return }
        NSCursor.pointingHandCursor().set()
    }
    
    override func awakeFromNib() {
        setup()
    }
    
    private func setup() {
//        borderColor = NSColor(calibratedWhite: 103/255.0, alpha: 1)
//        cornerRadius = 3
    }
}
