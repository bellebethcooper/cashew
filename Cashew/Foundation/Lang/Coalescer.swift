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
    
    fileprivate var timer: Timer?
    fileprivate var interval: TimeInterval?
    fileprivate var block: (()->())?
    fileprivate let accessQueue: DispatchQueue
    fileprivate let executionQueue: DispatchQueue
    
    @objc required init(interval: TimeInterval, name: String, executionQueue: DispatchQueue = DispatchQueue.main) {
        self.accessQueue = DispatchQueue(label: name, attributes: [])
        self.interval = interval
        self.executionQueue = executionQueue
        super.init()
    }
    
    @objc func executeBlock(_ block: @escaping ()->()) {
        guard let interval = interval else {
            fatalError()
        }
        
        accessQueue.async {
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
            }
            
            self.block = block
            DispatchOnMainQueue {
                self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(Coalescer.fire(_:)), userInfo: nil, repeats: false)
            }
        }
        
    }
    
    @objc
    func fire(_ timer: Timer) {
        accessQueue.async {
            if let aTimer = self.timer , timer == aTimer {
                aTimer.invalidate()
                self.timer = nil
            } else {
                return
            }
            if let block = self.block {
                self.executionQueue.async(execute: block)
            }
        }
    }
    
}
