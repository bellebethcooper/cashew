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
    fileprivate let coalescer = Coalescer(interval: 3, name: "co.cashewapp.notificationManager.coalescer")
    fileprivate let issuesAccessQueue: DispatchQueue = DispatchQueue(label: "co.cashewapp.notificationManager.issuesAccessQueue", attributes: []);
    fileprivate var issues = Set<QIssue>()
    
    deinit {
        QIssueNotificationStore.remove(self)
    }
    
    override init() {
        super.init()
        QIssueNotificationStore.add(self)
    }
    
    fileprivate func postLocalNotification() {
        var listOfIssues = [QIssue]()
        self.issuesAccessQueue.sync {
            listOfIssues = [QIssue](self.issues)
            self.issues.removeAll()
        }
        
        if let issue = listOfIssues.first , listOfIssues.count == 1 {
            let notification = NSUserNotification()
            //notification.hasActionButton = false
            notification.title =  "Issue Updated" //"\(issueNotification.reason) - \(issue.number) - \(issue.user.login)" //"\(issue.user.login) assigned #\(issue.number) to you."
            notification.informativeText = "#\(issue.number) \(issue.title)"
            notification.soundName = NSUserNotificationDefaultSoundName
            notification.userInfo = ["issueNumber": issue.number, "accountId": issue.account.identifier ?? -1, "repositoryId": issue.repo().identifier ?? -1]
            NSUserNotificationCenter.default.deliver(notification)
        } else if listOfIssues.count > 0 {
            let notification = NSUserNotification()
            //notification.title =  "\(listOfIssues.count) Issues Updated" //"\(issueNotification.reason) - \(issue.number) - \(issue.user.login)" //"\(issue.user.login) assigned #\(issue.number) to you."
            //notification.hasActionButton = false
            notification.informativeText = "\(listOfIssues.count) issues updated"
            notification.soundName = NSUserNotificationDefaultSoundName
            notification.userInfo = ["issuesCount": listOfIssues.count]
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    fileprivate func coalesceNotificationForRecord(_ record: AnyObject) {
        guard let issue = record as? QIssue, let issueNotification = issue.notification , issueNotification.read == false && UserDefaults.notificationPreference() == .Enabled else { return }
        
        self.issuesAccessQueue.sync {
            // FIXME: hicham - should show notifications for other accounts in multi-user mode. I'll let user ask for it ;)
            let currentAccount = QContext.shared().currentAccount
            
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
    
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {
        coalesceNotificationForRecord(record as AnyObject)
    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        coalesceNotificationForRecord(record as AnyObject)
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {
        
    }
    
    
    
    
    
    
}
