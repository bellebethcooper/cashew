//
//  Coalescer.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/4/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRCoalescer)
class Coalescer: NSObject {
    
    private var timer: NSTimer?
    private var interval: NSTimeInterval?
    private var block: dispatch_block_t?
    private let accessQueue: dispatch_queue_t
    private let executionQueue: dispatch_queue_t
    
    required init(interval: NSTimeInterval, name: String, executionQueue: dispatch_queue_t = dispatch_get_main_queue()) {
        self.accessQueue = dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL)
        self.interval = interval
        self.executionQueue = executionQueue
        super.init()
    }
    
    func executeBlock(block: dispatch_block_t) {
        guard let interval = interval else {
            fatalError()
        }
        
        dispatch_async(accessQueue) {
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
            }
            
            self.block = block
            DispatchOnMainQueue {
                self.timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(Coalescer.fire(_:)), userInfo: nil, repeats: false)
            }
        }
        
    }
    
    @objc
    func fire(timer: NSTimer) {
        dispatch_async(accessQueue) {
            if let aTimer = self.timer where timer == aTimer {
                aTimer.invalidate()
                self.timer = nil
            } else {
                return
            }
            if let block = self.block {
                dispatch_async(self.executionQueue, block)
            }
        }
    }
    
}
