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
    case repository, owner, label, milestone, issueState, unspecified
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
    @objc let type: SearchSuggestionResultType
    @objc let title: String
    
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
    case all, mentions, assignee, repository, label, author, milestone
}

class SearchSuggestionDataSource: NSObject {
    
    fileprivate static let maxPerSection: Int = 3
    
    fileprivate let searchAccessQueue = DispatchQueue(label: "co.hellocode.searchSuggestionDataSource.searchAccessQueue", attributes: [])
    fileprivate var searchQuery = ""
    fileprivate var results = [SearchSuggestionResultItem]()
    fileprivate let operationQueue = OperationQueue()
    // private let repositoryTrie = SRTrie()
    
    var resultCount: Int {
        return Int(results.count)
    }
    
    func resultAtIndex(_ index: Int) -> SearchSuggestionResultItem {
        return results[index]
    }
    
    func searchUsingQuery(_ queryText: String, onCompletion: @escaping ()->()) {
        searchAccessQueue.sync {
            self.searchQuery = queryText
            self.operationQueue.cancelAllOperations()
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let account = QContext.shared().currentAccount
            var query = "\(queryText)*"
            self.operationQueue.maxConcurrentOperationCount = 4
            
            
            // no:label, no:milestone, no:assignee
            var unspecified = [String]()
            if "no:assignee".hasPrefix(queryText.lowercased()) {
                unspecified.append("assignee")
            }
            
            if "no:milestone".hasPrefix(queryText.lowercased()) {
                unspecified.append("milestone")
            }
            
            if "no:label".hasPrefix(queryText.lowercased()) {
                unspecified.append("label")
            }
            
            // issue state
            var issueStates = [String]()
            if "open".hasPrefix(queryText.lowercased()) || "is:open".hasPrefix(queryText.lowercased()) {
                issueStates.append("open")
            }
            
            if "closed".hasPrefix(queryText.lowercased()) || "is:closed".hasPrefix(queryText.lowercased()) {
                issueStates.append("closed")
            }
            
            var suggestionType: SearchSuggestionType = .all
            
            if queryText.lowercased().hasPrefix("milestone:") || queryText.lowercased().hasPrefix("-milestone:") {
                suggestionType = .milestone
                query = (query as NSString).substring(from: 10)
                
            } else if queryText.lowercased().hasPrefix("assignee:") || queryText.lowercased().hasPrefix("-assignee:") || queryText.lowercased().hasPrefix("@") {
                suggestionType = .assignee
                if queryText.lowercased().hasPrefix("@") {
                    query = (query as NSString).substring(from: 1)
                } else {
                    query = (query as NSString).substring(from: 9)
                }
                
            } else if queryText.lowercased().hasPrefix("repo:") || queryText.lowercased().hasPrefix("-repo:") {
                suggestionType = .repository
                query = (query as NSString).substring(from: 5)
                
            } else if queryText.lowercased().hasPrefix("label:") || queryText.lowercased().hasPrefix("-label:") {
                suggestionType = .label
                query = (query as NSString).substring(from: 6)
                
            } else if queryText.lowercased().hasPrefix("author:") || queryText.lowercased().hasPrefix("-author:") {
                suggestionType = .author
                query = (query as NSString).substring(from: 7)
                
            } else if queryText.lowercased().hasPrefix("mentions:") || queryText.lowercased().hasPrefix("-mentions:") {
                suggestionType = .mentions
                query = (query as NSString).substring(from: 9)
            }
            
            // repository search
            var repositories = [String]()
            if suggestionType == .all || suggestionType == .repository {
                self.operationQueue.addOperation({
                    let searchResults = QRepositoryStore.searchRepositories(withQuery: query, forAccountId: account?.identifier)
                    let repoStrings = self.uniqueStringsForElements(searchResults!, stringExtractor: { (object) -> String? in
                        guard let repository = object as? QRepository else { return nil }
                        return repository.fullName
                    })
                    repositories.append(contentsOf: repoStrings)
                })
            }
            
            // milestone search
            var milestones = [String]()
            if suggestionType == .all || suggestionType == .milestone {
                self.operationQueue.addOperation({
                    let searchResults = QMilestoneStore.searchMilestone(withQuery: query, forAccountId: account?.identifier)
                    let milestoneStrings = self.uniqueStringsForElements(searchResults!, stringExtractor: { (object) -> String? in
                        guard let milestone = object as? QMilestone else { return nil }
                        return milestone.title
                    })
                    milestones.append(contentsOf: milestones)
                })
            }
            
            // owner search
            var owners = [String]()
            if suggestionType == .all || suggestionType == .assignee || suggestionType == .author || suggestionType == .mentions {
                self.operationQueue.addOperation({
                    let searchResults = QOwnerStore.searchUser(withQuery: query, forAccountId: account?.identifier)
                    let ownerStrings = self.uniqueStringsForElements(searchResults!, stringExtractor: { (object) -> String? in
                        guard let owner = object as? QOwner else { return nil }
                        return owner.login
                    })
                    owners.append(contentsOf: ownerStrings)
                })
            }
            
            // label search
            var labels = [String]()
            if suggestionType == .all || suggestionType == .label {
                self.operationQueue.addOperation({
                    if let searchResults = QLabelStore.searchLabels(withQuery: query, forAccountId: account?.identifier) as NSArray as? [QLabel] {
                        let labelStrings = self.uniqueStringsForElements(searchResults, stringExtractor: { (object) -> String? in
                            guard let label = object as? QLabel else { return nil }
                            return label.name
                        })
                        labels.append(contentsOf: labels)
                    }
                })
            }
            
            self.operationQueue.waitUntilAllOperationsAreFinished()
    
            self.searchAccessQueue.sync {
                guard self.searchQuery == queryText else {
                    return
                }
                var searchResults = [SearchSuggestionResultItem]()
                
                let spaceHeight: CGFloat = 10
                
                if unspecified.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "UNSPECIFIED"))
                    unspecified.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .unspecified, title: title))
                    })
                }
                
                if issueStates.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "ISSUE STATE"))
                    issueStates.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .issueState, title: title))
                    })
                }
                
                if repositories.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "REPOSITORY"))
                    repositories.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .repository, title: title))
                    })
                }
                
                if milestones.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "MILESTONE"))
                    milestones.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .milestone, title: title))
                    })
                }
                
                if owners.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "USER"))
                    owners.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .owner, title: title))
                    })
                }
                
                if labels.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                    searchResults.append(SearchSuggestionResultItemHeader(title: "LABEL"))
                    labels.forEach({ (title) in
                        searchResults.append(SearchSuggestionResultItemValue(type: .label, title: title))
                    })
                }
                
                if searchResults.count > 0 {
                    searchResults.append(BaseSpacerTableRowViewItem(spaceHeight: spaceHeight))
                }
                
                //  DDLogDebug("searchResults -> \(searchResults) for queryText \(queryText)")
                self.results = searchResults
            }
            
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
    
    
    fileprivate func uniqueStringsForElements(_ elements: [AnyObject], stringExtractor: ( (AnyObject) -> String?)) -> [String] {
        let orderedSet = NSMutableOrderedSet()
        for element in elements {
            guard orderedSet.count <= SearchSuggestionDataSource.maxPerSection else {
                break
            }
            if let title = stringExtractor(element) {
                orderedSet.add(title)
            }
        }
        
        var strings = [String]()
        if let orderedStrings = orderedSet.array as? [String] {
            strings.append(contentsOf: orderedStrings)
        }
        return strings
    }
}
