//
//  SearchSuggestionDataSource.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/17/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRSearchSuggestionResultType)
enum SearchSuggestionResultType: Int {
    case Repository, Owner, Label, Milestone, IssueState, Unspecified
}

@objc(SRSearchSuggestionResultItem)
protocol SearchSuggestionResultItem: NSObjectProtocol {
    
}

@objc(SRSearchSuggestionResultItemHeader)
class SearchSuggestionResultItemHeader: NSObject, SearchSuggestionResultItem {
    let title: String
    
    init(title: String) {
        self.title = title
        super.init()
    }
    
    override var description: String {
        return title
    }
}

extension BaseSpacerTableRowViewItem: SearchSuggestionResultItem  { }

@objc(SRSearchSuggestionResultItemValue)
class SearchSuggestionResultItemValue: NSObject, SearchSuggestionResultItem {
    let type: SearchSuggestionResultType
    let title: String
    
    init(type: SearchSuggestionResultType, title: String) {
        self.type = type
        self.title = title
        super.init()
    }
    
    override var description: String {
        return "\(title) - \(type)"
    }
}

private enum SearchSuggestionType {
    case All, Mentions, Assignee, Repository, Label, Author, Milestone
}

class SearchSuggestionDataSource: NSObject {
    
    private static let maxPerSection: Int = 3
    
    private let searchAccessQueue = dispatch_queue_create("com.simplerocket.searchSuggestionDataSource.searchAccessQueue", DISPATCH_QUEUE_SERIAL)
    private var searchQuery = ""
    private var results = [SearchSuggestionResultItem]()
    private let operationQueue = NSOperationQueue()
    // private let repositoryTrie = SRTrie()
    
    var resultCount: Int {
        return Int(results.count)
    }
    
    func resultAtIndex(index: Int) -> SearchSuggestionResultItem {
        return results[index]
    }
    
    func searchUsingQuery(queryText: String, onCompletion: dispatch_block_t) {
        dispatch_sync(searchAccessQueue) {
            self.searchQuery = queryText
            self.operationQueue.cancelAllOperations()
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            let account = QContext.sharedContext().currentAccount
            var query = "\(queryText)*"
            self.operationQueue.maxConcurrentOperationCount = 4
            
            
            // no:label, no:milestone, no:assignee
            var unspecified = [String]()
            if "no:assignee".hasPrefix(queryText.lowercaseString) {
                unspecified.append("assignee")
            }
            
            if "no:milestone".hasPrefix(queryText.lowercaseString) {
                unspecified.append("milestone")
            }
            
            if "no:label".hasPrefix(queryText.lowercaseString) {
                unspecified.append("label")
            }
            
            // issue state
            var issueStates = [String]()
            if "open".hasPrefix(queryText.lowercaseString) || "is:open".hasPrefix(queryText.lowercaseString) {
                issueStates.append("open")
            }
            
            if "closed".hasPrefix(queryText.lowercaseString) || "is:closed".hasPrefix(queryText.lowercaseString) {
                issueStates.append("closed")
            }
            
            var suggestionType: SearchSuggestionType = .All
            
            if queryText.lowercaseString.hasPrefix("milestone:") || queryText.lowercaseString.hasPrefix("-milestone:") {
                suggestionType = .Milestone
                query = (query as NSString).substringFromIndex(10)
                
            } else if queryText.lowercaseString.hasPrefix("assignee:") || queryText.lowercaseString.hasPrefix("-assignee:") || queryText.lowercaseString.hasPrefix("@") {
                suggestionType = .Assignee
                if queryText.lowercaseString.hasPrefix("@") {
                    query = (query as NSString).substringFromIndex(1)
                } else {
                    query = (query as NSString).substringFromIndex(9)
                }
                
            } else if queryText.lowercaseString.hasPrefix("repo:") || queryText.lowercaseString.hasPrefix("-repo:") {
                suggestionType = .Repository
                query = (query as NSString).substringFromIndex(5)
                
            } else if queryText.lowercaseString.hasPrefix("label:") || queryText.lowercaseString.hasPrefix("-label:") {
                suggestionType = .Label
                query = (query as NSString).substringFromIndex(6)
                
            } else if queryText.lowercaseString.hasPrefix("author:") || queryText.lowercaseString.hasPrefix("-author:") {
                suggestionType = .Author
                query = (query as NSString).substringFromIndex(7)
                
            } else if queryText.lowercaseString.hasPrefix("mentions:") || queryText.lowercaseString.hasPrefix("-mentions:") {
                suggestionType = .Mentions
                query = (query as NSString).substringFromIndex(9)
            }
            
            // repository search
            var repositories = [String]()
            if suggestionType == .All || suggestionType == .Repository {
                self.operationQueue.addOperationWithBlock({
                    let searchResults = QRepositoryStore.searchRepositoriesWithQuery(query, forAccountId: account.identifier)
                    let repoStrings = self.uniqueStringsForElements(searchResults, stringExtractor: { (object) -> String? in
                        guard let repository = object as? QRepository else { return nil }
                        return repository.fullName
                    })
                    repositories.appendContentsOf(repoStrings)
                })
            }
            
            // milestone search
            var milestones = [String]()
            if suggestionType == .All || suggestionType == .Milestone {
                self.operationQueue.addOperationWithBlock({
                    let searchResults = QMilestoneStore.searchMilestoneWithQuery(query, forAccountId: account.identifier)
                    let milestoneStrings = self.uniqueStringsForElements(searchResults, stringExtractor: { (object) -> String? in
                        guard let milestone = object as? QMilestone else { return nil }
                        return milestone.title
                    })
                    milestones.appendContentsOf(milestoneStrings)
                })
            }
            
            // owner search
            var owners = [String]()
            if suggestionType == .All || suggestionType == .Assignee || suggestionType == .Author || suggestionType == .Mentions {
                self.operationQueue.addOperationWithBlock({
                    let searchResults = QOwnerStore.searchUserWithQuery(query, forAccountId: account.identifier)
                    let ownerStrings = self.uniqueStringsForElements(searchResults, stringExtractor: { (object) -> String? in
                        guard let owner = object as? QOwner else { return nil }
                        return owner.login
                    })
                    owners.appendContentsOf(ownerStrings)
                })
            }
            
            // label search
            var labels = [String]()
            if suggestionType == .All || suggestionType == .Label {
                self.operationQueue.addOperationWithBlock({
                    if let searchResults = QLabelStore.searchLabelsWithQuery(query, forAccountId: account.identifier) as NSArray as? [QLabel] {
                        let labelStrings = self.uniqueStringsForElements(searchResults, stringExtractor: { (object) -> String? in
                            guard let label = object as? QLabel else { return nil }
                            return label.name
                        })
                        labels.appendContentsOf(labelStrings)
                    }
                })
            }
            
            self.operationQueue.waitUntilAllOperationsAreFinished()
    
            dispatch_sync(self.searchAccessQueue) {
                guard self.searchQuery == queryText else {
                    return
                }
                var searchResults = [SearchSuggestionResultItem]()
                
                let spaceHeight: CGFloat = 10
                
                if unspecified.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "UNSPECIFIED"))
                    unspecified.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .Unspecified, title: title))
                    })
                }
                
                if issueStates.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "ISSUE STATE"))
                    issueStates.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .IssueState, title: title))
                    })
                }
                
                if repositories.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "REPOSITORY"))
                    repositories.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .Repository, title: title))
                    })
                }
                
                if milestones.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "MILESTONE"))
                    milestones.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .Milestone, title: title))
                    })
                }
                
                if owners.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "USER"))
                    owners.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .Owner, title: title))
                    })
                }
                
                if labels.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "LABEL"))
                    labels.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .Label, title: title))
                    })
                }
                
                if searchResults.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                }
                
                //  DDLogDebug("searchResults -> \(searchResults) for queryText \(queryText)")
                self.results = searchResults
            }
            
            dispatch_async(dispatch_get_main_queue(), onCompletion)
        }
    }
    
    
    private func uniqueStringsForElements(elements: [AnyObject], stringExtractor: ( (AnyObject) -> String?)) -> [String] {
        let orderedSet = NSMutableOrderedSet()
        for element in elements {
            guard orderedSet.count <= SearchSuggestionDataSource.maxPerSection else {
                break
            }
            if let title = stringExtractor(element) {
                orderedSet.addObject(title)
            }
        }
        
        var strings = [String]()
        if let orderedStrings = orderedSet.array as? [String] {
            strings.appendContentsOf(orderedStrings)
        }
        return strings
    }
}
