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
    
    private var dataSource: RepositorySearchablePickerDataSource? = RepositorySearchablePickerDataSource()
    private var searchablePickerController: SearchablePickerViewController?
    
    weak var popover: NSPopover?
    
    @objc
    private func issueSelectionChanged(notification: NSNotification) {
        reloadPicker()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    var popoverBackgroundColorFixEnabed = true
    
    private func reloadPicker() {
        if let searchablePickerController = self.searchablePickerController {
            searchablePickerController.removeFromParentViewController()
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
            guard let strongPickerController = searchablePickerController, strongSelf = self, dataSource = strongSelf.dataSource else { return }
            
            strongPickerController.loading = true
            let repositories = dataSource.selectedRepositories
            
            for repository in repositories {
                guard let repo = repository as? QRepository else { continue }
                Analytics.logCustomEventWithName("Added Repository", customAttributes: ["RepositoryName": repo.fullName])
                QRepositoryStore.saveRepository(repo)
            }
            
            if let popover = self?.popover {
                popover.close()
            } else {
                strongPickerController.view.window?.close()
            }
        }
        
        self.searchablePickerController = searchablePickerController
        
        addChildViewController(searchablePickerController);
        
        view.addSubview(searchablePickerController.view)
        searchablePickerController.view.pinAnchorsToSuperview()
    }
    
    private func setupThemeObserver() {
        
        if let view = self.view as? BaseView {
            view.disableThemeObserver = true
            view.shouldAllowVibrancy = false
            
            if NSUserDefaults.themeMode() == .Dark {
                view.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                view.backgroundColor = CashewColor.backgroundColor()
            }
        }
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self, view = strongSelf.view as? BaseView else {
                return
            }
            
            if mode == .Dark {
                view.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                view.backgroundColor = CashewColor.backgroundColor()
            }
        }
    }
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RepositorySearchablePickerViewController.issueSelectionChanged(_:)), name: kQContextIssueSelectionChangeNotification, object: nil)
        
        super.viewDidLoad()
        Analytics.logContentViewWithName(NSStringFromClass(RepositorySearchablePickerViewController.self), contentType: nil, contentId: nil, customAttributes: nil)        
        reloadPicker()
        
        setupThemeObserver()
    }
    
}


