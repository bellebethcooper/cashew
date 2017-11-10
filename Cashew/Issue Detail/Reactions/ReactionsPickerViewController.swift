//
//  ReactionsPickerViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class ReactionsPickerViewController: NSViewController {
    
    @IBOutlet weak var thumbsUpButton: NSButton!
    @IBOutlet weak var thumbsDownButton: NSButton!
    @IBOutlet weak var laughButton: NSButton!
    @IBOutlet weak var hoorayButton: NSButton!
    @IBOutlet weak var confusedButton: NSButton!
    @IBOutlet weak var heartButton: NSButton!
    
    weak var popover: NSPopover?
    
    private let reactionService = SRReactionsService(forAccount: QContext.sharedContext().currentAccount)
    
    var commentInfo: QIssueCommentInfo? {
        didSet {
            didSetCommentInfo()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let baseView = view as? BaseView {
            baseView.popoverBackgroundColorFixEnabed = true
            baseView.disableThemeObserver = true
        }
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else { return }
            
            let backgroundColor: NSColor
            strongSelf.view.appearance = NSAppearance(named: NSAppearanceNameAqua)
            
            if mode == .Dark {
                //
                backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                
                backgroundColor = CashewColor.backgroundColor()
            }
            
            if let baseView = strongSelf.view as? BaseView {
             baseView.backgroundColor = backgroundColor
            }
            
            
            [strongSelf.thumbsUpButton, strongSelf.thumbsDownButton, strongSelf.laughButton, strongSelf.hoorayButton, strongSelf.confusedButton, strongSelf.heartButton].forEach({ (btn) in
                btn.appearance = strongSelf.view.appearance
                btn.wantsLayer = true
                btn.layer?.backgroundColor = backgroundColor.CGColor
            })
        }
    }
    
    private func didSetCommentInfo() {
        
    }
    
    // MARK: Actions
    @IBAction func didClickThumbsDown(sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("-1")
    }
    
    @IBAction func didClickThumbsUp(sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("+1")
    }
    
    @IBAction func didClickLaughButton(sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("laugh")
    }
    
    @IBAction func didClickHoorayButton(sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("hooray")
    }
    
    @IBAction func didClickConfusedButton(sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("confused")
    }
    
    @IBAction func didClickHeartButton(sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("heart")
    }
    
    private func fetchReactionsThenToggleReactionContent(content: String) {
        if let issue = commentInfo as? QIssue {
            
            handleReactionsForIssue(issue, content: content)
        }  else if let issueComment = commentInfo as? QIssueComment {
            handleReactionsForIssueComment(issueComment, content: content)
        }
    }
    
    private func handleReactionsForIssue(issue: QIssue, content: String) {
        var issuesReactionSet = Set<SRIssueReaction>()
        let savedReactions = SRIssueReactionStore.issueReactionsForIssue(issue)
        
        savedReactions.forEach { (savedReaction) in
            issuesReactionSet.insert(savedReaction)
        }
        
        reactionService.reactionsForIssue(issue, onCompletion: { [weak self] (responseObject, context, err) in
            guard let reactions = responseObject as? [SRIssueReaction] where err == nil else { return }
            reactions.forEach({ (reaction) in
                SRIssueReactionStore.saveIssueReaction(reaction)
                issuesReactionSet.remove(reaction)
            })
            
            issuesReactionSet.forEach({ (deleteReaction) in
                SRIssueReactionStore.deleteIssueReaction(deleteReaction)
            })
            
            
            self?.didClickButtonWithContent(content)
            })
    }
    
    private func handleReactionsForIssueComment(issueComment: QIssueComment, content: String) {
        var issueCommentsReactionSet = Set<SRIssueCommentReaction>()
        let savedReactions = SRIssueCommentReactionStore.issueCommentReactionsForIssueComment(issueComment)
        
        savedReactions.forEach { (savedReaction) in
            issueCommentsReactionSet.insert(savedReaction)
        }
        
        
        reactionService.reactionsForIssueComment(issueComment, onCompletion: { [weak self] (responseObject, context, err) in
            guard let reactions = responseObject as? [SRIssueCommentReaction] where err == nil else { return }
            reactions.forEach({ (reaction) in
                SRIssueCommentReactionStore.saveIssueCommentReaction(reaction)
                issueCommentsReactionSet.remove(reaction)
            })
            
            issueCommentsReactionSet.forEach({ (deleteReaction) in
                SRIssueCommentReactionStore.deleteIssueCommentReaction(deleteReaction)
            })
            
            
            self?.didClickButtonWithContent(content)
            })
    }
    
    private func didClickButtonWithContent(content: String) {
        let userId = QContext.sharedContext().currentAccount.userId
        if let issue = commentInfo as? QIssue {
            if let reaction = SRIssueReactionStore.didUserId(userId, addReactionToIssue: issue, withContent: content) {
                //DDLogDebug("issue.reaction \(reaction)")
                reactionService.deleteReactionWithId(reaction.identifier, onCompletion: { [weak self] (obj, context, err) in
                    if  err == nil {
                        SRIssueReactionStore.deleteIssueReaction(reaction)
                    }
                    QIssueStore.updateIssueReactionCountsForIssue(issue)
                    self?.popover?.close()
                    })
            } else {
                reactionService.createReactionForIssue(issue, content: content, onCompletion: { [weak self] (reaction, context, err) in
                    if let reaction = reaction as? SRIssueReaction where err == nil {
                        SRIssueReactionStore.saveIssueReaction(reaction)
                    }
                    QIssueStore.updateIssueReactionCountsForIssue(issue)
                    self?.popover?.close()
                    })
            }
            
        } else if let issueComment = commentInfo as? QIssueComment {
            if let reaction = SRIssueCommentReactionStore.didUserId(userId, addReactionToIssueComment: issueComment, withContent: content) {
                //DDLogDebug("issueComment.reaction \(reaction)")
                reactionService.deleteReactionWithId(reaction.identifier, onCompletion: { [weak self] (obj, context, err) in
                    if err == nil {
                        SRIssueCommentReactionStore.deleteIssueCommentReaction(reaction)
                    }
                    QIssueCommentStore.updateIssueCommentReactionCountsForIssueComment(issueComment)
                    self?.popover?.close()
                    })
            } else {
                reactionService.createReactionForIssueComment(issueComment, content: content, onCompletion: { [weak self] (reaction, context, err) in
                    if let reaction = reaction as? SRIssueCommentReaction where err == nil {
                        SRIssueCommentReactionStore.saveIssueCommentReaction(reaction)
                    }
                    QIssueCommentStore.updateIssueCommentReactionCountsForIssueComment(issueComment)
                    self?.popover?.close()
                    })
            }
        }
    }
    
}
