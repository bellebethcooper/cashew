//
//  IssueSyncWatcher.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/21/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import os.log

@objc(SRIssueSyncWatcher)
class IssueSyncWatcher: NSObject {
    
    @objc static let sharedWatcher = IssueSyncWatcher()
    
    fileprivate var deltaSyncRepos = Set<QRepository>()
    fileprivate var fullSyncRepos = Set<QRepository>()
    fileprivate let accessQueue = DispatchQueue(label: "co.cashewapp.IssueSyncWatcher.accessQueue", attributes: DispatchQueue.Attributes.concurrent)
    fileprivate let executionQueue = DispatchQueue(label: "co.cashewapp.IssueSyncWatcher.executionQueue", attributes: DispatchQueue.Attributes.concurrent)
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(IssueSyncWatcher.didFinishSynching(_:)), name: NSNotification.Name.didFinishSynchingRepository, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(IssueSyncWatcher.willStartSynching(_:)), name: NSNotification.Name.willStartSynchingRepository, object: nil)
    }
    
    func isSynchingRepository(_ repo: QRepository) -> Bool {
        var result = false
        (accessQueue).sync {
            result = self.deltaSyncRepos.contains(repo) || self.fullSyncRepos.contains(repo)
        }
        return result
    }
    
    func isPartiallySynchingRepository(_ repo: QRepository) -> Bool {
        var result = false
        (accessQueue).sync {
            result = self.deltaSyncRepos.contains(repo)
        }
        return result
    }
    
    func isFullySynchingRepository(_ repo: QRepository) -> Bool {
        var result = false
        (accessQueue).sync {
            result = self.fullSyncRepos.contains(repo)
        }
        return result
    }
    
    @objc
    fileprivate func willStartSynching(_ notfication: Notification) {
        accessQueue.sync(flags: .barrier, execute: {
            if let userInfo = (notfication as NSNotification).userInfo, let isFullSyncNumber = userInfo["isFullSync"] as? NSNumber, let repo = notfication.object as? QRepository , isFullSyncNumber.boolValue == false {
                let emptySet = self.deltaSyncRepos.count == 0
                self.deltaSyncRepos.insert(repo)
                if emptySet && self.deltaSyncRepos.count == 1 {
                    self.executionQueue.async {
                        os_log("Start Delta Issue Syncher = %@", log: .default, type: .debug, Date().toFullDateString())
                        NotificationCenter.default.post(name: NSNotification.Name.willStartDeltaIssueSynching, object: nil)
                    }
                }
            } else if let userInfo = (notfication as NSNotification).userInfo, let isFullSyncNumber = userInfo["isFullSync"] as? NSNumber, let repo = notfication.object as? QRepository , isFullSyncNumber.boolValue == true {
                let emptySet = self.fullSyncRepos.count == 0
                self.fullSyncRepos.insert(repo)
                if emptySet && self.fullSyncRepos.count == 1 {
                    self.executionQueue.async {
                        os_log("Start Full Issue Syncher = %@", log: .default, type: .debug, Date().toFullDateString())
                        NotificationCenter.default.post(name: NSNotification.Name.willStartFullIssueSynching, object: nil)
                    }
                }
            }
        }) 
    }
    
    @objc
    fileprivate func didFinishSynching(_ notfication: Notification) {
        accessQueue.sync(flags: .barrier, execute: {
            if let userInfo = (notfication as NSNotification).userInfo, let isFullSyncNumber = userInfo["isFullSync"] as? NSNumber, let repo = notfication.object as? QRepository , isFullSyncNumber.boolValue == false {
                let notEmptySet = self.deltaSyncRepos.count != 0
                self.deltaSyncRepos.remove(repo)
                if notEmptySet && self.deltaSyncRepos.count == 0 {
                    self.executionQueue.async {
                        os_log("End Delta Issue Syncher = %@", log: .default, type: .debug, Date().toFullDateString())
                        NotificationCenter.default.post(name: NSNotification.Name.didFinishDeltaIssueSynching, object: nil)
                    }
                }
            } else if let userInfo = (notfication as NSNotification).userInfo, let isFullSyncNumber = userInfo["isFullSync"] as? NSNumber, let repo = notfication.object as? QRepository , isFullSyncNumber.boolValue == true {
                let notEmptySet = self.fullSyncRepos.count != 0
                self.fullSyncRepos.remove(repo)
                if notEmptySet && self.fullSyncRepos.count == 0 {
                    self.executionQueue.async {
                        os_log("End Full Issue Syncher = %@", log: .default, type: .debug, Date().toFullDateString())
                        NotificationCenter.default.post(name: NSNotification.Name.didFinishFullIssueSynching, object: nil)
                    }
                }
            }
        }) 
    }
}
