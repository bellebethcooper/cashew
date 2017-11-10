//
//  EmbedLabelsInIssuesConversion.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/23/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

private struct MissingLabelsConversionIssue {
    let accountId: NSNumber
    let repositoryId: NSNumber
    let issueId: NSNumber
    // let searchKey: String
}

@objc(SREmbedLabelsInIssuesConversion)
class EmbedLabelsInIssuesConversion: NSObject {
    
    func runConversion() {
        DDLogDebug("Start EmbedLabelsInIssuesConversion")
        var issues = issuesWithNoEmbededLabel()
        while issues.count > 0 {
            
            issues.forEach({ (issue) in
                updateLabelsOnIssue(issue)
            })
            
            issues = issuesWithNoEmbededLabel()
        }
        DDLogDebug("END EmbedLabelsInIssuesConversion")
    }
    
    private func updateLabelsOnIssue(issue: MissingLabelsConversionIssue) {
        var labels = [String]()
        
        QBaseStore.doWriteInTransaction { (db, rollback) in
            do {
                let rs = try db.executeQuery("SELECT name FROM issue_label l WHERE l.account_id = ? AND l.repository_id = ? AND l.issue_id = ?", values: [issue.accountId, issue.repositoryId, issue.issueId])
                while rs.next() {
                    let name = rs.stringForColumn("name")
                    labels.append(name)
                }
                rs.close()
                
                
                let data = try NSJSONSerialization.dataWithJSONObject(labels, options: NSJSONWritingOptions())
                let json = NSString(data: data, encoding: NSUTF8StringEncoding)!
                
                try db.executeUpdate("UPDATE issue SET labels = ? WHERE  account_id = ? AND repository_id = ? AND identifier = ?", values: [json, issue.accountId, issue.repositoryId, issue.issueId])
                
            } catch {
                rollback.memory = true
            }
        }
        
    }
    
    private func issuesWithNoEmbededLabel() -> [MissingLabelsConversionIssue] {
        var issues = [MissingLabelsConversionIssue]()
        QBaseStore.doReadInTransaction { (db) in
            do {
                let rs = try db.executeQuery("SELECT account_id, repository_id, identifier FROM issue WHERE labels is null LIMIT 1000", values: [])
                while rs.next() {
                    let issue = MissingLabelsConversionIssue(accountId: NSNumber(int: rs.intForColumn("account_id")), repositoryId: NSNumber(int: rs.intForColumn("repository_id")), issueId: NSNumber(int: rs.intForColumn("identifier"))) //, searchKey: rs.stringForColumn("search_uniq_key"))
                    issues.append(issue)
                }
                rs.close()
            } catch {
                
            }
        }
        return issues
    }
    
}
