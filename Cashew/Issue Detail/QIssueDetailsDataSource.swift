//
//  QIssueDetailsDataSource.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 2/18/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

typealias IssueDetailsRowChange = ( (_ row: Int) -> () )

class QIssueDetailsDataSource: NSObject, QStoreObserver {
    
    fileprivate static let skippedEvents = ["mentioned", "subscribed", "unsubscribed", "referenced", "merged", "head_ref_deleted", "deployed"]
    
    fileprivate var items = [SRIssueDetailItem]()
//    private var events = [QIssueEvent]()
//    private var comments = [QIssueComment]()
    
    fileprivate var drafts = [String: IssueCommentDraft]()
    fileprivate let draftsAccessQueue = DispatchQueue(label: "co.cashewapp.QIssueDetailsDataSource.draftsAccessQueue", attributes: DispatchQueue.Attributes.concurrent)
    
    var onRowDeletion: IssueDetailsRowChange?
    var onRowUpdate: IssueDetailsRowChange?
    var onRowInsert: IssueDetailsRowChange?
    
    deinit {
        QIssueCommentStore.remove(self)
        QIssueStore.remove(self)
        QIssueEventStore.remove(self)
    }
    
    
    required override init() {
        super.init()
        
        QIssueCommentStore.add(self)
        QIssueStore.add(self)
        QIssueEventStore.add(self)
    }
    
    func issueCommentDraftForIssueComment(_ info: QIssueCommentInfo) -> IssueCommentDraft? {
        if let info = info as? QIssue {
            var draft: IssueCommentDraft?
            (draftsAccessQueue).sync {
                draft = self.drafts[self.draftKeyWith(nil, accountId: info.account.identifier, repositoryId: info.repository.identifier, type: .issue)]
            }
            return draft
        } else if let info = info as? QIssueComment, let account = info.account, let repository = info.repository {
            var draft: IssueCommentDraft?
            (draftsAccessQueue).sync {
                draft = self.drafts[self.draftKeyWith(info.identifier, accountId: account.identifier, repositoryId: repository.identifier, type: .comment)]
            }
            return draft
        }
        fatalError()
    }
    
    func issueCommentDraftForCurrentIssue() -> IssueCommentDraft? {
        guard let issue = issue else { return nil }
        let key = draftKeyWith(nil, accountId: issue.account.identifier, repositoryId: issue.repository.identifier, type: .comment)
        
        var draft: IssueCommentDraft?
        (draftsAccessQueue).sync {
            draft = self.drafts[key]
        }
        return draft
    }
    
    fileprivate func draftKeyWith(_ identifier: NSNumber?, accountId: NSNumber, repositoryId: NSNumber, type: IssueCommentDraftType) -> String {
        if let identifier = identifier {
            return "\(type.rawValue)_\(identifier)_\(accountId)_\(repositoryId)"
        } else {
            return "\(type.rawValue)_nil_\(accountId)_\(repositoryId)"
        }
    }
    
    fileprivate func mergeIssueEvents(_ items: [SRIssueDetailItem]) -> [SRIssueDetailItem] {
        var mergedItems = [SRIssueDetailItem]()
        var buckets = [ String: IssueEventInfo ]();
        for item in items {
            guard let event = item as? QIssueEvent, let eventName = event.event else {
                mergedItems.append(item)
                continue
            }
            let dateString = event.createdAt.toFullDateString()
            let eventBucketKey: String
            if eventName == "labeled" || eventName == "unlabeled" {
                eventBucketKey = "labeled"
            } else if eventName == "milestoned" || eventName == "demilestoned" {
                eventBucketKey = "milestoned"
            } else {
                eventBucketKey = String(eventName)
            }
            let bucketKey = "\(event.actor.login)_\(dateString)_\(eventBucketKey)"
            let issueEvent: IssueEventInfo? = buckets[bucketKey]
            
            // grouped events
            if eventName == "labeled" || eventName == "unlabeled" || eventName == "milestoned" || eventName == "demilestoned" {
                
                if let eventViewModel = issueEvent as? IssueEventViewModel {
                    
                    if event.createdAt.isAfterDate(eventViewModel.createdAt) {
                        eventViewModel.createdAt = event.createdAt
                    }
                    
                    if eventName == "labeled"  {
                        eventViewModel.additions.add(event.label!.name!)
                        
                    } else if eventName == "milestoned" {
                        eventViewModel.additions.add(event.milestone!.title)
                        
                    } else if eventName == "unlabeled" {
                        eventViewModel.removals.add(event.label!.name!)
                        
                    } else if eventName == "demilestoned" {
                        eventViewModel.removals.add(event.milestone!.title)
                    }
                    
                } else {
                    let eventViewModel = IssueEventViewModel(actor: event.actor, createdAt: event.createdAt, event: eventName)
                    
                    if eventName == "labeled"  {
                        eventViewModel.additions.add(event.label!.name!)
                        
                    } else if eventName == "milestoned" {
                        eventViewModel.additions.add(event.milestone!.title)
                        
                    } else if eventName == "unlabeled" {
                        eventViewModel.removals.add(event.label!.name!)
                        
                    } else if eventName == "demilestoned" {
                        eventViewModel.removals.add(event.milestone!.title)
                    }
                    
                    buckets[bucketKey] = eventViewModel
                }
                
            } else {
                buckets[bucketKey] = event
            }
            
        }
        
        buckets.values.forEach { (event) in
            mergedItems.append(event)
        }
        
        mergedItems.sort { (obj1, obj2) -> Bool in
            return obj1.sortDate().compare(obj2.sortDate()) == .orderedAscending
        }
        
        return mergedItems
    }
    
    var issue: QIssue? {
        didSet {
            reloadData()
        }
    }
    
    fileprivate func reloadDrafts() {
        draftsAccessQueue.sync(flags: .barrier, execute: {
            self.drafts = [String: IssueCommentDraft]()
        }) 
        
        guard let issue = issue else { return }
        return
            // temporarily just commenting this out and returning here, because the method isn't recognised and I don't know why
//        let drafts = QIssueCommentDraftStore.issueCommentDraftsForAccountId(issue.account.identifier, repositoryId: issue.repository.identifier, issueNumber: issue.number)
        
        drafts.forEach { (draft) in
            guard let draft = draft as? IssueCommentDraft else { return }
            addIssueCommentDraft(draft)
        }
    }
    
    func addIssueCommentDraft(_ draft: IssueCommentDraft) {
        draftsAccessQueue.async(flags: .barrier, execute: {
            let key = self.draftKeyWith(draft.issueCommentId, accountId: draft.account.identifier, repositoryId: draft.repository.identifier, type: draft.type)
            self.drafts[key] = draft
        }) 
    }
    
    func removeIssueCommentDraft(_ draft: IssueCommentDraft) {
        draftsAccessQueue.async(flags: .barrier, execute: {
            let key = self.draftKeyWith(draft.issueCommentId, accountId: draft.account.identifier, repositoryId: draft.repository.identifier, type: draft.type)
            self.drafts[key] = nil
        }) 
    }
    
    func reloadData() {
        layoutCache.removeAllObjects()
        
        guard let issue = issue else {
            items = [SRIssueDetailItem]()
            return
        }
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 10
        
        var comments = [SRIssueDetailItem]()
        var events = [SRIssueDetailItem]()
        

        operationQueue.addOperation {
            comments = QIssueCommentStore.issueComments(forAccountId: issue.account.identifier, repositoryId: issue.repository.identifier, issueNumber: issue.number)
        }
        operationQueue.addOperation {
            events = QIssueEventStore.issueEvents(forAccountId: issue.account.identifier, repositoryId: issue.repository.identifier, issueNumber: issue.number, skipEvents: QIssueDetailsDataSource.skippedEvents)
        }
        operationQueue.addOperation { [weak self] in
            self?.reloadDrafts()
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        var all = [SRIssueDetailItem]()
        
        comments.forEach { (comment) in
            all.append(comment)
        }
        
        events.forEach { (event) in
            all.append(event)
        }
        
        // merge events
        all = mergeIssueEvents(all)
        
        //all.insert(IssueDetailLabelsTableViewModel(issue: issue), atIndex: 0)
        all.insert(issue, at: 0)
        
        // set items
        items = all
    }
    
    func numberOfItems() -> Int {
        return items.count
    }
    
    func itemAtIndex(_ index: Int) -> AnyObject {
        return items[index]
    }
    
    fileprivate let layoutCache = NSCache<AnyObject, AnyObject>()
    func updateWebViewLayoutCache(_ height: Float, forRow row: Int) {
        layoutCache.setObject(NSNumber(value: height as Float), forKey: row as AnyObject)
    }
    
    func webViewLayoutCacheForRow(_ row: Int) -> CGFloat {
        if let val = layoutCache.object(forKey: row as AnyObject) as? NSNumber {
            return CGFloat(val.floatValue)
        } else {
            return 54 + IssueCommentTableViewCell.reactionViewerHeight
        }
    }
    
    // MARK: QStoreObserver
    
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {
        switch record {
        case let issueComment as QIssueComment:
            
            if issueComment.repository != issue?.repository || issueComment.issueNumber != issue?.number {
                return
            }
            
            let index = items.insertionIndexOf(issueComment) {
                if $0.isKind(of: IssueDetailLabelsTableViewModel.self) || $0.isKind(of: QIssue.self) {
                    return true
                }
                if $1.isKind(of: IssueDetailLabelsTableViewModel.self) || $1.isKind(of: QIssue.self) {
                    return false
                }
                return $0.sortDate().compare($1.sortDate()) == .orderedAscending
            }
            
            if let onRowInsert = onRowInsert {
                items.insert(issueComment, at: index)
                onRowInsert(index)
            }
            break
        case let issueEvent as QIssueEvent:
            guard let eventName = issueEvent.event as? String , QIssueDetailsDataSource.skippedEvents.contains(eventName) == false else {
                return
            }
            
            if issueEvent.repository != issue?.repository || issueEvent.issueNumber != issue?.number {
                return
            }
            
            let index = items.insertionIndexOf(issueEvent) {
                if $0.isKind(of: IssueDetailLabelsTableViewModel.self) || $0.isKind(of: QIssue.self) {
                    return true
                }
                if $1.isKind(of: IssueDetailLabelsTableViewModel.self) || $1.isKind(of: QIssue.self) {
                    return false
                }
                return $0.sortDate().compare($1.sortDate()) == .orderedAscending
            }
            
            if let onRowInsert = onRowInsert {
                items.insert(issueEvent, at: index)
                onRowInsert(index)
            }
            break
        default:
            break
        }
    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        switch record {
//        case let issue as QIssue:
//            let index = items.indexOf {
//                if let currentIssue = $0 as? QIssue,
//                    issue == currentIssue && issue.updatedAt != currentIssue.updatedAt && issue.body != currentIssue.body {
//                    return true
//                }
//                return false
//            }
//
//            if let index = index, let onRowUpdate = onRowUpdate {
//                items[index] = issue
//                onRowUpdate(row: index)
//            }
//            break
//        case let issueComment as QIssueComment:
//            let index = items.indexOf {
//                if let currentIssueComment = $0 as? QIssueComment , issueComment == currentIssueComment && issueComment.updatedAt != currentIssueComment.updatedAt && issueComment.body != currentIssueComment.body {
//                    return true
//                }
//                return false
//            }
//
//            if let index = index, let onRowUpdate = onRowUpdate {
//                items[index] = issueComment
//                onRowUpdate(row: index)
//            }
//            break
        default:
            break
        }
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {
        switch record {
//        case let issueComment as QIssueComment:
//            
//            if issueComment.repository != issue?.repository || issueComment.issueNumber != issue?.number {
//                return
//            }
//            
//            let index = items.indexOf {
//                if let currentIssueComment = $0 as? QIssueComment , issueComment == currentIssueComment {
//                    return true
//                }
//                return false
//            }
//            
//            if let index = index, let onRowDeletion = onRowDeletion {
//                items.removeAtIndex(index)
//                onRowDeletion(row: index)
//            }
//            break
        default:
            break
        }
    }
}
