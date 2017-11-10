//
//  RepositorySearchablePickerViewController.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/30/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRLabelSearchablePickerViewController)
class LabelSearchablePickerViewController: BaseViewController {
    
    private var dataSource: LabelSearchablePickerDataSource?
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
        guard let issue = sourceIssue ?? QContext.sharedContext().currentIssues.first else {
            return
        }
        
        //        if let _ = self.dataSource, searchablePickerController = self.searchablePickerController  {
        //            searchablePickerController.resetSelectionToOriginal(issue.repository)
        //            return
        //        }
        
        let dataSource = LabelSearchablePickerDataSource(sourceIssue: self.sourceIssue)
        dataSource.sourceIssue = self.sourceIssue
        self.dataSource = dataSource
        dataSource.repository = issue.repository
        
        let pickerSearchFieldViewModel = PickerSearchFieldViewModel(placeHolderText: "Search")
        
        // let pickerToolbarViewModel = PickerToolbarViewModel(leftButtonViewModel: nil, rightButtonViewModel: rightButtonModel)
        
        let viewModel = SearchablePickerViewModel(pickerSearchFieldViewModel: pickerSearchFieldViewModel) //, pickerToolbarViewModel: pickerToolbarViewModel)
        
        let searchablePickerController = SearchablePickerViewController(viewModel: viewModel, dataSource: dataSource)
        
        searchablePickerController.popoverBackgroundColorFixEnabed = popoverBackgroundColorFixEnabed
        searchablePickerController.registerAdapter(LabelSearchablePickerTableViewAdapter(dataSource: dataSource), clazz: QLabel.self)
        searchablePickerController.showNumberOfSelections = true
        searchablePickerController.onTappedItemBlock = { [weak self] (cell, item) in
            guard let cell = cell as? LabelSearchResultTableRowView, item = item as? QLabel, dataSource = self?.dataSource else { return }
            
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
        
        searchablePickerController.disableButtonIfNoSelection = false
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
        
        addChildViewController(searchablePickerController);
        
        view.addSubview(searchablePickerController.view)
        searchablePickerController.view.pinAnchorsToSuperview()
        
        if let searchablePickerController = self.searchablePickerController {
            searchablePickerController.removeFromParentViewController()
            searchablePickerController.view.removeFromSuperview()
            self.searchablePickerController = nil
        }
        
        searchablePickerController.repositoryPopupButton.currentRepository = dataSource.repository
        
        self.searchablePickerController = searchablePickerController
    }
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LabelSearchablePickerViewController.issueSelectionChanged(_:)), name: kQContextIssueSelectionChangeNotification, object: nil)
        super.viewDidLoad()
        Analytics.logContentViewWithName(NSStringFromClass(LabelSearchablePickerViewController.self), contentType: nil, contentId: nil, customAttributes: nil)
        
        reloadPicker()
    }
    
    
    private func doSaveWithCompletion(completion: dispatch_block_t?) {
        
        guard let strongPickerController = searchablePickerController, dataSource = self.dataSource, selectionMap = dataSource.selectionMap else { return }
        strongPickerController.loading = true
        
        let operationQueue = NSOperationQueue()
        operationQueue.name = "co.cashewapp.LabelSearchablePickerViewController.doSave"
        operationQueue.maxConcurrentOperationCount = 2
        
        for (issue, labelsSet) in selectionMap {
            var labelNames = [String]()
            for label in labelsSet {
                guard let labelName = label.name, labelRepo = label.repository where !QLabelStore.isHiddenLabelName(labelName, accountId: labelRepo.account.identifier, repositoryId: labelRepo.identifier) else { continue }
                labelNames.append(labelName)
            }
            
            operationQueue.addOperationWithBlock {
                let semaphore = dispatch_semaphore_create(0)
                let fullRepoName = issue.repository.fullName
                let sinceDate = issue.updatedAt
                let issueService = QIssuesService(forAccount: issue.account)
                
                Analytics.logCustomEventWithName("Changed Label", customAttributes: ["RepositoryName": fullRepoName])
                issueService.saveLabels(labelNames, forRepository: issue.repository, issueNumber: issue.number, onCompletion: { [weak self] (issue, context, err) in
                    if let issue = issue as? QIssue {
                        self?.searchablePickerController?.syncIssueEventsForIssue(issue, sinceDate: sinceDate)
                        Analytics.logCustomEventWithName("Successful Changed Label", customAttributes: ["RepositoryName": fullRepoName])
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                            QIssueStore.saveIssue(issue)
                        })
                    } else {
                        let errorString: String
                        if let error = err {
                            errorString = error.localizedDescription
                        } else {
                            errorString = ""
                        }
                        Analytics.logCustomEventWithName("Failed Changed Label", customAttributes: ["error": errorString, "RepositoryName": fullRepoName])
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
        //}
    }
    
}
