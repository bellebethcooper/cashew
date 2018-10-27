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
    let expiresOn: Date?
    
    required init(cacheObject: T, expiresOn: Date?) {
        self.cacheObject = cacheObject
        self.expiresOn = expiresOn
        super.init()
    }
}

class BaseCache<T>: NSObject {
    
    fileprivate let cache = NSCache<AnyObject, AnyObject>()
    fileprivate let accessQueue = DispatchQueue(label: "co.cashewapp.BaseCache.accessQueue", attributes: DispatchQueue.Attributes.concurrent)
    
    required init(countLimit: Int) {
        super.init()
        cache.countLimit = countLimit
    }
    
    func fetch(_ key: String, expiresOn: Date?, fetcher: ( () -> T? )) -> T? {
        
        var existingEntry: BaseCacheEntry<T>?
        
        accessQueue.sync {
            if let entry = self.cache.object(forKey: key as AnyObject) as? BaseCacheEntry<T> {
                existingEntry = entry
            } else {
                existingEntry = nil
            }
        }
        
        if let entry = existingEntry {
            if let expiresOn = entry.expiresOn , expiresOn.compare(Date()) == .orderedDescending {
                let val = fetcher()
                if let val = val {
                    let entry = BaseCacheEntry<T>(cacheObject: val, expiresOn: expiresOn)
                    accessQueue.sync(flags: .barrier, execute: {
                        self.cache.setObject(entry, forKey: key as AnyObject)
                    }) 
                }
                return val
            } else {
                return entry.cacheObject
            }
        } else {
            let val = fetcher()
            if let val = val {
                let entry = BaseCacheEntry<T>(cacheObject: val, expiresOn: expiresOn)
                accessQueue.sync(flags: .barrier, execute: {
                    self.cache.setObject(entry, forKey: key as AnyObject)
                }) 
            }
            return val
        }
    }
    
    func fetch(_ key: String, fetcher: ( () -> T? )) -> T? {
        return fetch(key, expiresOn: nil, fetcher: fetcher)
    }
    
    
    func set(_ value: T?, forKey key: String) {
        set(value, expiresOn: nil, forKey: key)
    }
    
    func set(_ value: T?, expiresOn: Date?, forKey key: String) {
        guard let val = value else { return }
        let entry = BaseCacheEntry<T>(cacheObject: val, expiresOn: expiresOn)
        accessQueue.sync(flags: .barrier, execute: {
            self.cache.setObject(entry, forKey: key as AnyObject)
        }) 
    }
    
    
    func removeObjectForKey(_ key: String) {
        accessQueue.sync(flags: .barrier, execute: {
            self.cache.removeObject(forKey: key as AnyObject)
        }) 
    }
    
    func removeAll() {
        accessQueue.sync(flags: .barrier, execute: {
            self.cache.removeAllObjects()
        }) 
        
    }
    
}


extension Int {
    
    var minutes: Date {
        get {
            return Date().addingTimeInterval(TimeInterval(self) * TimeInterval(60))
        }
    }
    
    var hours: Date {
        get {
            return Date().addingTimeInterval(TimeInterval(self) * TimeInterval(60 * 60))
        }
    }
    
}
