//
//  RepositoryBaseSyncOperation.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class RepositoryBaseSyncOperation: Operation {

    static let pageSize = 100
    static let maxRateLimit = 3000
    
    
    func sleepIfNeededWithContext(_ context: QServiceResponseContext) {
        if let sleepSeconds = context.nextRateLimitResetDate?.timeIntervalSinceNow, let rateLimitRemaining = context.rateLimitRemaining?.intValue , rateLimitRemaining < RepositoryBaseSyncOperation.maxRateLimit && sleepSeconds > 0 {
            DDLogDebug("Sleeping for \(sleepSeconds) due to rate limit")
            Thread.sleep(forTimeInterval: sleepSeconds)
        }
    }

}
