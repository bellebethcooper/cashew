//
//  MilestoneCache.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/26/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

@objc(SRMilestoneCache)
class MilestoneCache: NSObject {
    
    private static var token: dispatch_once_t = 0
    private static var _sharedCache: MilestoneCache?
    
    private let cache = BaseCache<QMilestone>(countLimit: 1000)
    
    class func sharedCache() -> MilestoneCache {
        dispatch_once(&token) {
            _sharedCache = MilestoneCache()
        }
        return _sharedCache!
    }
    
    func removeObjectForKey(key: String) {
        cache.removeObjectForKey(key)
    }
    
    func fetch(key: String, fetcher: ( () -> QMilestone? )) -> QMilestone? {
        return cache.fetch(key, fetcher: fetcher)
    }
    
    func removeAll() {
        cache.removeAll()
    }
    
    class func MilestoneCacheKeyForAccountId(accountId: NSNumber, repositoryId: NSNumber, milestoneId: NSNumber) -> String {
        return "milestone_\(accountId)_\(repositoryId)_\(milestoneId)"
    }
}


