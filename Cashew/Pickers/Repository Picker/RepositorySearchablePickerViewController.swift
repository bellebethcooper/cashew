//
//  RepositorySearchablePickerViewController.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRRepositorySearchablePickerViewController)
class RepositorySearchablePickerViewController: BaseViewController {
    
    fileprivate var dataSource: RepositorySearchablePickerDataSource? = RepositorySearchablePickerDataSource()
    fileprivate var searchablePickerController: SearchablePickerViewController?
    
    weak var popover: NSPopover?
    
    @objc
    fileprivate func issueSelectionChanged(_ notification: Notification) {
        reloadPicker()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    var popoverBackgroundColorFixEnabed = true
    
    fileprivate func reloadPicker() {
        if let searchablePickerController = self.searchablePickerController {
            searchablePickerController.removeFromParent()
            searchablePickerController.view.removeFromSuperview()
            self.searchablePickerController = nil;
        }
        
        let dataSource = RepositorySearchablePickerDataSource()

        self.dataSource = dataSource
        
        let pickerSearchFieldViewModel = PickerSearchFieldViewModel(placeHolderText: "Search")
        
        let viewModel = SearchablePickerViewModel(pickerSearchFieldViewModel: pickerSearchFieldViewModel)
        
        let searchablePickerController = SearchablePickerViewController(viewModel: viewModel, dataSource: dataSource)
        
        let adapter = RepositorySearchablePickerTableViewAdapter(dataSource: dataSource)
        searchablePickerController.popoverBackgroundColorFixEnabed = popoverBackgroundColorFixEnabed
        searchablePickerController.registerAdapter(adapter, clazz: OrganizationPrivateRepositoryPermissionViewModel.self)
        searchablePickerController.registerAdapter(adapter, clazz: QRepository.self)
        searchablePickerController.showNumberOfSelections = true
        searchablePickerController.onDoneButtonClick = { [weak searchablePickerController, weak self] in
            guard let strongPickerController = searchablePickerController, let strongSelf = self, let dataSource = strongSelf.dataSource else { return }
            
            strongPickerController.loading = true
            let repositories = dataSource.selectedRepositories
            
            for repository in repositories {
                guard let repo = repository as? QRepository else { continue }
                QRepositoryStore.save(repo)
            }
            
            if let popover = self?.popover {
                popover.close()
            } else {
                strongPickerController.view.window?.close()
            }
        }
        
        self.searchablePickerController = searchablePickerController
        
        addChild(searchablePickerController);
        
        view.addSubview(searchablePickerController.view)
        searchablePickerController.view.pinAnchorsToSuperview()
    }
    
    fileprivate func setupThemeObserver() {
        
        if let view = self.view as? BaseView {
            view.disableThemeObserver = true
            view.shouldAllowVibrancy = false
            
            if UserDefaults.themeMode() == .dark {
                view.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                view.backgroundColor = CashewColor.backgroundColor()
            }
        }
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self, let view = strongSelf.view as? BaseView else {
                return
            }
            
            if mode == .dark {
                view.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                view.backgroundColor = CashewColor.backgroundColor()
            }
        }
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(RepositorySearchablePickerViewController.issueSelectionChanged(_:)), name: NSNotification.Name.qContextIssueSelectionChange, object: nil)
        
        super.viewDidLoad()    
        reloadPicker()
        
        setupThemeObserver()
    }
    
}


