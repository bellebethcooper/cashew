//
//  QIssueDetailsDataSource.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 2/18/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

typealias IssueDetailsRowChange = ( (row: Int) -> () )

class QIssueDetailsDataSource: NSObject, QStoreObserver {
    
    private static let skippedEvents = ["mentioned", "subscribed", "unsubscribed", "referenced", "merged", "head_ref_deleted", "deployed"]
    
    private var items = [SRIssueDetailItem]()
//    private var events = [QIssueEvent]()
//    private var comments = [QIssueComment]()
    
    private var drafts = [String: IssueCommentDraft]()
    private let draftsAccessQueue = dispatch_queue_create("co.cashewapp.QIssueDetailsDataSource.draftsAccessQueue", DISPATCH_QUEUE_CONCURRENT)
    
    var onRowDeletion: IssueDetailsRowChange?
    var onRowUpdate: IssueDetailsRowChange?
    var onRowInsert: IssueDetailsRowChange?
    
    deinit {
        QIssueCommentStore.removeObserver(self)
        QIssueStore.removeObserver(self)
        QIssueEventStore.removeObserver(self)
    }
    
    
    required override init() {
        super.init()
        
        QIssueCommentStore.addObserver(self)
        QIssueStore.addObserver(self)
        QIssueEventStore.addObserver(self)
    }
    
    func issueCommentDraftForIssueComment(info: QIssueCommentInfo) -> IssueCommentDraft? {
        if let info = info as? QIssue {
            var draft: IssueCommentDraft?
            dispatch_sync(draftsAccessQueue) {
                draft = self.drafts[self.draftKeyWith(nil, accountId: info.account.identifier, repositoryId: info.repository.identifier, type: .Issue)]
            }
            return draft
        } else if let info = info as? QIssueComment, account = info.account, repository = info.repository {
            var draft: IssueCommentDraft?
            dispatch_sync(draftsAccessQueue) {
                draft = self.drafts[self.draftKeyWith(info.identifier, accountId: account.identifier, repositoryId: repository.identifier, type: .Comment)]
            }
            return draft
        }
        fatalError()
    }
    
    func issueCommentDraftForCurrentIssue() -> IssueCommentDraft? {
        guard let issue = issue else { return nil }
        let key = draftKeyWith(nil, accountId: issue.account.identifier, repositoryId: issue.repository.identifier, type: .Comment)
        
        var draft: IssueCommentDraft?
        dispatch_sync(draftsAccessQueue) {
            draft = self.drafts[key]
        }
        return draft
    }
    
    private func draftKeyWith(identifier: NSNumber?, accountId: NSNumber, repositoryId: NSNumber, type: IssueCommentDraftType) -> String {
        if let identifier = identifier {
            return "\(type.rawValue)_\(identifier)_\(accountId)_\(repositoryId)"
        } else {
            return "\(type.rawValue)_nil_\(accountId)_\(repositoryId)"
        }
    }
    
    private func mergeIssueEvents(items: [SRIssueDetailItem]) -> [SRIssueDetailItem] {
        var mergedItems = [SRIssueDetailItem]()
        var buckets = [ String: IssueEventInfo ]();
        for item in items {
            guard let event = item as? QIssueEvent, eventName = event.event else {
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
                        eventViewModel.additions.addObject(event.label!.name!)
                        
                    } else if eventName == "milestoned" {
                        eventViewModel.additions.addObject(event.milestone!.title)
                        
                    } else if eventName == "unlabeled" {
                        eventViewModel.removals.addObject(event.label!.name!)
                        
                    } else if eventName == "demilestoned" {
                        eventViewModel.removals.addObject(event.milestone!.title)
                    }
                    
                } else {
                    let eventViewModel = IssueEventViewModel(actor: event.actor, createdAt: event.createdAt, event: eventName)
                    
                    if eventName == "labeled"  {
                        eventViewModel.additions.addObject(event.label!.name!)
                        
                    } else if eventName == "milestoned" {
                        eventViewModel.additions.addObject(event.milestone!.title)
                        
                    } else if eventName == "unlabeled" {
                        eventViewModel.removals.addObject(event.label!.name!)
                        
                    } else if eventName == "demilestoned" {
                        eventViewModel.removals.addObject(event.milestone!.title)
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
        
        mergedItems.sortInPlace { (obj1, obj2) -> Bool in
            return obj1.sortDate().compare(obj2.sortDate()) == .OrderedAscending
        }
        
        return mergedItems
    }
    
    var issue: QIssue? {
        didSet {
            reloadData()
        }
    }
    
    private func reloadDrafts() {
        dispatch_barrier_sync(draftsAccessQueue) {
            self.drafts = [String: IssueCommentDraft]()
        }
        
        guard let issue = issue else { return }
        
        let drafts = QIssueCommentDraftStore.issueCommentDraftsForAccountId(issue.account.identifier, repositoryId: issue.repository.identifier, issueNumber: issue.number)
        
        drafts.forEach { (draft) in
            guard let draft = draft as? IssueCommentDraft else { return }
            addIssueCommentDraft(draft)
        }
    }
    
    func addIssueCommentDraft(draft: IssueCommentDraft) {
        dispatch_barrier_async(draftsAccessQueue) {
            let key = self.draftKeyWith(draft.issueCommentId, accountId: draft.account.identifier, repositoryId: draft.repository.identifier, type: draft.type)
            self.drafts[key] = draft
        }
    }
    
    func removeIssueCommentDraft(draft: IssueCommentDraft) {
        dispatch_barrier_async(draftsAccessQueue) {
            let key = self.draftKeyWith(draft.issueCommentId, accountId: draft.account.identifier, repositoryId: draft.repository.identifier, type: draft.type)
            self.drafts[key] = nil
        }
    }
    
    func reloadData() {
        layoutCache.removeAllObjects()
        
        guard let issue = issue else {
            items = [SRIssueDetailItem]()
            return
        }
        
        let operationQueue = NSOperationQueue()
        operationQueue.maxConcurrentOperationCount = 10
        
        var comments = [SRIssueDetailItem]()
        var events = [SRIssueDetailItem]()
        

        operationQueue.addOperationWithBlock {
            comments = QIssueCommentStore.issueCommentsForAccountId(issue.account.identifier, repositoryId: issue.repository.identifier, issueNumber: issue.number)
        }
        operationQueue.addOperationWithBlock {
            events = QIssueEventStore.issueEventsForAccountId(issue.account.identifier, repositoryId: issue.repository.identifier, issueNumber: issue.number, skipEvents: QIssueDetailsDataSource.skippedEvents)
        }
        operationQueue.addOperationWithBlock { [weak self] in
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
        all.insert(issue, atIndex: 0)
        
        // set items
        items = all
    }
    
    func numberOfItems() -> Int {
        return items.count
    }
    
    func itemAtIndex(index: Int) -> AnyObject {
        return items[index]
    }
    
    private let layoutCache = NSCache()
    func updateWebViewLayoutCache(height: Float, forRow row: Int) {
        layoutCache.setObject(NSNumber(float: height), forKey: row)
    }
    
    func webViewLayoutCacheForRow(row: Int) -> CGFloat {
        if let val = layoutCache.objectForKey(row) as? NSNumber {
            return CGFloat(val.floatValue)
        } else {
            return 54 + IssueCommentTableViewCell.reactionViewerHeight
        }
    }
    
    // MARK: QStoreObserver
    
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {
        switch record {
        case let issueComment as QIssueComment:
            
            if issueComment.repository != issue?.repository || issueComment.issueNumber != issue?.number {
                return
            }
            
            let index = items.insertionIndexOf(issueComment) {
                if $0.isKindOfClass(IssueDetailLabelsTableViewModel) || $0.isKindOfClass(QIssue) {
                    return true
                }
                if $1.isKindOfClass(IssueDetailLabelsTableViewModel) || $1.isKindOfClass(QIssue) {
                    return false
                }
                return $0.sortDate().compare($1.sortDate()) == .OrderedAscending
            }
            
            if let onRowInsert = onRowInsert {
                items.insert(issueComment, atIndex: index)
                onRowInsert(row: index)
            }
            break
        case let issueEvent as QIssueEvent:
            guard let eventName = issueEvent.event as? String where QIssueDetailsDataSource.skippedEvents.contains(eventName) == false else {
                return
            }
            
            if issueEvent.repository != issue?.repository || issueEvent.issueNumber != issue?.number {
                return
            }
            
            let index = items.insertionIndexOf(issueEvent) {
                if $0.isKindOfClass(IssueDetailLabelsTableViewModel) || $0.isKindOfClass(QIssue) {
                    return true
                }
                if $1.isKindOfClass(IssueDetailLabelsTableViewModel) || $1.isKindOfClass(QIssue) {
                    return false
                }
                return $0.sortDate().compare($1.sortDate()) == .OrderedAscending
            }
            
            if let onRowInsert = onRowInsert {
                items.insert(issueEvent, atIndex: index)
                onRowInsert(row: index)
            }
            break
        default:
            break
        }
    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        switch record {
        case let issue as QIssue:
            let index = items.indexOf {
                if let currentIssue = $0 as? QIssue where issue == currentIssue && issue.updatedAt != currentIssue.updatedAt && issue.body != currentIssue.body {
                    return true
                }
                return false
            }
            
            if let index = index, onRowUpdate = onRowUpdate {
                items[index] = issue
                onRowUpdate(row: index)
            }
            break
        case let issueComment as QIssueComment:
            let index = items.indexOf {
                if let currentIssueComment = $0 as? QIssueComment where issueComment == currentIssueComment && issueComment.updatedAt != currentIssueComment.updatedAt && issueComment.body != currentIssueComment.body {
                    return true
                }
                return false
            }
            
            if let index = index, onRowUpdate = onRowUpdate {
                items[index] = issueComment
                onRowUpdate(row: index)
            }
            break
        default:
            break
        }
    }
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {
        switch record {
        case let issueComment as QIssueComment:
            
            if issueComment.repository != issue?.repository || issueComment.issueNumber != issue?.number {
                return
            }
            
            let index = items.indexOf {
                if let currentIssueComment = $0 as? QIssueComment where issueComment == currentIssueComment {
                    return true
                }
                return false
            }
            
            if let index = index, onRowDeletion = onRowDeletion {
                items.removeAtIndex(index)
                onRowDeletion(row: index)
            }
            break
        default:
            break
        }
    }
}
