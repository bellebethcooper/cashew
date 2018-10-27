//
//  ReactionCountView.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

//@objc(SRReactionCountView)
class ReactionCountView: BaseView {
    
    fileprivate static let buttonLabelPadding: CGFloat = 5
    fileprivate static let labelRightPadding: CGFloat = 10
    
    fileprivate lazy var reactionService: SRReactionsService = {
        return SRReactionsService(for: QContext.shared().currentAccount)
    }()
    
    let button = NSButton()
    let countLabel = BaseLabel()
    
    var content: String?
    var commentInfo: QIssueCommentInfo? /* {
        didSet {
            let userId = QContext.shared().currentAccount.userId
            guard let content = content else { return }
            
            if let issue = commentInfo as? QIssue {
                if let _ = SRIssueReactionStore.didUserId(userId, addReactionToIssue: issue, withContent: content) {
                    DispatchOnMainQueue({
                        self.backgroundColor = CashewColor.currentLineBackgroundColor()
                    })
                    
                } else {
                    DispatchOnMainQueue({
                        self.backgroundColor = NSColor.clear()
                    })
                }
                
            } else if let issueComment = commentInfo as? QIssueComment {
                if let _ = SRIssueCommentReactionStore.didUserId(userId, addReactionToIssueComment: issueComment, withContent: content) {
                    DispatchOnMainQueue({
                        self.backgroundColor = CashewColor.currentLineBackgroundColor()
                    })
                } else {
                    DispatchOnMainQueue({
                        self.backgroundColor = NSColor.clear()
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
    
    override func mouseDown(with theEvent: NSEvent) {
        super.mouseDown(with: theEvent)
        didClick()
    }
    
    @objc
    fileprivate func didClick() {
        let userId = QContext.shared().currentAccount.userId
        guard let content = content else { return }
        
        if let issue = commentInfo as? QIssue {
            
            var issuesReactionSet = Set<SRIssueReaction>()
            if let savedReactions = SRIssueReactionStore.issueReactions(for: issue) {
                savedReactions.forEach { (savedReaction) in
                    issuesReactionSet.insert(savedReaction)
                }
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
                
                if let reaction = SRIssueReactionStore.didUserId(userId, addReactionTo: issue, withContent: content) {
                    //DDLogDebug("issue.reaction \(reaction)")
                    self?.reactionService.deleteReactionWithId(reaction.identifier, onCompletion: { (obj, context, err) in
                        if  err == nil {
                            SRIssueReactionStore.delete(reaction)
                            QIssueStore.updateIssueReactionCounts(for: issue)
//                            DispatchOnMainQueue({
//                                self?.backgroundColor = NSColor.clear()
//                            })
                            
                        }
                        })
                } else {
                    self?.reactionService.createReactionForIssue(issue, content: content, onCompletion: { (reaction, context, err) in
                        if let reaction = reaction as? SRIssueReaction , err == nil {
                            SRIssueReactionStore.save(reaction)
                            QIssueStore.updateIssueReactionCounts(for: issue)
//                            DispatchOnMainQueue({
//                                self?.backgroundColor = CashewColor.currentLineBackgroundColor()
//                            })
                        }
                        })
                }
                
                
                })
            
        } else if let issueComment = commentInfo as? QIssueComment {
            
            var issueCommentsReactionSet = Set<SRIssueCommentReaction>()
            if let savedReactions = SRIssueCommentReactionStore.issueCommentReactions(for: issueComment) {
                savedReactions.forEach { (savedReaction) in
                    issueCommentsReactionSet.insert(savedReaction)
                }
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
                
                if let reaction = SRIssueCommentReactionStore.didUserId(userId, addReactionTo: issueComment, withContent: content) {
                    //DDLogDebug("issueComment.reaction \(reaction)")
                    self?.reactionService.deleteReactionWithId(reaction.identifier, onCompletion: { (obj, context, err) in
                        if err == nil {
                            SRIssueCommentReactionStore.delete(reaction)
                            QIssueCommentStore.updateIssueCommentReactionCounts(for: issueComment)
//                            DispatchOnMainQueue({
//                                self?.backgroundColor = NSColor.clear()
//                            })
                        }
                        })
                } else {
                    self?.reactionService.createReactionForIssueComment(issueComment, content: content, onCompletion: {  (reaction, context, err) in
                        if let reaction = reaction as? SRIssueCommentReaction , err == nil {
                            SRIssueCommentReactionStore.save(reaction)
                            QIssueCommentStore.updateIssueCommentReactionCounts(for: issueComment)
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
        
        backgroundColor = NSColor.clear
        
        button.isBordered = false
        button.wantsLayer = true
        button.font = NSFont.systemFont(ofSize: 15)
        button.setButtonType(.momentaryChange)
        button.action = #selector(ReactionCountView.didClick)
        button.target = self
        
        addSubview(button)
        addSubview(countLabel)
        
        
        button.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = NSFont.systemFont(ofSize: 13)
        
        button.leftAnchor.constraint(equalTo: leftAnchor, constant: ReactionCountView.labelRightPadding).isActive = true
        button.centerYAnchor.constraint(equalTo: centerYAnchor ,constant: 1).isActive = true
        //        button.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        //        button.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        button.rightAnchor.constraint(equalTo: countLabel.leftAnchor, constant: -ReactionCountView.buttonLabelPadding).isActive = true
        
        
        //        countLabel.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        //        countLabel.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        countLabel.centerYAnchor.constraint(equalTo: centerYAnchor ,constant: 0).isActive = true
        countLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -ReactionCountView.labelRightPadding).isActive = true
        
        countLabel.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        countLabel.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .vertical)
        countLabel.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .vertical)
        
        button.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        button.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        icon = ""
        count = 0
    }
}
