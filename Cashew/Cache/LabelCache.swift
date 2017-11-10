//
//  LabelCache.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/26/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

@objc(SRLabelCache)
class LabelCache: NSObject {
    
    private static var token: dispatch_once_t = 0
    private static var _sharedCache: LabelCache?
    
    private let cache = BaseCache<QLabel>(countLimit: 1000)
    
    class func sharedCache() -> LabelCache {
        dispatch_once(&token) {
            _sharedCache = LabelCache()
        }
        return _sharedCache!
    }
    
    func removeAll() {
        cache.removeAll()
    }
    
    func fetch(key: String, fetcher: ( () -> QLabel? )) -> QLabel? {
        return cache.fetch(key, fetcher: fetcher)
    }
    
    func set(value: QLabel, forKey key: String) {
        cache.set(value, forKey: key)
    }
    
    class func LabelCacheKeyForAccountId(accountId: NSNumber, repositoryId: NSNumber, name: NSString) -> NSString {
        return "label_\(accountId)_\(repositoryId)_\(name)"
    }
    
}

