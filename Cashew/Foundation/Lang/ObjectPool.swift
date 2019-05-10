//
//  ObjectPool.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class ObjectPool<T>: NSObject {
    
    fileprivate let accessQueue = DispatchQueue(label: "co.hellocode.cashew.ObjectPool", attributes: [])
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
//            DDLogDebug("ObjectPool borrowObject - inside queue sync")
            let lastObject = self.data.lastObject as? T
            if let lastObject = lastObject {
//                DDLogDebug("ObjectPool borrowObject - unwrapped lastObject")
                self.data.remove(lastObject)
                object = lastObject
//                DDLogDebug("ObjectPool borrowObject - object is now lastObj: \(object)")
            } else {
                object = self.createObject()
//                DDLogDebug("ObjectPool borrowObject - just created new obj: \(object)")
            }
        }
//        DDLogDebug("ObjectPool borrowObject - after queue sync, willBorrowObj: \(willBorrowObject), obj: \(object)")
        if let preBorrow = willBorrowObject,
            let object = object {
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

            self.data.add(object)
        }
    }
}
