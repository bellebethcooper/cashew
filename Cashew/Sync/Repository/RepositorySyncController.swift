//
//  RepositorySyncController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRRepositorySyncController)
class RepositorySyncController: NSObject {
    
    static let sharedController = RepositorySyncController()
    
//    @property (nonatomic) SRSourceListRepositorySyncer *sourceListRepositorySyncer;
//    @property (nonatomic) SRSourceListUserQuerySyncher *sourceListUserQuerySyncher;
    
    private let sourceListRepositorySyncher = SourceListRepositorySyncer()
    private let sourceListUserQuerySyncher = SourceListUserQuerySyncher()
    
    private let operationQueue = NSOperationQueue()
    private var timer: NSTimer?
    private let controllerAccessQueue = dispatch_queue_create("co.cashewapp.RepositorySyncController.controllerAccessQueue", DISPATCH_QUEUE_SERIAL)
    
    private var repositoryOperations = [QRepository: NSOperation]()
    private let accessQueue = dispatch_queue_create("co.cashewapp.RepositorySyncController.accessQueue", DISPATCH_QUEUE_SERIAL)
    
    private let totalSyncsAccessQueue = dispatch_queue_create("co.cashewapp.RepositorySyncController.totalSyncsAccessQueue", DISPATCH_QUEUE_SERIAL)
    private var totalSyncs: UInt = 0
    
    deinit {
        QRepositoryStore.removeObserver(self)
        QAccountStore.removeObserver(self)
    }
    
    private override init() {
        super.init()
        
        QRepositoryStore.addObserver(self)
        QAccountStore.addObserver(self)
        
        operationQueue.suspended = true
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.underlyingQueue = dispatch_queue_create("co.cashewapp.RepositorySyncController.operationQueue", DISPATCH_QUEUE_CONCURRENT)
    }
    
    func start(forced: Bool) {
        dispatch_sync(controllerAccessQueue) { [weak self] in
            // bail out if queue already running
            guard let strongSelf = self else { return }
            
            if strongSelf.operationQueue.suspended == true {
                strongSelf.operationQueue.suspended = false
            }
            
            if strongSelf.timer == nil {
                strongSelf.timer = NSTimer(timeInterval: 10 * 60, target: strongSelf, selector: #selector(RepositorySyncController.runSyncher(_:)), userInfo: nil, repeats: true)
                let interval: NSTimeInterval = 10
                let now = NSDate()
                let components = NSCalendar.currentCalendar().components([.Era, .Year, .Month, .Day, .Hour, .Minute, .Second], fromDate: now)
                components.minute += 1
                components.second  = 0
                let nextDate = NSCalendar.currentCalendar().dateFromComponents(components)!
                strongSelf.timer = NSTimer(fireDate: nextDate, interval: interval * 60, target: strongSelf, selector: #selector(RepositorySyncController.runSyncher(_:)), userInfo: nil, repeats: true)
                // [[NSRunLoop mainRunLoop] addTimer:_syncTimer forMode:NSDefaultRunLoopMode];
                NSRunLoop.mainRunLoop().addTimer(strongSelf.timer!, forMode: NSDefaultRunLoopMode)
            } else if forced {
                strongSelf.runSyncerNow(forced: forced)
            }
        }
    }
    
    func stop() {
        dispatch_sync(controllerAccessQueue) { [weak self] in
            // bail out if queue already stopped
            guard let strongSelf = self where strongSelf.operationQueue.suspended == false && strongSelf.timer == nil else { return }
            
            strongSelf.operationQueue.cancelAllOperations()
            strongSelf.operationQueue.suspended = true
            if let timer = strongSelf.timer {
                timer.invalidate()
                strongSelf.timer = nil
            }
        }
    }
    
    
    @objc
    func runSyncher(timer: NSTimer) {
        runSyncerNow(forced: false)
    }
    
    private func runSyncerNow(forced forced: Bool) {
        dispatch_sync(totalSyncsAccessQueue) {
            let includeAllOperations = (self.totalSyncs % 3 == 0) || forced
            let accounts = QAccountStore.accounts()
            for account in accounts {
                let repositories = QRepositoryStore.repositoriesForAccountId(account.identifier)
                for repository in repositories {
                    self.syncRepository(repository, includeAllOperations: includeAllOperations)
                }
            }
            
            self.totalSyncs += 1
            
            if self.totalSyncs == UInt.max {
                self.totalSyncs = 0
            }
        }
        //self.operationQueue.waitUntilAllOperationsAreFinished()
        sourceListRepositorySyncher.sync()
        sourceListUserQuerySyncher.sync()
    }
    
    private func syncRepository(repository: QRepository, includeAllOperations: Bool) {
        dispatch_sync(accessQueue) {
            guard self.repositoryOperations[repository] == nil else { return }
            let isFullSync: NSNumber = NSNumber(bool: !repository.initialSyncCompleted)
            
            let issueSyncOperation = RepositoryIssueSyncOperation(repository: repository)
            self.repositoryOperations[repository] = issueSyncOperation
            
            issueSyncOperation.completionBlock = { [weak self] in
                guard let strongSelf = self else { return }
                dispatch_sync(strongSelf.accessQueue) {
                    strongSelf.repositoryOperations[repository] = nil
                    
                    if QAccountStore.isDeletedAccount(repository.account) {
                        QAccountStore.deleteAccount(repository.account)
                        
                    } else if QRepositoryStore.isDeletedRepository(repository) {
                        QRepositoryStore.deleteRepository(repository)
                    }
                    NSNotificationCenter.defaultCenter().postNotificationName(kDidFinishSynchingRepositoryNotification, object: repository, userInfo: ["isFullSync" : isFullSync])
                }
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName(kWillStartSynchingRepositoryNotification, object: repository, userInfo: ["isFullSync" : isFullSync])
            if includeAllOperations {
                let milestoneOperation = RepositoryMilestoneSyncOperation(repository: repository)
                let labelOperation = RepositoryLabelsSyncOperation(repository: repository)
                let assigneeOperation = RepositoryAssigneeSyncOperation(repository: repository)
                
                issueSyncOperation.addDependency(milestoneOperation)
                issueSyncOperation.addDependency(labelOperation)
                issueSyncOperation.addDependency(assigneeOperation)
                
                self.operationQueue.addOperations([milestoneOperation, labelOperation, assigneeOperation, issueSyncOperation], waitUntilFinished: false)
            } else {
                self.operationQueue.addOperation(issueSyncOperation)
            }

        }
    }
    
    
}

extension RepositorySyncController: QStoreObserver {
    
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {
        
        if let record = record as? QRepository where store == QRepositoryStore.self {
            syncRepository(record, includeAllOperations: true)
        }
    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        
    }
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {
        
        if let record = record as? QRepository where store == QRepositoryStore.self {
            dispatch_sync(self.accessQueue) {
                guard let operation = self.repositoryOperations[record] else { return }
                operation.cancel()
            }
            
        } else if let record = record as? QAccount where store == QAccountStore.self {
            dispatch_sync(self.accessQueue) {
                self.repositoryOperations.forEach({ (repository, operation) in
                    if repository.account == record {
                        operation.cancel()
                    }
                })
            }
        }
    }
}
