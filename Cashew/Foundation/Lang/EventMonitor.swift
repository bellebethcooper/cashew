//
//  EventMonitor.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/11/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SREventMonitor)
class EventMonitor: NSObject {
    
    private var monitor: AnyObject?
    private let mask: NSEventMask
    private let handler: NSEvent? -> ()
    
    init(mask: NSEventMask, handler: NSEvent? -> ()) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEventsMatchingMask(mask, handler: handler)
    }
    
    func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}