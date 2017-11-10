//
//  BaseCache.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/26/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

private class BaseCacheEntry<T>: NSObject {
    let cacheObject: T
    let expiresOn: NSDate?
    
    required init(cacheObject: T, expiresOn: NSDate?) {
        self.cacheObject = cacheObject
        self.expiresOn = expiresOn
        super.init()
    }
}

class BaseCache<T>: NSObject {
    
    private let cache = NSCache()
    private let accessQueue = dispatch_queue_create("co.cashewapp.BaseCache.accessQueue", DISPATCH_QUEUE_CONCURRENT)
    
    required init(countLimit: Int) {
        super.init()
        cache.countLimit = countLimit
    }
    
    func fetch(key: String, expiresOn: NSDate?, fetcher: ( () -> T? )) -> T? {
        
        var existingEntry: BaseCacheEntry<T>?
        
        dispatch_sync(accessQueue) {
            if let entry = self.cache.objectForKey(key) as? BaseCacheEntry<T> {
                existingEntry = entry
            } else {
                existingEntry = nil
            }
        }
        
        if let entry = existingEntry {
            if let expiresOn = entry.expiresOn where expiresOn.compare(NSDate()) == .OrderedDescending {
                let val = fetcher()
                if let val = val {
                    let entry = BaseCacheEntry<T>(cacheObject: val, expiresOn: expiresOn)
                    dispatch_barrier_sync(accessQueue) {
                        self.cache.setObject(entry, forKey: key)
                    }
                }
                return val
            } else {
                return entry.cacheObject
            }
        } else {
            let val = fetcher()
            if let val = val {
                let entry = BaseCacheEntry<T>(cacheObject: val, expiresOn: expiresOn)
                dispatch_barrier_sync(accessQueue) {
                    self.cache.setObject(entry, forKey: key)
                }
            }
            return val
        }
    }
    
    func fetch(key: String, fetcher: ( () -> T? )) -> T? {
        return fetch(key, expiresOn: nil, fetcher: fetcher)
    }
    
    
    func set(value: T?, forKey key: String) {
        set(value, expiresOn: nil, forKey: key)
    }
    
    func set(value: T?, expiresOn: NSDate?, forKey key: String) {
        guard let val = value else { return }
        let entry = BaseCacheEntry<T>(cacheObject: val, expiresOn: expiresOn)
        dispatch_barrier_sync(accessQueue) {
            self.cache.setObject(entry, forKey: key)
        }
    }
    
    
    func removeObjectForKey(key: String) {
        dispatch_barrier_sync(accessQueue) {
            self.cache.removeObjectForKey(key)
        }
    }
    
    func removeAll() {
        dispatch_barrier_sync(accessQueue) {
            self.cache.removeAllObjects()
        }
        
    }
    
}


extension Int {
    
    var minutes: NSDate {
        get {
            return NSDate().dateByAddingTimeInterval(NSTimeInterval(self) * NSTimeInterval(60))
        }
    }
    
    var hours: NSDate {
        get {
            return NSDate().dateByAddingTimeInterval(NSTimeInterval(self) * NSTimeInterval(60 * 60))
        }
    }
    
}
