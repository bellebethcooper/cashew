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
    
    private func setup() {
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
        QIssueNotificationStore.removeObserver(self)
        QIssueStore.removeObserver(self)
    }
    
    var issue: QIssue? {
        didSet {
            SyncDispatchOnMainQueue {                
                if let issue = self.issue, notification = issue.notification where notification.read == false {
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
    
    private override func setup() {
        super.setup()
        label.textColor = NSColor.redColor()
        label.alignment = .Center
        QIssueNotificationStore.addObserver(self)
        QIssueStore.addObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension DotIssueCellView: QStoreObserver {
    
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {
        
    }
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {
        
    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        if let issue = issue, record = record as? QIssue where record == issue {
            self.issue = record
        }
    }
}

