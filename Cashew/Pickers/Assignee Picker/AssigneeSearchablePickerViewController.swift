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
    
    private var dataSource: AssigneeSearchablePickerDataSource?
    private var searchablePickerController: SearchablePickerViewController?
    
    weak var popover: NSPopover?
    var sourceIssue: QIssue? {
        didSet {
            if let dataSource = dataSource {
                dataSource.sourceIssue = sourceIssue
            }
        }
    }
    
    @objc
    private func issueSelectionChanged(notification: NSNotification) {
        guard let searchablePickerController = searchablePickerController where searchablePickerController.dirtyFlag else {
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
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func reloadPicker() {
        guard let issue = (sourceIssue ?? QContext.sharedContext().currentIssues.first) else {
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
            guard let cell = cell as? AssigneeSearchResultTableRowView, item = item as? QOwner, dataSource = self?.dataSource else { return }
            
            if dataSource.isPartialSelection(item) {
                cell.accessoryView = GreenDottedView()
                cell.checked = true
            } else {
                cell.accessoryView = GreenCheckboxView()
                cell.checked = dataSource.isSelectedItem(item) ?? false
            }
            cell.accessoryView?.disableThemeObserver = true
            cell.accessoryView?.backgroundColor = NSColor.clearColor()
            cell.needsLayout = true
            cell.layoutSubtreeIfNeeded()
        }
        
        searchablePickerController.onDoneButtonClick = { [weak searchablePickerController, weak self] in
            guard let strongPickerController = searchablePickerController, strongSelf = self else { return }
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AssigneeSearchablePickerViewController.issueSelectionChanged(_:)), name: kQContextIssueSelectionChangeNotification, object: nil)
        
        super.viewDidLoad()
        Analytics.logContentViewWithName(NSStringFromClass(AssigneeSearchablePickerViewController.self), contentType: nil, contentId: nil, customAttributes: nil)
        
        reloadPicker()
    }
    
    private func doSaveWithCompletion(completion: dispatch_block_t?) {
        
        guard let strongPickerController = searchablePickerController, dataSource = self.dataSource, selectionMap = dataSource.selectionMap, userToRepoMap = dataSource.userToRepositoryMap else { return }
        
        strongPickerController.loading = true
        
        let operationQueue = NSOperationQueue()
        operationQueue.name = "co.cashewapp.AssigneeSearchablePickerViewController.doSave"
        operationQueue.maxConcurrentOperationCount = 2
        
        for (issue, assigneeSet) in selectionMap {
            let assignee =  assigneeSet.first
            guard issue.assignee != assignee else {
                continue
            }
            
            if let assignee = assignee, assigneeRepos = userToRepoMap[assignee] where !assigneeRepos.contains(issue.repository) {
                continue
            }
            
            operationQueue.addOperationWithBlock {
                let semaphore = dispatch_semaphore_create(0)
                let fullRepoName = issue.repository.fullName
                let sinceDate = issue.updatedAt
                let issueService = QIssuesService(forAccount: issue.account)
                Analytics.logCustomEventWithName("Changed Assignee", customAttributes: ["RepositoryName": fullRepoName])
                issueService.saveAssigneeLogin(assignee?.login, forRepository: issue.repository, number: issue.number, onCompletion: { [weak self] (issue, context, error) in
                    if let issue = issue as? QIssue {
                        Analytics.logCustomEventWithName("Successful Changed Assignee", customAttributes: ["RepositoryName": fullRepoName])
                        self?.searchablePickerController?.syncIssueEventsForIssue(issue, sinceDate: sinceDate)
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                            QIssueStore.saveIssue(issue)
                        })
                    } else {
                        let errorString: String
                        if let error = error {
                            errorString = error.localizedDescription
                        } else {
                            errorString = ""
                        }
                        Analytics.logCustomEventWithName("Failed Changed Assignee", customAttributes: ["error": errorString, "RepositoryName": fullRepoName])
                    }
                    dispatch_semaphore_signal(semaphore)
                    })
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            }
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        strongPickerController.loading = false
        
        if let completion = completion {
            completion()
        }
    }
    
}
