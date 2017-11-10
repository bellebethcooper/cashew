//
//  MilestoneSearchablePickerViewController.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/1/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRMilestoneSearchablePickerViewController)
class MilestoneSearchablePickerViewController: BaseViewController {
    
    private var dataSource: MilestoneSearchablePickerDataSource?
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
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    var popoverBackgroundColorFixEnabed = true {
        didSet {
            self.searchablePickerController?.popoverBackgroundColorFixEnabed = popoverBackgroundColorFixEnabed
        }
    }
    
    private func reloadPicker() {
        guard let issue =  sourceIssue ?? QContext.sharedContext().currentIssues.first else {
            return
        }
        
        if let searchablePickerController = self.searchablePickerController {
            searchablePickerController.removeFromParentViewController()
            searchablePickerController.view.removeFromSuperview()
            self.searchablePickerController = nil;
        }
        
        let dataSource = MilestoneSearchablePickerDataSource(sourceIssue: self.sourceIssue)
        dataSource.sourceIssue = self.sourceIssue
        self.dataSource = dataSource
        
        dataSource.repository = issue.repository
        
        let pickerSearchFieldViewModel = PickerSearchFieldViewModel(placeHolderText: "Search")
        
        let viewModel = SearchablePickerViewModel(pickerSearchFieldViewModel: pickerSearchFieldViewModel) //, pickerToolbarViewModel: pickerToolbarViewModel)
        
        let searchablePickerController = SearchablePickerViewController(viewModel: viewModel, dataSource: dataSource)
        
        searchablePickerController.popoverBackgroundColorFixEnabed = popoverBackgroundColorFixEnabed
        searchablePickerController.disableButtonIfNoSelection = false
        searchablePickerController.registerAdapter(MilestoneSearchablePickerTableViewAdapter(dataSource: dataSource), clazz: QMilestone.self)
        searchablePickerController.showNumberOfSelections = true
        searchablePickerController.allowMultiSelection = false
        searchablePickerController.repositoryPopupButton.currentRepository = dataSource.repository
        
        searchablePickerController.onTappedItemBlock = { [weak self] (cell, item) in
            guard let cell = cell as? MilestoneSearchResultTableRowView, item = item as? QMilestone, dataSource = self?.dataSource else { return }
            
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MilestoneSearchablePickerViewController.issueSelectionChanged(_:)), name: kQContextIssueSelectionChangeNotification, object: nil)
        
        super.viewDidLoad()
        Analytics.logContentViewWithName(NSStringFromClass(MilestoneSearchablePickerViewController.self), contentType: nil, contentId: nil, customAttributes: nil)
        
        reloadPicker()
    }
    
    private func doSaveWithCompletion(completion: dispatch_block_t?) {
        
        guard let strongPickerController = searchablePickerController, dataSource = self.dataSource, selectionMap = dataSource.selectionMap else { return }
        
        strongPickerController.loading = true
        
        let operationQueue = NSOperationQueue()
        operationQueue.name = "co.cashewapp.MilestoneSearchablePickerViewController.doSave"
        operationQueue.maxConcurrentOperationCount = 2
        
        for (issue, milestoneSet) in selectionMap {
            let milestone =  milestoneSet.first
            guard issue.milestone != milestone else {
                DDLogDebug("Skipping milestone batch update for \(issue) because milestone \(milestone) matches issue milestone \(issue.milestone)")
                continue
            }
            
            operationQueue.addOperationWithBlock {
                let semaphore = dispatch_semaphore_create(0)
                let fullRepoName = issue.repository.fullName
                let sinceDate = issue.updatedAt
                let issueService = QIssuesService(forAccount: issue.account)
                
                Analytics.logCustomEventWithName("Changed Milestone", customAttributes: ["RepositoryName": fullRepoName])
                issueService.saveMilestoneNumber(milestone?.number, forRepository: issue.repository, number: issue.number, onCompletion: { [weak self] (issue, context, error) in
                    if let issue = issue as? QIssue {
                        self?.searchablePickerController?.syncIssueEventsForIssue(issue, sinceDate: sinceDate)
                        Analytics.logCustomEventWithName("Successful Changed Milestone", customAttributes: ["RepositoryName": fullRepoName])
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
                        DDLogDebug("Error updating milestone for \(issue) because \(error?.localizedDescription) error \(error)")
                        Analytics.logCustomEventWithName("Failed Changed Milestone", customAttributes: ["error": errorString, "RepositoryName": fullRepoName])
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
