//
//  ReactionsViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRReactionsViewController)
class ReactionsViewController: NSViewController {
    
    @IBOutlet weak var thumbsUpCountView: ReactionCountView!
    @IBOutlet weak var thumbsDownCountView: ReactionCountView!
    @IBOutlet weak var laughCountView: ReactionCountView!
    @IBOutlet weak var hoorayCountView: ReactionCountView!
    @IBOutlet weak var confusedCountView: ReactionCountView!
    @IBOutlet weak var heartCountView: ReactionCountView!
    @IBOutlet weak var reactionsStackView: NSStackView!
    
    var commentInfo: QIssueCommentInfo? {
        didSet {
            reloadReactions()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reactionsStackView.wantsLayer = true
        reactionsStackView.layer?.borderColor = CashewColor.separatorColor().CGColor
        reactionsStackView.layer?.borderWidth = 1
        
        thumbsUpCountView.icon = "👍"
        thumbsUpCountView.content = "+1"
        thumbsDownCountView.icon = "👎"
        thumbsDownCountView.content = "-1"
        laughCountView.icon = "😄"
        laughCountView.content = "laugh"
        hoorayCountView.icon = "🎉"
        hoorayCountView.content = "hooray"
        confusedCountView.icon = "😕"
        confusedCountView.content = "confused"
        heartCountView.icon = "❤️"
        heartCountView.content = "heart"
    }
    
    var hasReactions: Bool {
        if let issue = commentInfo as? QIssue  {
            return (issue.thumbsUpCount + issue.thumbsDownCount + issue.laughCount + issue.hoorayCount + issue.confusedCount + issue.heartCount) > 0
        } else if let issueComment = commentInfo as? QIssueComment {
            return (issueComment.thumbsUpCount + issueComment.thumbsDownCount + issueComment.laughCount + issueComment.hoorayCount + issueComment.confusedCount + issueComment.heartCount) > 0
        }
        
        return false
    }
    
    func reloadReactions() {
        
        let buttons = [thumbsUpCountView, thumbsDownCountView, laughCountView, hoorayCountView, confusedCountView, heartCountView]
        
        guard let commentInfo = commentInfo else {
            let block = {
                buttons.forEach({ (btn) in
                    btn.commentInfo = nil
                    btn.hidden = true
                })
            }
            
            if NSThread.isMainThread() {
                block()
            } else {
                dispatch_sync(dispatch_get_main_queue(), block)
            }
            
            return
        }
        
        if let issue = commentInfo as? QIssue  {
            layoutViewsUsingReactions(issue.thumbsUpCount, thumbsDownCount: issue.thumbsDownCount, laughCount: issue.laughCount, hoorayCount: issue.hoorayCount, confusedCount: issue.confusedCount, heartCount: issue.heartCount)
        } else if let issueComment = commentInfo as? QIssueComment {
            layoutViewsUsingReactions(issueComment.thumbsUpCount, thumbsDownCount: issueComment.thumbsDownCount, laughCount: issueComment.laughCount, hoorayCount: issueComment.hoorayCount, confusedCount: issueComment.confusedCount, heartCount: issueComment.heartCount)
        }
    }
    
    func layoutViewsUsingReactions(thumbsUpCount: Int, thumbsDownCount: Int, laughCount: Int, hoorayCount: Int, confusedCount: Int, heartCount: Int) {

        let buttons = [thumbsUpCountView, thumbsDownCountView, laughCountView, hoorayCountView, confusedCountView, heartCountView]
        
        let block = { [weak self] in
            guard let strongSelf = self else { return }
            
            buttons.forEach({ (btn) in
                btn.commentInfo = strongSelf.commentInfo
            })
            
            strongSelf.thumbsUpCountView.hidden = (thumbsUpCount == 0)
            strongSelf.thumbsUpCountView.count = thumbsUpCount
            
            strongSelf.thumbsDownCountView.hidden = (thumbsDownCount == 0)
            strongSelf.thumbsDownCountView.count = thumbsDownCount
            
            strongSelf.laughCountView.hidden = (laughCount == 0)
            strongSelf.laughCountView.count = laughCount
            
            strongSelf.hoorayCountView.hidden = (hoorayCount == 0)
            strongSelf.hoorayCountView.count = hoorayCount
            
            strongSelf.confusedCountView.hidden = (confusedCount == 0)
            strongSelf.confusedCountView.count = confusedCount
            
            strongSelf.heartCountView.hidden = (heartCount == 0)
            strongSelf.heartCountView.count = heartCount
        }
        
        if NSThread.isMainThread() {
            block()
        } else {
            dispatch_sync(dispatch_get_main_queue(), block)
        }
    }
    
}
