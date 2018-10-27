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
    
    private static var __once: () = {
            _sharedCache = LabelCache()
        }()
    
    fileprivate static var token: Int = 0
    fileprivate static var _sharedCache: LabelCache?
    
    fileprivate let cache = BaseCache<QLabel>(countLimit: 1000)
    
    class func sharedCache() -> LabelCache {
        _ = LabelCache.__once
        return _sharedCache!
    }
    
    func removeAll() {
        cache.removeAll()
    }
    
    func fetch(_ key: String, fetcher: ( () -> QLabel? )) -> QLabel? {
        return cache.fetch(key, fetcher: fetcher)
    }
    
    func set(_ value: QLabel, forKey key: String) {
        cache.set(value, forKey: key)
    }
    
    class func LabelCacheKeyForAccountId(_ accountId: NSNumber, repositoryId: NSNumber, name: NSString) -> NSString {
        return "label_\(accountId)_\(repositoryId)_\(name)" as NSString
    }
    
}

