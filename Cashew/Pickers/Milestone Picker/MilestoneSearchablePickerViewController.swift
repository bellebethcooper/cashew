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
    
    fileprivate var dataSource: MilestoneSearchablePickerDataSource?
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var popoverBackgroundColorFixEnabed = true {
        didSet {
            self.searchablePickerController?.popoverBackgroundColorFixEnabed = popoverBackgroundColorFixEnabed
        }
    }
    
    fileprivate func reloadPicker() {
        guard let issue =  sourceIssue ?? QContext.shared().currentIssues.first else {
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
            guard let cell = cell as? MilestoneSearchResultTableRowView, let item = item as? QMilestone, let dataSource = self?.dataSource else { return }
            
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
        NotificationCenter.default.addObserver(self, selector: #selector(MilestoneSearchablePickerViewController.issueSelectionChanged(_:)), name: NSNotification.Name.qContextIssueSelectionChange, object: nil)
        
        super.viewDidLoad()
        
        reloadPicker()
    }
    
    fileprivate func doSaveWithCompletion(_ completion: (() -> ())?) {
        
        guard let strongPickerController = searchablePickerController, let dataSource = self.dataSource, let selectionMap = dataSource.selectionMap else { return }
        
        strongPickerController.loading = true
        
        let operationQueue = OperationQueue()
        operationQueue.name = "co.cashewapp.MilestoneSearchablePickerViewController.doSave"
        operationQueue.maxConcurrentOperationCount = 2
        
        for (issue, milestoneSet) in selectionMap {
            let milestone =  milestoneSet.first
            guard issue.milestone != milestone else {
                DDLogDebug("Skipping milestone batch update for \(issue) because milestone \(milestone) matches issue milestone \(issue.milestone)")
                continue
            }
            
            operationQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                let fullRepoName = issue.repository.fullName
                let sinceDate = issue.updatedAt
                let issueService = QIssuesService(for: issue.account)
                
                issueService.saveMilestoneNumber(milestone?.number, for: issue.repository, number: issue.number, onCompletion: { [weak self] (issue, context, error) in
                    if let issue = issue as? QIssue {
                        self?.searchablePickerController?.syncIssueEventsForIssue(issue, sinceDate: sinceDate)
                        DispatchQueue.global().async {
                            QIssueStore.save(issue)
                        }
                    } else {
                        let errorString: String
                        if let error = error {
                            errorString = error.localizedDescription
                        } else {
                            errorString = ""
                        }
                        DDLogDebug("Error updating milestone for \(issue) because \(error?.localizedDescription) error \(error)")
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
