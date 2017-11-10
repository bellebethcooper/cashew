//
//  RepositorySearchablePickerDataSource.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/29/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRRepositoryPickerItem)
protocol RepositoryPickerItem: NSObjectProtocol { }
extension OrganizationPrivateRepositoryPermissionViewModel: RepositoryPickerItem { }
extension QRepository: RepositoryPickerItem { }

@objc(SRRepositorySearchablePickerDataSource)
class RepositorySearchablePickerDataSource: NSObject, SearchablePickerDataSource {
    
    private var results = [RepositoryPickerItem]()
    private var recentRequestId: Int = 0
    private var selectedRepositoriesSet = NSMutableSet()
    
    var sourceIssue: QIssue?
    
    @objc
    var selectedRepositories: [RepositoryPickerItem] {
        if let repos = selectedRepositoriesSet.allObjects as? [QRepository] {
            return repos
        } else {
            return [RepositoryPickerItem]()
        }
    }
    
    private func selectRepository(repo: RepositoryPickerItem) {
        guard repo is QRepository else { return }
        selectedRepositoriesSet.addObject(repo)
    }
    
    private func unselectRepository(repo: RepositoryPickerItem) {
        guard repo is QRepository else { return }
        selectedRepositoriesSet.removeObject(repo)
    }
    
    private func isSelectedRepository(repo: RepositoryPickerItem)  -> Bool {
        guard repo is QRepository else { return false }
        return selectedRepositoriesSet.containsObject(repo)
    }
    
    
    // MARK - SearchablePickerDataSource
    
    var allowResetToOriginal: Bool = false
    var repository: QRepository? = nil
    
    var listOfRepositories: [QRepository] {
        return [QRepository]()
    }
    
    var selectedIndexes: NSIndexSet {
        let set = NSMutableIndexSet()
        for (i , repo) in results.enumerate() {
            guard repo is QRepository else { continue }
            if selectedRepositoriesSet.containsObject(results[i]) {
                set.addIndex(i)
            }
        }
        return set
    }
    
    var mode: SearchablePickerDataSourceMode = .SearchResults {
        didSet {
            switch mode {
            case .SelectedItems:
                if let selectedItems = selectedRepositoriesSet.allObjects as? [RepositoryPickerItem] {
                    results = selectedItems
                }
                
            default:
                results = [RepositoryPickerItem]()
            }
        }
    }
    
    func resetToOriginal() {
        
    }
    
    func clearSelection() {
        selectedRepositoriesSet.removeAllObjects()
        
    }
    
    var selectionCount: Int {
        return selectedRepositoriesSet.count
    }
    
    func selectItem(item: AnyObject) {
        if let repo = item as? QRepository {
            selectRepository(repo)
        }
    }
    
    func unselectItem(item: AnyObject) {
        if let repo = item as? QRepository {
            unselectRepository(repo)
        }
    }
    
    func isSelectedItem(item: AnyObject) -> Bool {
        if let repo = item as? QRepository {
            return isSelectedRepository(repo)
        }
        return false
    }
    
    var numberOfRows: Int {
        return results.count
    }
    
    func itemAtIndex(index: Int) -> AnyObject {
        return results[index]
    }
    
    func search(string: String, onCompletion: dispatch_block_t) {
        
        mode = .SearchResults
        let service = QRepositoriesService(forAccount: QContext.sharedContext().currentAccount)
        recentRequestId += 1
        service.searchRepositoriesWithQuery(string, pageNumber: 0, pageSize: 100, contextId: recentRequestId) { [weak self] (returnedObject, context, err) in
            guard let strongSelf = self where strongSelf.recentRequestId == context.contextId?.integerValue && strongSelf.mode == .SearchResults else {
                dispatch_async(dispatch_get_main_queue(), {
                    onCompletion()
                })
                return
            }
            
            if var repositories = returnedObject as? [RepositoryPickerItem] {
                repositories.insert(OrganizationPrivateRepositoryPermissionViewModel(), atIndex: 0)
                strongSelf.results = repositories
                dispatch_async(dispatch_get_main_queue(), {
                    onCompletion()
                })
                return
            } else {
                var repositories = [RepositoryPickerItem]()
                repositories.insert(OrganizationPrivateRepositoryPermissionViewModel(), atIndex: 0)
                strongSelf.results = repositories
                dispatch_async(dispatch_get_main_queue(), {
                    onCompletion()
                })
            }
        }
    }
    
    func defaults(onCompletion: dispatch_block_t) {
        
        mode = .DefaultResults
        let service = QRepositoriesService(forAccount: QContext.sharedContext().currentAccount)
        service.repositoriesForCurrentUserWithPageNumber(1, pageSize: 100) { [weak self] (returnedObject: AnyObject?, context: QServiceResponseContext, err: NSError?) -> Void in

            guard let strongSelf = self where strongSelf.mode == .DefaultResults else {
                dispatch_async(dispatch_get_main_queue(), {
                    onCompletion()
                })
                return
            }
            
            if var repositories = returnedObject as? [RepositoryPickerItem] {
                repositories.insert(OrganizationPrivateRepositoryPermissionViewModel(), atIndex: 0)
                strongSelf.results = repositories
                dispatch_async(dispatch_get_main_queue(), {
                    onCompletion()
                })
                return
            } else {
                var repositories = [RepositoryPickerItem]()
                repositories.insert(OrganizationPrivateRepositoryPermissionViewModel(), atIndex: 0)
                strongSelf.results = repositories
                dispatch_async(dispatch_get_main_queue(), {
                    onCompletion()
                })
            }
        }
    }
    
    
}
