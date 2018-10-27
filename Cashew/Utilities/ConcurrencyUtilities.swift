//
//  Concurrency+Utilities.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/3/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class ConcurrencyUtilities: NSObject {

}


func DispatchOnMainQueue(_ block: @escaping ()->()) {
//    if NSThread.isMainThread() {
//        block()
//    } else {
//        
//    }
    DispatchQueue.main.async(execute: block)
}

func SyncDispatchOnMainQueue(_ block: ()->()) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync(execute: block)
        }
}
