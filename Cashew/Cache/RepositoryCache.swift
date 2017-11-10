//
//  RepositoryCache.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/26/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

@objc(SRRepositoryCache)
class RepositoryCache: NSObject {

    private static var token: dispatch_once_t = 0
    private static var _sharedCache: RepositoryCache?
    
    private let cache = BaseCache<QRepository>(countLimit: 1000)
    
    class func sharedCache() -> RepositoryCache {
        dispatch_once(&token) {
            _sharedCache = RepositoryCache()
        }
        return _sharedCache!
    }
    
    func removeObjectForKey(key: String) {
        cache.removeObjectForKey(key)
    }
    
    func fetch(key: String, fetcher: ( () -> QRepository? )) -> QRepository? {
        return cache.fetch(key, fetcher: fetcher)
    }
    
    func removeAll() {
        cache.removeAll()
    }
    
    class func RepositoryCacheKeyForAccountId(accountId: NSNumber, repositoryId: NSNumber) -> String {
        return "repository_\(accountId)_\(repositoryId)"
    }
    
}
