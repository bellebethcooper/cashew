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
    
    private static var __once: () = {
            _sharedCache = MilestoneCache()
        }()
    
    fileprivate static var token: Int = 0
    fileprivate static var _sharedCache: MilestoneCache?
    
    fileprivate let cache = BaseCache<QMilestone>(countLimit: 1000)
    
    @objc class func sharedCache() -> MilestoneCache {
        _ = MilestoneCache.__once
        return _sharedCache!
    }
    
    func removeObjectForKey(_ key: String) {
        cache.removeObjectForKey(key)
    }

    @objc
    func fetch(_ key: String, fetcher: ( () -> QMilestone? )) -> QMilestone? {
        return cache.fetch(key, fetcher: fetcher)
    }
    
    @objc func removeAll() {
        cache.removeAll()
    }

    @objc
    class func MilestoneCacheKeyForAccountId(_ accountId: NSNumber, repositoryId: NSNumber, milestoneId: NSNumber) -> String {
        return "milestone_\(accountId)_\(repositoryId)_\(milestoneId)"
    }
}


