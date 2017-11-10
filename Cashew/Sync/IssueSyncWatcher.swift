//
//  IssueSyncWatcher.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/21/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRIssueSyncWatcher)
class IssueSyncWatcher: NSObject {
    
    static let sharedWatcher = IssueSyncWatcher()
    
    private var deltaSyncRepos = Set<QRepository>()
    private var fullSyncRepos = Set<QRepository>()
    private let accessQueue = dispatch_queue_create("co.cashewapp.IssueSyncWatcher.accessQueue", DISPATCH_QUEUE_CONCURRENT)
    private let executionQueue = dispatch_queue_create("co.cashewapp.IssueSyncWatcher.executionQueue", DISPATCH_QUEUE_CONCURRENT)
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private override init() {
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(IssueSyncWatcher.didFinishSynching(_:)), name: kDidFinishSynchingRepositoryNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(IssueSyncWatcher.willStartSynching(_:)), name: kWillStartSynchingRepositoryNotification, object: nil)
    }
    
    func isSynchingRepository(repo: QRepository) -> Bool {
        var result = false
        dispatch_sync(accessQueue) {
            result = self.deltaSyncRepos.contains(repo) || self.fullSyncRepos.contains(repo)
        }
        return result
    }
    
    func isPartiallySynchingRepository(repo: QRepository) -> Bool {
        var result = false
        dispatch_sync(accessQueue) {
            result = self.deltaSyncRepos.contains(repo)
        }
        return result
    }
    
    func isFullySynchingRepository(repo: QRepository) -> Bool {
        var result = false
        dispatch_sync(accessQueue) {
            result = self.fullSyncRepos.contains(repo)
        }
        return result
    }
    
    @objc
    private func willStartSynching(notfication: NSNotification) {
        dispatch_barrier_sync(accessQueue) {
            if let userInfo = notfication.userInfo, isFullSyncNumber = userInfo["isFullSync"] as? NSNumber, repo = notfication.object as? QRepository where isFullSyncNumber.boolValue == false {
                let emptySet = self.deltaSyncRepos.count == 0
                self.deltaSyncRepos.insert(repo)
                if emptySet && self.deltaSyncRepos.count == 1 {
                    dispatch_async(self.executionQueue) {
                        DDLogDebug("Start Delta Issue Syncher = \(NSDate())");
                        NSNotificationCenter.defaultCenter().postNotificationName(kWillStartDeltaIssueSynchingNotification, object: nil)
                    }
                }
            } else if let userInfo = notfication.userInfo, isFullSyncNumber = userInfo["isFullSync"] as? NSNumber, repo = notfication.object as? QRepository where isFullSyncNumber.boolValue == true {
                let emptySet = self.fullSyncRepos.count == 0
                self.fullSyncRepos.insert(repo)
                if emptySet && self.fullSyncRepos.count == 1 {
                    dispatch_async(self.executionQueue) {
                        DDLogDebug("Start Full Issue Syncher = \(NSDate())");
                        NSNotificationCenter.defaultCenter().postNotificationName(kWillStartFullIssueSynchingNotification, object: nil)
                    }
                }
            }
        }
    }
    
    @objc
    private func didFinishSynching(notfication: NSNotification) {
        dispatch_barrier_sync(accessQueue) {
            if let userInfo = notfication.userInfo, isFullSyncNumber = userInfo["isFullSync"] as? NSNumber, repo = notfication.object as? QRepository where isFullSyncNumber.boolValue == false {
                let notEmptySet = self.deltaSyncRepos.count != 0
                self.deltaSyncRepos.remove(repo)
                if notEmptySet && self.deltaSyncRepos.count == 0 {
                    dispatch_async(self.executionQueue) {
                        DDLogDebug("End Delta Issue Syncher = \(NSDate())");
                        NSNotificationCenter.defaultCenter().postNotificationName(kDidFinishDeltaIssueSynchingNotification, object: nil)
                    }
                }
            } else if let userInfo = notfication.userInfo, isFullSyncNumber = userInfo["isFullSync"] as? NSNumber, repo = notfication.object as? QRepository where isFullSyncNumber.boolValue == true {
                let notEmptySet = self.fullSyncRepos.count != 0
                self.fullSyncRepos.remove(repo)
                if notEmptySet && self.fullSyncRepos.count == 0 {
                    dispatch_async(self.executionQueue) {
                        DDLogDebug("End Full Issue Syncher = \(NSDate())");
                        NSNotificationCenter.defaultCenter().postNotificationName(kDidFinishFullIssueSynchingNotification, object: nil)
                    }
                }
            }
        }
    }
}
