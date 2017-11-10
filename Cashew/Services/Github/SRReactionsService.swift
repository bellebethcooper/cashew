//
//  SRReactionsService.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import AFNetworking

class SRReactionsService: QBaseService {
    
    //GET /repos/:owner/:repo/issues/:number/reactions
    func reactionsForIssue(issue: QIssue, onCompletion: QServiceOnCompletion) {
        let reactionsSet = NSMutableOrderedSet()
        fetchReactionsForIssue(issue, pageNumber: 0, reactionsSet: reactionsSet, onCompletion: onCompletion)
    }
    
    private func fetchReactionsForIssue(issue: QIssue, pageNumber: Int, reactionsSet: NSMutableOrderedSet, onCompletion: QServiceOnCompletion) {
        
        let manager = httpSessionManager()
        
        manager.requestSerializer.setValue("application/vnd.github.squirrel-girl-preview", forHTTPHeaderField: "Accept")
        
        
        manager.GET("repos/\(issue.repository.owner.login)/\(issue.repository.name)/issues/\(issue.number)/reactions", parameters: ["page": pageNumber, "per_page": 100], progress: nil) { [weak self] (responseObject, context, err) in
            guard let responseArray = responseObject as? [NSDictionary] where err == nil else {
                onCompletion(nil, context, err)
                return;
            }
            
            //var reactions = [SRReaction]()
            responseArray.forEach({ (json) in
                let reaction = SRIssueReaction.fromJSON(json as [NSObject : AnyObject])
                reaction.repository = issue.repository
                reaction.account = issue.account
                reaction.issueNumber = issue.number
                
                reactionsSet.addObject(reaction)
                //reactions.append(reaction)
            })
            
            if let nextPageNumber = context.nextPageNumber {
                self?.fetchReactionsForIssue(issue, pageNumber: nextPageNumber.integerValue, reactionsSet: reactionsSet, onCompletion: onCompletion)
            } else {
                let reactionsArray = reactionsSet.array
                onCompletion(reactionsArray, context, nil)
            }            
        }
        
    }
    
    
    //POST /repos/:owner/:repo/issues/:number/reactions
    func createReactionForIssue(issue: QIssue, content: String, onCompletion: QServiceOnCompletion) {
        let manager = httpSessionManagerForRequestSerializer(AFJSONRequestSerializer())
        
        
        manager.requestSerializer.setValue("application/vnd.github.squirrel-girl-preview", forHTTPHeaderField: "Accept")
        
        manager.POST("repos/\(issue.repository.owner.login)/\(issue.repository.name)/issues/\(issue.number)/reactions", parameters: ["content": content], progress: nil) { (responseObject, context, err) in
            guard let json = responseObject as? NSDictionary where err == nil else {
                onCompletion(nil, context, err)
                return;
            }
            
            let reaction = SRIssueReaction.fromJSON(json as [NSObject : AnyObject])
            reaction.repository = issue.repository
            reaction.account = issue.account
            reaction.issueNumber = issue.number
            
            onCompletion(reaction, context, nil)
            
        }
    }
    
    
    //GET /repos/:owner/:repo/issues/comments/:id/reactions
    func reactionsForIssueComment(issueComment: QIssueComment, onCompletion: QServiceOnCompletion) {
        let reactionsSet = NSMutableOrderedSet()
        fetchReactionsForIssueComment(issueComment, pageNumber: 0, reactionsSet: reactionsSet, onCompletion: onCompletion)
    }
    
    private func fetchReactionsForIssueComment(issueComment: QIssueComment, pageNumber: Int, reactionsSet: NSMutableOrderedSet, onCompletion: QServiceOnCompletion) {
        
        let manager = httpSessionManager()
        
        manager.requestSerializer.setValue("application/vnd.github.squirrel-girl-preview", forHTTPHeaderField: "Accept")
        
        
        manager.GET("repos/\(issueComment.repo().owner.login)/\(issueComment.repo().name)/issues/comments/\(issueComment.identifier)/reactions", parameters: ["page": pageNumber, "per_page": 100], progress: nil) { [weak self] (responseObject, context, err) in
            guard let responseArray = responseObject as? [NSDictionary] where err == nil else {
                onCompletion(nil, context, err)
                return;
            }
            
            //var reactions = [SRReaction]()
            responseArray.forEach({ (json) in
                let reaction = SRIssueCommentReaction.fromJSON(json as [NSObject : AnyObject])
                reaction.repository = issueComment.repo()
                reaction.account = issueComment.repo().account
                reaction.issueCommentIdentifier = issueComment.identifier
                
                reactionsSet.addObject(reaction)
                //reactions.append(reaction)
            })
            
            if let nextPageNumber = context.nextPageNumber {
                self?.fetchReactionsForIssueComment(issueComment, pageNumber: nextPageNumber.integerValue, reactionsSet: reactionsSet, onCompletion: onCompletion)
            } else {
                let reactionsArray = reactionsSet.array
                onCompletion(reactionsArray, context, nil)
            }
        }
        
    }
    
    
    //POST  /repos/:owner/:repo/issues/comments/:id/reactions
    func createReactionForIssueComment(issueComment: QIssueComment, content: String, onCompletion: QServiceOnCompletion) {
        let manager = httpSessionManagerForRequestSerializer(AFJSONRequestSerializer())
        
        
        manager.requestSerializer.setValue("application/vnd.github.squirrel-girl-preview", forHTTPHeaderField: "Accept")
        
        manager.POST("repos/\(issueComment.repo().owner.login)/\(issueComment.repo().name)/issues/comments/\(issueComment.identifier)/reactions", parameters: ["content": content], progress: nil) { (responseObject, context, err) in
            guard let json = responseObject as? NSDictionary where err == nil else {
                onCompletion(nil, context, err)
                return;
            }
            
            let reaction = SRIssueCommentReaction.fromJSON(json as [NSObject : AnyObject])
            reaction.repository = issueComment.repo()
            reaction.account = issueComment.repo().account
            reaction.issueCommentIdentifier = issueComment.identifier
            
            
            
            onCompletion(reaction, context, nil)
            
        }
    }
    
    //DELETE /reactions/:id
    func deleteReactionWithId(identifier: NSNumber, onCompletion: QServiceOnCompletion) {
        let manager = httpSessionManager()
        
        manager.requestSerializer.setValue("application/vnd.github.squirrel-girl-preview", forHTTPHeaderField: "Accept")
        
        manager.DELETE("reactions/\(identifier)", parameters: nil) { (responseObject, context, err) in
            onCompletion(responseObject, context, err)
        }
    }
    
}