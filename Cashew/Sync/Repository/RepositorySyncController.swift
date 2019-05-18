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
    
    @objc static let sharedController = RepositorySyncController()
    
//    @property (nonatomic) SRSourceListRepositorySyncer *sourceListRepositorySyncer;
//    @property (nonatomic) SRSourceListUserQuerySyncher *sourceListUserQuerySyncher;
    
    fileprivate let sourceListRepositorySyncher = SourceListRepositorySyncer()
    fileprivate let sourceListUserQuerySyncher = SourceListUserQuerySyncher()
    
    fileprivate let operationQueue = OperationQueue()
    fileprivate var timer: Timer?
    fileprivate let controllerAccessQueue = DispatchQueue(label: "co.cashewapp.RepositorySyncController.controllerAccessQueue", attributes: [])
    
    fileprivate var repositoryOperations = [QRepository: Operation]()
    fileprivate let accessQueue = DispatchQueue(label: "co.cashewapp.RepositorySyncController.accessQueue", attributes: [])
    
    fileprivate let totalSyncsAccessQueue = DispatchQueue(label: "co.cashewapp.RepositorySyncController.totalSyncsAccessQueue", attributes: [])
    fileprivate var totalSyncs: UInt = 0
    
    deinit {
        QRepositoryStore.remove(self)
        QAccountStore.remove(self)
    }
    
    fileprivate override init() {
        super.init()
        
        QRepositoryStore.add(self)
        QAccountStore.add(self)
        
        operationQueue.isSuspended = true
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.underlyingQueue = DispatchQueue(label: "co.cashewapp.RepositorySyncController.operationQueue", attributes: DispatchQueue.Attributes.concurrent)
    }
    
    @objc func start(_ forced: Bool) {
        controllerAccessQueue.sync { [weak self] in
            // bail out if queue already running
            guard let strongSelf = self else { return }
            
            if strongSelf.operationQueue.isSuspended == true {
                strongSelf.operationQueue.isSuspended = false
            }
            
            if strongSelf.timer == nil {
                strongSelf.timer = Timer(timeInterval: 10 * 60, target: strongSelf, selector: #selector(RepositorySyncController.runSyncher(_:)), userInfo: nil, repeats: true)
                let interval: TimeInterval = 10
                let now = Date()
                var components = (Calendar.current as NSCalendar).components([.era, .year, .month, .day, .hour, .minute, .second], from: now)
                components.minute! += 1
                components.second  = 0
                let nextDate = Calendar.current.date(from: components)!
                strongSelf.timer = Timer(fireAt: nextDate, interval: interval * 60, target: strongSelf, selector: #selector(RepositorySyncController.runSyncher(_:)), userInfo: nil, repeats: true)
                // [[NSRunLoop mainRunLoop] addTimer:_syncTimer forMode:NSDefaultRunLoopMode];
                RunLoop.main.add(strongSelf.timer!, forMode: RunLoop.Mode.default)
            } else if forced {
                strongSelf.runSyncerNow(forced: forced)
            }
        }
    }
    
    @objc func stop() {
        controllerAccessQueue.sync { [weak self] in
            // bail out if queue already stopped
            guard let strongSelf = self , strongSelf.operationQueue.isSuspended == false && strongSelf.timer == nil else { return }
            
            strongSelf.operationQueue.cancelAllOperations()
            strongSelf.operationQueue.isSuspended = true
            if let timer = strongSelf.timer {
                timer.invalidate()
                strongSelf.timer = nil
            }
        }
    }
    
    
    @objc
    func runSyncher(_ timer: Timer) {
        runSyncerNow(forced: false)
    }
    
    fileprivate func runSyncerNow(forced: Bool) {
        totalSyncsAccessQueue.sync {
            let includeAllOperations = (self.totalSyncs % 3 == 0) || forced
            let accounts = QAccountStore.accounts()
            for account in accounts! {
                let repositories = QRepositoryStore.repositories(forAccountId: account.identifier)
                for repository in repositories! {
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
    
    fileprivate func syncRepository(_ repository: QRepository, includeAllOperations: Bool) {
        accessQueue.sync {
            guard self.repositoryOperations[repository] == nil else { return }
            let isFullSync: NSNumber = NSNumber(value: !repository.initialSyncCompleted)
            
            let issueSyncOperation = RepositoryIssueSyncOperation(repository: repository)
            self.repositoryOperations[repository] = issueSyncOperation
            
            issueSyncOperation.completionBlock = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.accessQueue.sync {
                    strongSelf.repositoryOperations[repository] = nil
                    
                    if QAccountStore.isDeletedAccount(repository.account) {
                        QAccountStore.deleteAccount(repository.account)
                        
                    } else if QRepositoryStore.isDeletedRepository(repository) {
                        QRepositoryStore.delete(repository)
                    }
                    NotificationCenter.default.post(name: NSNotification.Name.didFinishSynchingRepository, object: repository, userInfo: ["isFullSync" : isFullSync])
                }
            }
            
            NotificationCenter.default.post(name: NSNotification.Name.willStartSynchingRepository, object: repository, userInfo: ["isFullSync" : isFullSync])
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
    
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {
        
        if let record = record as? QRepository , store == QRepositoryStore.self {
            syncRepository(record, includeAllOperations: true)
        }
    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {
        
        if let record = record as? QRepository , store == QRepositoryStore.self {
            self.accessQueue.sync {
                guard let operation = self.repositoryOperations[record] else { return }
                operation.cancel()
            }
            
        } else if let record = record as? QAccount , store == QAccountStore.self {
            (self.accessQueue).sync {
                self.repositoryOperations.forEach({ (repository, operation) in
                    if repository.account == record {
                        operation.cancel()
                    }
                })
            }
        }
    }
}
