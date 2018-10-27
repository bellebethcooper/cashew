//
//  IssueExtensionsDataSource.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/1/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class IssueExtensionsDataSource: NSObject {
    
    fileprivate var extensions = [SRExtension]()
    fileprivate var accessQueue = DispatchQueue(label: "co.cashewapp.ISsueExtensionsDataSource.accessQueue", attributes: DispatchQueue.Attributes.concurrent)
    
    
    var onRecordUpdate: ( (_ codeExtension: SRExtension, _ index: Int) -> Void )?
    var onRecordDeletion: ( (_ codeExtension: SRExtension, _ index: Int) -> Void )?
    var onRecordInsertion: ( (_ codeExtension: SRExtension, _ index: Int) -> Void )?
    
    deinit {
        SRExtensionStore.remove(self)
    }
    
    override init() {
        super.init()
        SRExtensionStore.add(self)
    }
    
    func reloadData(_ onCompletion: ()->()) {
        //service.syncCodeExtensions { [weak self] (extensions, err) in
        //guard let strongSelf = self else { return }
        (self.accessQueue).sync(flags: .barrier, execute: {
            self.extensions = SRExtensionStore.extensions(for: SRExtensionTypeIssue)
        })
        onCompletion()
        //}
    }
    
    var numberOfRows: Int {
        get {
            var count: Int = 0
            (accessQueue).sync {
                count = self.extensions.count
            }
            return count
        }
    }
    
    func itemAtIndex(_ index: Int) -> SRExtension {
        var item: SRExtension?
        (accessQueue).sync {
            item = self.extensions[index]
        }
        return item!
    }
}


extension IssueExtensionsDataSource: QStoreObserver {
    
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {
        guard let record = record as? SRExtension , store == SRExtensionStore.self else { return }
        self.accessQueue.sync(flags: .barrier, execute: {
            let index = self.extensions.insertionIndexOf(record, isOrderedBefore: { (record1, record2) -> Bool in
                return record1.name.lowercased() < record2.name.lowercased()
            })
            self.extensions.insert(record, at: index)
            if let onRecordInsertion = self.onRecordInsertion {
                onRecordInsertion(record, index)
            }
        })
        
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {
        guard let record = record as? SRExtension , store == SRExtensionStore.self else { return }
        self.accessQueue.sync(flags: .barrier, execute: {
            if let index = self.extensions.index(of: record) {
                self.extensions.remove(at: index)
                if let onRecordDeletion = self.onRecordDeletion {
                    onRecordDeletion(record, index)
                }
            }
        })
    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        guard let record = record as? SRExtension , store == SRExtensionStore.self else { return }
        self.accessQueue.sync(flags: .barrier, execute: {
            if let index = self.extensions.index(of: record) {
                self.extensions[index] = record
                if let onRecordUpdate = self.onRecordUpdate {
                    onRecordUpdate(record, index)
                }
            }
        })
    }
}
