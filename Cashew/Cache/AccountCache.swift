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
    
    private static var token: dispatch_once_t = 0
    private static var _sharedCache: AccountCache?
    
    private let cache = BaseCache<QAccount>(countLimit: 1000)
    
    class func sharedCache() -> AccountCache {
        dispatch_once(&token) {
            _sharedCache = AccountCache()
        }
        return _sharedCache!
    }
    
    func removeObjectForKey(key: String) {
        cache.removeObjectForKey(key)
    }
    
    func fetch(key: String, fetcher: ( () -> QAccount? )) -> QAccount? {
        return cache.fetch(key, fetcher: fetcher)
    }
    
    func removeAll() {
        cache.removeAll()
    }
    
    class func AccountCacheKeyForAccountId(accountId: NSNumber) -> String {
        return "account_\(accountId)"
    }
    
}
