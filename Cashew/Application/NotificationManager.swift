//
//  NotificationManager.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 3/14/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRNotificationManager)
class NotificationManager: NSObject {
    
    //private let serialQueue: dispatch_queue_t = dispatch_queue_create("co.cashewapp.notificationManager.notifier", DISPATCH_QUEUE_SERIAL);
    private let coalescer = Coalescer(interval: 3, name: "co.cashewapp.notificationManager.coalescer")
    private let issuesAccessQueue: dispatch_queue_t = dispatch_queue_create("co.cashewapp.notificationManager.issuesAccessQueue", DISPATCH_QUEUE_SERIAL);
    private var issues = Set<QIssue>()
    
    deinit {
        QIssueNotificationStore.removeObserver(self)
    }
    
    override init() {
        super.init()
        QIssueNotificationStore.addObserver(self)
    }
    
    private func postLocalNotification() {
        var listOfIssues = [QIssue]()
        dispatch_sync(self.issuesAccessQueue) {
            listOfIssues = [QIssue](self.issues)
            self.issues.removeAll()
        }
        
        if let issue = listOfIssues.first where listOfIssues.count == 1 {
            let notification = NSUserNotification()
            //notification.hasActionButton = false
            notification.title =  "Issue Updated" //"\(issueNotification.reason) - \(issue.number) - \(issue.user.login)" //"\(issue.user.login) assigned #\(issue.number) to you."
            notification.informativeText = "#\(issue.number) \(issue.title)"
            notification.soundName = NSUserNotificationDefaultSoundName
            notification.userInfo = ["issueNumber": issue.number, "accountId": issue.account.identifier, "repositoryId": issue.repo().identifier]
            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        } else if listOfIssues.count > 0 {
            let notification = NSUserNotification()
            //notification.title =  "\(listOfIssues.count) Issues Updated" //"\(issueNotification.reason) - \(issue.number) - \(issue.user.login)" //"\(issue.user.login) assigned #\(issue.number) to you."
            //notification.hasActionButton = false
            notification.informativeText = "\(listOfIssues.count) issues updated"
            notification.soundName = NSUserNotificationDefaultSoundName
            notification.userInfo = ["issuesCount": listOfIssues.count]
            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        }
    }
    
    private func coalesceNotificationForRecord(record: AnyObject) {
        guard let issue = record as? QIssue, issueNotification = issue.notification where issueNotification.read == false && NSUserDefaults.notificationPreference() == .Enabled else { return }
        
        dispatch_sync(self.issuesAccessQueue) {
            // FIXME: hicham - should show notifications for other accounts in multi-user mode. I'll let user ask for it ;)
            let currentAccount = QContext.sharedContext().currentAccount
            
            if currentAccount == issue.account {
                self.issues.insert(issue)
            }
        }
        coalescer.executeBlock {
            self.postLocalNotification()
        }
    }
    
}


extension NotificationManager: QStoreObserver {
    
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {
        coalesceNotificationForRecord(record)
    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        coalesceNotificationForRecord(record)
    }
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {
        
    }
    
    
    
    
    
    
}