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
    
    fileprivate var results = [RepositoryPickerItem]()
    fileprivate var recentRequestId: Int = 0
    fileprivate var selectedRepositoriesSet = NSMutableSet()
    
    var sourceIssue: QIssue?
    
    @objc
    var selectedRepositories: [RepositoryPickerItem] {
        if let repos = selectedRepositoriesSet.allObjects as? [QRepository] {
            return repos
        } else {
            return [RepositoryPickerItem]()
        }
    }
    
    fileprivate func selectRepository(_ repo: RepositoryPickerItem) {
        guard repo is QRepository else { return }
        selectedRepositoriesSet.add(repo)
    }
    
    fileprivate func unselectRepository(_ repo: RepositoryPickerItem) {
        guard repo is QRepository else { return }
        selectedRepositoriesSet.remove(repo)
    }
    
    fileprivate func isSelectedRepository(_ repo: RepositoryPickerItem)  -> Bool {
        guard repo is QRepository else { return false }
        return selectedRepositoriesSet.contains(repo)
    }
    
    
    // MARK - SearchablePickerDataSource
    
    var allowResetToOriginal: Bool = false
    var repository: QRepository? = nil
    
    var listOfRepositories: [QRepository] {
        return [QRepository]()
    }
    
    var selectedIndexes: IndexSet {
        let set = NSMutableIndexSet()
        for (i , repo) in results.enumerated() {
            guard repo is QRepository else { continue }
            if selectedRepositoriesSet.contains(results[i]) {
                set.add(i)
            }
        }
        return set as IndexSet
    }
    
    var mode: SearchablePickerDataSourceMode = .searchResults {
        didSet {
            switch mode {
            case .selectedItems:
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
    
    func selectItem(_ item: AnyObject) {
        if let repo = item as? QRepository {
            selectRepository(repo)
        }
    }
    
    func unselectItem(_ item: AnyObject) {
        if let repo = item as? QRepository {
            unselectRepository(repo)
        }
    }
    
    func isSelectedItem(_ item: AnyObject) -> Bool {
        if let repo = item as? QRepository {
            return isSelectedRepository(repo)
        }
        return false
    }
    
    var numberOfRows: Int {
        return results.count
    }
    
    func itemAtIndex(_ index: Int) -> AnyObject {
        return results[index]
    }
    
    func search(_ string: String, onCompletion: @escaping ()->()) {
        
        mode = .searchResults
        let service = QRepositoriesService(for: QContext.shared().currentAccount)
        recentRequestId += 1
        service.searchRepositories(withQuery: string, pageNumber: 0, pageSize: 100, contextId: recentRequestId as NSNumber) { [weak self] (returnedObject, context, err) in
            guard let strongSelf = self,
                strongSelf.recentRequestId == context.contextId?.intValue && strongSelf.mode == .searchResults else {
                DispatchQueue.main.async {
                    onCompletion()
                }
                return
            }
            
            if var repositories = returnedObject as? [RepositoryPickerItem] {
                repositories.insert(OrganizationPrivateRepositoryPermissionViewModel(), at: 0)
                strongSelf.results = repositories
                DispatchQueue.main.async {
                    onCompletion()
                }
                return
            } else {
                var repositories = [RepositoryPickerItem]()
                repositories.insert(OrganizationPrivateRepositoryPermissionViewModel(), at: 0)
                strongSelf.results = repositories
                DispatchQueue.main.async {
                    onCompletion()
                }
            }
        }
    }
    
    func defaults(_ onCompletion: @escaping ()->()) {
        
        mode = .defaultResults
        let service = QRepositoriesService(for: QContext.shared().currentAccount)
        service.repositoriesForCurrentUser(withPageNumber: 1, pageSize: 100) { [weak self] (returnedObject,
            context, err) in
            guard let strongSelf = self,
                strongSelf.mode == .defaultResults else {
                DispatchQueue.main.async {
                    onCompletion()
                }
                return
            }
            
            if var repositories = returnedObject as? [RepositoryPickerItem] {
                repositories.insert(OrganizationPrivateRepositoryPermissionViewModel(), at: 0)
                strongSelf.results = repositories
                DispatchQueue.main.async {
                    onCompletion()
                }
                return
            } else {
                var repositories = [RepositoryPickerItem]()
                repositories.insert(OrganizationPrivateRepositoryPermissionViewModel(), at: 0)
                strongSelf.results = repositories
                DispatchQueue.main.async {
                    onCompletion()
                }
            }
        }
    }
    
    
}
