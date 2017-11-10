//
//  ReactionCountView.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRReactionCountView)
class ReactionCountView: BaseView {
    
    private static let buttonLabelPadding: CGFloat = 5
    private static let labelRightPadding: CGFloat = 10
    
    private lazy var reactionService: SRReactionsService = {
        return SRReactionsService(forAccount: QContext.sharedContext().currentAccount)
    }()
    
    let button = NSButton()
    let countLabel = BaseLabel()
    
    var content: String?
    var commentInfo: QIssueCommentInfo? /* {
        didSet {
            let userId = QContext.sharedContext().currentAccount.userId
            guard let content = content else { return }
            
            if let issue = commentInfo as? QIssue {
                if let _ = SRIssueReactionStore.didUserId(userId, addReactionToIssue: issue, withContent: content) {
                    DispatchOnMainQueue({
                        self.backgroundColor = CashewColor.currentLineBackgroundColor()
                    })
                    
                } else {
                    DispatchOnMainQueue({
                        self.backgroundColor = NSColor.clearColor()
                    })
                }
                
            } else if let issueComment = commentInfo as? QIssueComment {
                if let _ = SRIssueCommentReactionStore.didUserId(userId, addReactionToIssueComment: issueComment, withContent: content) {
                    DispatchOnMainQueue({
                        self.backgroundColor = CashewColor.currentLineBackgroundColor()
                    })
                } else {
                    DispatchOnMainQueue({
                        self.backgroundColor = NSColor.clearColor()
                    })
                }
            }
        }
    } */
    
    var icon: String = "" {
        didSet {
            button.title = icon
            invalidateIntrinsicContentSize()
        }
    }
    
    var count: Int = 0 {
        didSet {
            if count == 0 {
                countLabel.stringValue = ""
            } else {
                countLabel.stringValue = String(count)
            }
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: NSSize {
        let btnSize = button.intrinsicContentSize
        let lblSize = countLabel.intrinsicContentSize
        return NSSize(width: 30 + btnSize.width + lblSize.width, height: btnSize.height + lblSize.height)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        didClick()
    }
    
    @objc
    private func didClick() {
        let userId = QContext.sharedContext().currentAccount.userId
        guard let content = content else { return }
        
        if let issue = commentInfo as? QIssue {
            
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
                
                if let reaction = SRIssueReactionStore.didUserId(userId, addReactionToIssue: issue, withContent: content) {
                    //DDLogDebug("issue.reaction \(reaction)")
                    self?.reactionService.deleteReactionWithId(reaction.identifier, onCompletion: { (obj, context, err) in
                        if  err == nil {
                            SRIssueReactionStore.deleteIssueReaction(reaction)
                            QIssueStore.updateIssueReactionCountsForIssue(issue)
//                            DispatchOnMainQueue({
//                                self?.backgroundColor = NSColor.clearColor()
//                            })
                            
                        }
                        })
                } else {
                    self?.reactionService.createReactionForIssue(issue, content: content, onCompletion: { (reaction, context, err) in
                        if let reaction = reaction as? SRIssueReaction where err == nil {
                            SRIssueReactionStore.saveIssueReaction(reaction)
                            QIssueStore.updateIssueReactionCountsForIssue(issue)
//                            DispatchOnMainQueue({
//                                self?.backgroundColor = CashewColor.currentLineBackgroundColor()
//                            })
                        }
                        })
                }
                
                
                })
            
        } else if let issueComment = commentInfo as? QIssueComment {
            
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
                
                if let reaction = SRIssueCommentReactionStore.didUserId(userId, addReactionToIssueComment: issueComment, withContent: content) {
                    //DDLogDebug("issueComment.reaction \(reaction)")
                    self?.reactionService.deleteReactionWithId(reaction.identifier, onCompletion: { (obj, context, err) in
                        if err == nil {
                            SRIssueCommentReactionStore.deleteIssueCommentReaction(reaction)
                            QIssueCommentStore.updateIssueCommentReactionCountsForIssueComment(issueComment)
//                            DispatchOnMainQueue({
//                                self?.backgroundColor = NSColor.clearColor()
//                            })
                        }
                        })
                } else {
                    self?.reactionService.createReactionForIssueComment(issueComment, content: content, onCompletion: {  (reaction, context, err) in
                        if let reaction = reaction as? SRIssueCommentReaction where err == nil {
                            SRIssueCommentReactionStore.saveIssueCommentReaction(reaction)
                            QIssueCommentStore.updateIssueCommentReactionCountsForIssueComment(issueComment)
//                            DispatchOnMainQueue({
//                                self?.backgroundColor = CashewColor.currentLineBackgroundColor()
//                            })
                        }
                        
                        })
                }
                
                
                })
            
        }
    }
    
    func setup() {
        
        backgroundColor = NSColor.clearColor()
        
        button.bordered = false
        button.wantsLayer = true
        button.font = NSFont.systemFontOfSize(15)
        button.setButtonType(.MomentaryChange)
        button.action = #selector(ReactionCountView.didClick)
        button.target = self
        
        addSubview(button)
        addSubview(countLabel)
        
        
        button.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = NSFont.systemFontOfSize(13)
        
        button.leftAnchor.constraintEqualToAnchor(leftAnchor, constant: ReactionCountView.labelRightPadding).active = true
        button.centerYAnchor.constraintEqualToAnchor(centerYAnchor ,constant: 1).active = true
        //        button.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        //        button.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        button.rightAnchor.constraintEqualToAnchor(countLabel.leftAnchor, constant: -ReactionCountView.buttonLabelPadding).active = true
        
        
        //        countLabel.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        //        countLabel.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        countLabel.centerYAnchor.constraintEqualToAnchor(centerYAnchor ,constant: 0).active = true
        countLabel.rightAnchor.constraintEqualToAnchor(rightAnchor, constant: -ReactionCountView.labelRightPadding).active = true
        
        countLabel.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        countLabel.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        countLabel.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        countLabel.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        
        button.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        button.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        icon = ""
        count = 0
    }
}
