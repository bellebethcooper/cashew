//
//  IssueCellView.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/17/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRIssueCellView)
class IssueCellView: NSTableCellView {
    
    let label = BaseLabel()
    
    required init() {
        super.init(frame: NSRect.zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setup() {
        addSubview(label)
        wantsLayer = true;
        label.wantsLayer = true;
        //canDrawConcurrently = true;
        //canDrawSubviewsIntoLayer = true;
        label.drawsBackground = false;
    }
    
    override func layout() {
        label.frame = bounds
        super.layout()
    }
}


@objc(SRDotIssueCellView)
class DotIssueCellView: IssueCellView {
    
    deinit {
        QIssueNotificationStore.remove(self)
        QIssueStore.remove(self)
    }
    
    var issue: QIssue? {
        didSet {
            SyncDispatchOnMainQueue {                
                if let issue = self.issue, let notification = issue.notification , notification.read == false {
                    self.label.stringValue = "•"
                } else {
                    self.label.stringValue = ""
                }
            }
        }
    }
    
    required init() {
        super.init()
        setup()
    }
    
    fileprivate override func setup() {
        super.setup()
        label.textColor = NSColor.red
        label.alignment = .center
        QIssueNotificationStore.add(self)
        QIssueStore.add(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension DotIssueCellView: QStoreObserver {
    
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {
        
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {
        
    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        if let issue = issue, let record = record as? QIssue , record == issue {
            self.issue = record
        }
    }
}

