//
//  ObjectPool.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class ObjectPool<T>: NSObject {
    
    fileprivate let accessQueue = DispatchQueue(label: "com.simplerocket.Issues.ObjectPool", attributes: [])
    fileprivate var data = NSMutableOrderedSet()
    fileprivate let createObject: (() -> T)
    
    var willReturnObject: ((T) -> ())?
    var willBorrowObject: ((T) -> ())?
    
    required init(createObject aBlock: @escaping (() -> T)) {
        createObject = aBlock
    }
    
    func borrowObject() -> T {
        var object: T?
        accessQueue.sync {
            let lastObject = self.data.lastObject as? T
            if let lastObject = lastObject as? AnyObject {
                self.data.remove(lastObject)
                object = lastObject as? T
            } else {
                object = self.createObject()
            }
        }
        
        if let preBorrow = willBorrowObject, let object = object {
            preBorrow(object)
            return object
        }
        
        fatalError()
    }
    
    func returnObject(_ object: T) {
        accessQueue.sync {
            if let preReturn = self.willReturnObject {
                preReturn(object)
            }
            if let object = object as? AnyObject {
                self.data.add(object)
            }
        }
    }
}
