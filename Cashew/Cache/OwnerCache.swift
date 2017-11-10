//
//  OwnerCache.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/26/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

@objc(SROwnerCache)
class OwnerCache: NSObject {
    
    private static var token: dispatch_once_t = 0
    private static var _sharedCache: OwnerCache?
    
    private let cache = BaseCache<QOwner>(countLimit: 1000)
    
    class func sharedCache() -> OwnerCache {
        dispatch_once(&token) {
            _sharedCache = OwnerCache()
        }
        return _sharedCache!
    }
    
    func removeObjectForKey(key: String) {
        cache.removeObjectForKey(key)
    }
    
    func fetch(key: String, fetcher: ( () -> QOwner? )) -> QOwner? {
        return cache.fetch(key, fetcher: fetcher)
    }
    
    func removeAll() {
        cache.removeAll()
    }
    
    class func OwnerCacheKeyForAccountId(accountId: NSNumber, ownerId: NSNumber) -> String {
        return "owner_\(accountId)_\(ownerId)"
    }
    
}

