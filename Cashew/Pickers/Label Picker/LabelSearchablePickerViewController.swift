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
    
    fileprivate var dataSource: LabelSearchablePickerDataSource?
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
        guard let issue = sourceIssue ?? QContext.shared().currentIssues.first else {
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
            guard let cell = cell as? LabelSearchResultTableRowView, let item = item as? QLabel, let dataSource = self?.dataSource else { return }
            
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
        
        searchablePickerController.disableButtonIfNoSelection = false
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
        NotificationCenter.default.addObserver(self, selector: #selector(LabelSearchablePickerViewController.issueSelectionChanged(_:)), name: NSNotification.Name.qContextIssueSelectionChange, object: nil)
        super.viewDidLoad()
        reloadPicker()
    }
    
    
    fileprivate func doSaveWithCompletion(_ completion: (()->())?) {
        
        guard let strongPickerController = searchablePickerController, let dataSource = self.dataSource, let selectionMap = dataSource.selectionMap else { return }
        strongPickerController.loading = true
        
        let operationQueue = OperationQueue()
        operationQueue.name = "co.cashewapp.LabelSearchablePickerViewController.doSave"
        operationQueue.maxConcurrentOperationCount = 2
        
        for (issue, labelsSet) in selectionMap {
            var labelNames = [String]()
            for label in labelsSet {
                guard let labelName = label.name, let labelRepo = label.repository , !QLabelStore.isHiddenLabelName(labelName, accountId: labelRepo.account.identifier, repositoryId: labelRepo.identifier) else { continue }
                labelNames.append(labelName)
            }
            
            operationQueue.addOperation {
                let semaphore = DispatchSemaphore(value: 0)
                let fullRepoName = issue.repository.fullName
                let sinceDate = issue.updatedAt
                let issueService = QIssuesService(for: issue.account)
                
                issueService.saveLabels(labelNames, for: issue.repository, issueNumber: issue.number, onCompletion: { [weak self] (issue, context, err) in
                    if let issue = issue as? QIssue {
                        self?.searchablePickerController?.syncIssueEventsForIssue(issue, sinceDate: sinceDate)
                        DispatchQueue.global(qos: .userInitiated).async {
                            QIssueStore.save(issue)
                        }
                    } else {
                        let errorString: String
                        if let error = err {
                            errorString = error.localizedDescription
                        } else {
                            errorString = ""
                        }
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
        //}
    }
    
}
