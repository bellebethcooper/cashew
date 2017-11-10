//
//  ObjectPool.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class ObjectPool<T>: NSObject {
    
    private let accessQueue = dispatch_queue_create("com.simplerocket.Issues.ObjectPool", DISPATCH_QUEUE_SERIAL)
    private var data = NSMutableOrderedSet()
    private let createObject: (() -> T)
    
    var willReturnObject: ((T) -> ())?
    var willBorrowObject: ((T) -> ())?
    
    required init(createObject aBlock: (() -> T)) {
        createObject = aBlock
    }
    
    func borrowObject() -> T {
        var object: T?
        dispatch_sync(accessQueue) {
            let lastObject = self.data.lastObject as? T
            if let lastObject = lastObject as? AnyObject {
                self.data.removeObject(lastObject)
                object = lastObject as? T
            } else {
                object = self.createObject()
            }
        }
        
        if let preBorrow = willBorrowObject, object = object {
            preBorrow(object)
            return object
        }
        
        fatalError()
    }
    
    func returnObject(object: T) {
        dispatch_sync(accessQueue) {
            if let preReturn = self.willReturnObject {
                preReturn(object)
            }
            if let object = object as? AnyObject {
                self.data.addObject(object)
            }
        }
    }
}
