//
//  RepositoryBaseSyncOperation.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class RepositoryBaseSyncOperation: NSOperation {

    static let pageSize = 100
    static let maxRateLimit = 3000
    
    
    func sleepIfNeededWithContext(context: QServiceResponseContext) {
        if let sleepSeconds = context.nextRateLimitResetDate?.timeIntervalSinceNow, rateLimitRemaining = context.rateLimitRemaining?.integerValue where rateLimitRemaining < RepositoryBaseSyncOperation.maxRateLimit && sleepSeconds > 0 {
            DDLogDebug("Sleeping for \(sleepSeconds) due to rate limit")
            NSThread.sleepForTimeInterval(sleepSeconds)
        }
    }

}
