//
//  AssigneeSearchablePickerViewController.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/2/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRAssigneeSearchablePickerViewController)
class AssigneeSearchablePickerViewController: BaseViewController {
    
    fileprivate var dataSource: AssigneeSearchablePickerDataSource?
    fileprivate var searchablePickerController: SearchablePickerViewController?
    
    weak var popover: NSPopover?
    var sourceIssue: QIssue? {
        didSet {
            if let dataSource = dataSource {
                dataSource.sourceIssue = sourceIssue
            }
        }
    }
    
    @objc
    fileprivate func issueSelectionChanged(_ notification: Notification) {
        guard let searchablePickerController = searchablePickerController , searchablePickerController.dirtyFlag else {
            reloadPicker()
            return
        }
        
        doSaveWithCompletion({
            self.reloadPicker()
        })
    }
    
    var popoverBackgroundColorFixEnabed = true {
        didSet {
            self.searchablePickerController?.popoverBackgroundColorFixEnabed = popoverBackgroundColorFixEnabed
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func reloadPicker() {
        guard let issue = (sourceIssue ?? QContext.shared().currentIssues.first) else {
            return
        }
        
        if let searchablePickerController = self.searchablePickerController {
            searchablePickerController.removeFromParentViewController()
            searchablePickerController.view.removeFromSuperview()
            self.searchablePickerController = nil;
        }
        
        let dataSource = AssigneeSearchablePickerDataSource(sourceIssue: sourceIssue)
        dataSource.sourceIssue = self.sourceIssue
        self.dataSource = dataSource
        
        dataSource.repository = issue.repository
        
        let pickerSearchFieldViewModel = PickerSearchFieldViewModel(placeHolderText: "Search")
        
        // let pickerToolbarViewModel = PickerToolbarViewModel(leftButtonViewModel: nil, rightButtonViewModel: rightButtonModel)
        
        let viewModel = SearchablePickerViewModel(pickerSearchFieldViewModel: pickerSearchFieldViewModel) //, pickerToolbarViewModel: pickerToolbarViewModel)
        
        let searchablePickerController = SearchablePickerViewController(viewModel: viewModel, dataSource: dataSource)
        
        searchablePickerController.popoverBackgroundColorFixEnabed = popoverBackgroundColorFixEnabed
        searchablePickerController.disableButtonIfNoSelection = false
        searchablePickerController.registerAdapter(AssigneeSearchablePickerTableViewAdapter(dataSource: dataSource), clazz: QOwner.self)
        searchablePickerController.showNumberOfSelections = true
        searchablePickerController.allowMultiSelection = false
        searchablePickerController.repositoryPopupButton.currentRepository = dataSource.repository
        
        searchablePickerController.onTappedItemBlock = { [weak self] (cell, item) in
            guard let cell = cell as? AssigneeSearchResultTableRowView, let item = item as? QOwner, let dataSource = self?.dataSource else { return }
            
            if dataSource.isPartialSelection(item) {
                cell.accessoryView = GreenDottedView()
                cell.checked = true
            } else {
                cell.accessoryView = GreenCheckboxView()
                cell.checked = dataSource.isSelectedItem(item) ?? false
            }
            cell.accessoryView?.disableThemeObserver = true
            cell.accessoryView?.backgroundColor = NSColor.clear
            cell.needsLayout = true
            cell.layoutSubtreeIfNeeded()
        }
        
        searchablePickerController.onDoneButtonClick = { [weak searchablePickerController, weak self] in
            guard let strongPickerController = searchablePickerController, let strongSelf = self else { return }
            strongSelf.doSaveWithCompletion({
                if let popover = strongSelf.popover {
                    popover.close()
                } else {
                    strongPickerController.view.window?.close()
                }
            })
        }
        
        self.searchablePickerController = searchablePickerController
        
        addChildViewController(searchablePickerController);
        
        view.addSubview(searchablePickerController.view)
        searchablePickerController.view.pinAnchorsToSuperview()
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(AssigneeSearchablePickerViewController.issueSelectionChanged(_:)), name: NSNotification.Name.qContextIssueSelectionChange, object: nil)
        
        super.viewDidLoad()
        Analytics.logContentViewWithName(NSStringFromClass(AssigneeSearchablePickerViewController.self), contentType: nil, contentId: nil, customAttributes: nil)
        
        reloadPicker()
    }
    
    fileprivate func doSaveWithCompletion(_ completion: (()->())?) {
        
        guard let strongPickerController = searchablePickerController, let dataSource = self.dataSource, let selectionMap = dataSource.selectionMap, let userToRepoMap = dataSource.userToRepositoryMap else { return }
        
        strongPickerController.loading = true
        
        let operationQueue = OperationQueue()
        operationQueue.name = "co.cashewapp.AssigneeSearchablePickerViewController.doSave"
        operationQueue.maxConcurrentOperationCount = 2
        
        for (issue, assigneeSet) in selectionMap {
            let assignee =  assigneeSet.first
            guard issue.assignee != assignee else {
                continue
            }
            
            if let assignee = assignee,
                let assigneeRepos = userToRepoMap[assignee],
                !assigneeRepos.contains(issue.repository) {
                continue
            }
            
            operationQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                let fullRepoName = issue.repository.fullName
                let sinceDate = issue.updatedAt
                let issueService = QIssuesService(for: issue.account)
                Analytics.logCustomEventWithName("Changed Assignee", customAttributes: ["RepositoryName": fullRepoName as AnyObject])
                issueService.saveAssigneeLogin(assignee?.login, for: issue.repository, number: issue.number, onCompletion: { [weak self] (issue, context, error) in
                    if let issue = issue as? QIssue {
                        Analytics.logCustomEventWithName("Successful Changed Assignee", customAttributes: ["RepositoryName": fullRepoName as AnyObject])
                        self?.searchablePickerController?.syncIssueEventsForIssue(issue, sinceDate: sinceDate)
                        DispatchQueue.global(qos: .userInitiated).async {
                            QIssueStore.save(issue)
                        }
                    } else {
                        let errorString: String
                        if let error = error {
                            errorString = error.localizedDescription
                        } else {
                            errorString = ""
                        }
                        Analytics.logCustomEventWithName("Failed Changed Assignee", customAttributes: ["error": errorString as AnyObject, "RepositoryName": fullRepoName as AnyObject])
                    }
                    semaphore.signal()
                    })
                semaphore.wait(timeout: .distantFuture)
            }
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        strongPickerController.loading = false
        
        if let completion = completion {
            completion()
        }
    }
    
}
