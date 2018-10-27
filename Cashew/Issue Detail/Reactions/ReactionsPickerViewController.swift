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
    
    fileprivate let reactionService = SRReactionsService(for: QContext.shared().currentAccount)
    
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
            strongSelf.view.appearance = NSAppearance(named: NSAppearance.Name.aqua)
            
            if mode == .dark {
                //
                backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                
                backgroundColor = CashewColor.backgroundColor()
            }
            
            if let baseView = strongSelf.view as? BaseView {
             baseView.backgroundColor = backgroundColor
            }
            
            
            [strongSelf.thumbsUpButton, strongSelf.thumbsDownButton, strongSelf.laughButton, strongSelf.hoorayButton, strongSelf.confusedButton, strongSelf.heartButton].forEach({ (btn) in
                btn?.appearance = strongSelf.view.appearance
                btn?.wantsLayer = true
                btn?.layer?.backgroundColor = backgroundColor.cgColor
            })
        }
    }
    
    fileprivate func didSetCommentInfo() {
        
    }
    
    // MARK: Actions
    @IBAction func didClickThumbsDown(_ sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("-1")
    }
    
    @IBAction func didClickThumbsUp(_ sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("+1")
    }
    
    @IBAction func didClickLaughButton(_ sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("laugh")
    }
    
    @IBAction func didClickHoorayButton(_ sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("hooray")
    }
    
    @IBAction func didClickConfusedButton(_ sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("confused")
    }
    
    @IBAction func didClickHeartButton(_ sender: AnyObject) {
        fetchReactionsThenToggleReactionContent("heart")
    }
    
    fileprivate func fetchReactionsThenToggleReactionContent(_ content: String) {
        if let issue = commentInfo as? QIssue {
            
            handleReactionsForIssue(issue, content: content)
        }  else if let issueComment = commentInfo as? QIssueComment {
            handleReactionsForIssueComment(issueComment, content: content)
        }
    }
    
    fileprivate func handleReactionsForIssue(_ issue: QIssue, content: String) {
        var issuesReactionSet = Set<SRIssueReaction>()
        let savedReactions = SRIssueReactionStore.issueReactions(for: issue)
        
        savedReactions?.forEach { (savedReaction) in
            issuesReactionSet.insert(savedReaction)
        }
        
        reactionService.reactionsForIssue(issue, onCompletion: { [weak self] (responseObject, context, err) in
            guard let reactions = responseObject as? [SRIssueReaction] , err == nil else { return }
            reactions.forEach({ (reaction) in
                SRIssueReactionStore.save(reaction)
                issuesReactionSet.remove(reaction)
            })
            
            issuesReactionSet.forEach({ (deleteReaction) in
                SRIssueReactionStore.delete(deleteReaction)
            })
            
            
            self?.didClickButtonWithContent(content)
            })
    }
    
    fileprivate func handleReactionsForIssueComment(_ issueComment: QIssueComment, content: String) {
        var issueCommentsReactionSet = Set<SRIssueCommentReaction>()
        let savedReactions = SRIssueCommentReactionStore.issueCommentReactions(for: issueComment)
        
        savedReactions?.forEach { (savedReaction) in
            issueCommentsReactionSet.insert(savedReaction)
        }
        
        
        reactionService.reactionsForIssueComment(issueComment, onCompletion: { [weak self] (responseObject, context, err) in
            guard let reactions = responseObject as? [SRIssueCommentReaction] , err == nil else { return }
            reactions.forEach({ (reaction) in
                SRIssueCommentReactionStore.save(reaction)
                issueCommentsReactionSet.remove(reaction)
            })
            
            issueCommentsReactionSet.forEach({ (deleteReaction) in
                SRIssueCommentReactionStore.delete(deleteReaction)
            })
            
            
            self?.didClickButtonWithContent(content)
            })
    }
    
    fileprivate func didClickButtonWithContent(_ content: String) {
        let userId = QContext.shared().currentAccount.userId
        if let issue = commentInfo as? QIssue {
            if let reaction = SRIssueReactionStore.didUserId(userId, addReactionTo: issue, withContent: content) {
                //DDLogDebug("issue.reaction \(reaction)")
                reactionService.deleteReactionWithId(reaction.identifier, onCompletion: { [weak self] (obj, context, err) in
                    if  err == nil {
                        SRIssueReactionStore.delete(reaction)
                    }
                    QIssueStore.updateIssueReactionCounts(for: issue)
                    self?.popover?.close()
                    })
            } else {
                reactionService.createReactionForIssue(issue, content: content, onCompletion: { [weak self] (reaction, context, err) in
                    if let reaction = reaction as? SRIssueReaction , err == nil {
                        SRIssueReactionStore.save(reaction)
                    }
                    QIssueStore.updateIssueReactionCounts(for: issue)
                    self?.popover?.close()
                    })
            }
            
        } else if let issueComment = commentInfo as? QIssueComment {
            if let reaction = SRIssueCommentReactionStore.didUserId(userId, addReactionTo: issueComment, withContent: content) {
                //DDLogDebug("issueComment.reaction \(reaction)")
                reactionService.deleteReactionWithId(reaction.identifier, onCompletion: { [weak self] (obj, context, err) in
                    if err == nil {
                        SRIssueCommentReactionStore.delete(reaction)
                    }
                    QIssueCommentStore.updateIssueCommentReactionCounts(for: issueComment)
                    self?.popover?.close()
                    })
            } else {
                reactionService.createReactionForIssueComment(issueComment, content: content, onCompletion: { [weak self] (reaction, context, err) in
                    if let reaction = reaction as? SRIssueCommentReaction , err == nil {
                        SRIssueCommentReactionStore.save(reaction)
                    }
                    QIssueCommentStore.updateIssueCommentReactionCounts(for: issueComment)
                    self?.popover?.close()
                    })
            }
        }
    }
    
}
