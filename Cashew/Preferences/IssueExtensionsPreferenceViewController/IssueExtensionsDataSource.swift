//
//  IssueExtensionsDataSource.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/1/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class IssueExtensionsDataSource: NSObject {
    
    private var extensions = [SRExtension]()
    private var accessQueue = dispatch_queue_create("co.cashewapp.ISsueExtensionsDataSource.accessQueue", DISPATCH_QUEUE_CONCURRENT)
    
    
    var onRecordUpdate: ( (codeExtension: SRExtension, index: Int) -> Void )?
    var onRecordDeletion: ( (codeExtension: SRExtension, index: Int) -> Void )?
    var onRecordInsertion: ( (codeExtension: SRExtension, index: Int) -> Void )?
    
    deinit {
        SRExtensionStore.removeObserver(self)
    }
    
    override init() {
        super.init()
        SRExtensionStore.addObserver(self)
    }
    
    func reloadData(onCompletion: dispatch_block_t) {
        //service.syncCodeExtensions { [weak self] (extensions, err) in
        //guard let strongSelf = self else { return }
        dispatch_barrier_sync(self.accessQueue, {
            self.extensions = SRExtensionStore.extensionsForType(SRExtensionTypeIssue)
        })
        onCompletion()
        //}
    }
    
    var numberOfRows: Int {
        get {
            var count: Int = 0
            dispatch_sync(accessQueue) {
                count = self.extensions.count
            }
            return count
        }
    }
    
    func itemAtIndex(index: Int) -> SRExtension {
        var item: SRExtension?
        dispatch_sync(accessQueue) {
            item = self.extensions[index]
        }
        return item!
    }
}


extension IssueExtensionsDataSource: QStoreObserver {
    
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {
        guard let record = record as? SRExtension where store == SRExtensionStore.self else { return }
        dispatch_barrier_sync(self.accessQueue, {
            let index = self.extensions.insertionIndexOf(record, isOrderedBefore: { (record1, record2) -> Bool in
                return record1.name.lowercaseString < record2.name.lowercaseString
            })
            self.extensions.insert(record, atIndex: index)
            if let onRecordInsertion = self.onRecordInsertion {
                onRecordInsertion(codeExtension: record, index: index)
            }
        })
        
    }
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {
        guard let record = record as? SRExtension where store == SRExtensionStore.self else { return }
        dispatch_barrier_sync(self.accessQueue, {
            if let index = self.extensions.indexOf(record) {
                self.extensions.removeAtIndex(index)
                if let onRecordDeletion = self.onRecordDeletion {
                    onRecordDeletion(codeExtension: record, index: index)
                }
            }
        })
    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        guard let record = record as? SRExtension where store == SRExtensionStore.self else { return }
        dispatch_barrier_sync(self.accessQueue, {
            if let index = self.extensions.indexOf(record) {
                self.extensions[index] = record
                if let onRecordUpdate = self.onRecordUpdate {
                    onRecordUpdate(codeExtension: record, index: index)
                }
            }
        })
    }
}