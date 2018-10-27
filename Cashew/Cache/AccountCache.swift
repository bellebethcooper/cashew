//
//  AccountCache.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/26/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

@objc(SRAccountCache)
class AccountCache: NSObject {
    
    private static var __once: () = {
            _sharedCache = AccountCache()
        }()
    
    fileprivate static var token: Int = 0
    fileprivate static var _sharedCache: AccountCache?
    
    fileprivate let cache = BaseCache<QAccount>(countLimit: 1000)
    
    class func sharedCache() -> AccountCache {
        _ = AccountCache.__once
        return _sharedCache!
    }
    
    func removeObjectForKey(_ key: String) {
        cache.removeObjectForKey(key)
    }
    
    func fetch(_ key: String, fetcher: ( () -> QAccount? )) -> QAccount? {
        return cache.fetch(key, fetcher: fetcher)
    }
    
    func removeAll() {
        cache.removeAll()
    }
    
    class func AccountCacheKeyForAccountId(_ accountId: NSNumber) -> String {
        return "account_\(accountId)"
    }
    
}
