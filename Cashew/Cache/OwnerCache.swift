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
    
    private static var __once: () = {
            _sharedCache = OwnerCache()
        }()
    
    fileprivate static var token: Int = 0
    fileprivate static var _sharedCache: OwnerCache?
    
    fileprivate let cache = BaseCache<QOwner>(countLimit: 1000)
    
    @objc class func sharedCache() -> OwnerCache {
        _ = OwnerCache.__once
        return _sharedCache!
    }
    
    @objc func removeObjectForKey(_ key: String) {
        cache.removeObjectForKey(key)
    }
    
    @objc func fetch(_ key: String, fetcher: ( () -> QOwner? )) -> QOwner? {
        return cache.fetch(key, fetcher: fetcher)
    }
    
    @objc func removeAll() {
        cache.removeAll()
    }
    
    @objc class func OwnerCacheKeyForAccountId(_ accountId: NSNumber, ownerId: NSNumber) -> String {
        return "owner_\(accountId)_\(ownerId)"
    }
    
}

