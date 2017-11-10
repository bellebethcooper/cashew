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


func DispatchOnMainQueue(block: dispatch_block_t) {
//    if NSThread.isMainThread() {
//        block()
//    } else {
//        
//    }
    dispatch_async(dispatch_get_main_queue(), block)
}

func SyncDispatchOnMainQueue(block: dispatch_block_t) {
        if NSThread.isMainThread() {
            block()
        } else {
            dispatch_sync(dispatch_get_main_queue(), block)
        }
}