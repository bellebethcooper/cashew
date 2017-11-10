//
//  NewIssueViewController.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 2/29/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRIssueCreationPopUpButton)
class IssueCreationPopUpButton: NSPopUpButton {
    override var canBecomeKeyView: Bool {
        return true
    }
}

@objc(SRIssueCreationTokenField)
class IssueCreationTokenField: NSTokenField {
    override var canBecomeKeyView: Bool {
        return true
    }
}

class NewIssueViewController: NSViewController {
    
    @IBOutlet weak var milestoneAssigneeLabelContainerViewHeightConstraint: NSLayoutConstraint!
    private static let buttonSize = CGSize(width: 92, height: 30)
    private static let buttonsSpacing: CGFloat = 8
    private static let milestoneAssigneeLabelContainerViewHeight: CGFloat = 123
    private static let submitButtonRightPadding: CGFloat = 12
    private static let buttonsBottomPadding: CGFloat = 13
    private static let progressIndicatorRightPadding: CGFloat = 6.0
    private static let progressIndicatorSize = CGSizeMake(17, 17)
    private static let labelColor = NSColor(calibratedWhite: 111/255.0, alpha: 0.85)
    private static let errorColor = NSColor(calibratedRed: 230/255.0, green: 86/255.0, blue: 13/255.0, alpha: 1)
    
    @IBOutlet weak var errorMessage: NSTextField!
    @IBOutlet var descriptionTextView: MarkdownEditorTextView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var labelsTokenField: NSTokenField!
    @IBOutlet weak var bodyTextView: NSScrollView!
    
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var labelsLabel: NSTextField!
    @IBOutlet weak var assigneeLabel: NSTextField!
    @IBOutlet weak var assigneeTokenField: NSTokenField!
    @IBOutlet weak var repositoryLabel: NSTextField!
    @IBOutlet weak var repositoryPopupButton: NSPopUpButton!
    @IBOutlet weak var milestonePopupButton: NSPopUpButton!
    
    private let cancelButton = BaseButton.whiteButton()
    private let submitNewIssueButton = BaseButton.greenButton()
    private let progressIndicator = NSProgressIndicator()
    private let uploadFileProgressIndicator = LabeledProgressIndicatorView()
    
    private var recentlySelectedRepository: QRepository?
    
    private lazy var assigneeTokenFieldDelegate = {
        return NewIssueAssigneeTokenFieldDelegate()
    }()
    
    private lazy var labelsTokenFieldDelegate = {
        return NewIssueLabelsTokenFieldDelegate()
    }()
    
    var request: CreateIssueRequest?
    var onCancelClicked: ( () -> Void )?
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButtons()
        setupProgressIndicator()
        loadRepositories()
        reloadDataForCurrentRepository()
        updateUIWithRequest()
        setupDescriptionTextView()
        setupFileUploadProgressIndicator()
        
        descriptionTextView.hidePlaceholder = true
        Analytics.logContentViewWithName(NSStringFromClass(NewIssueViewController.self), contentType: nil, contentId: nil, customAttributes: nil)
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.descriptionTextView.textColor = CashewColor.foregroundColor()
            if (.Dark == mode) {
                let appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
                strongSelf.progressIndicator.appearance = appearance
            } else {
                let appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
                strongSelf.progressIndicator.appearance = appearance
            }
        }
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.labelsTokenField.delegate = self.labelsTokenFieldDelegate
        self.assigneeTokenField.delegate = self.assigneeTokenFieldDelegate
        
        descriptionTextView.collapseToolbar = false
        descriptionTextView.activateTextViewConstraints = true
        
        self.titleTextField.becomeFirstResponder()
    }
    
    // MARK: Data Loaders
    
    private func loadRepositories() {
        repositoryPopupButton.removeAllItems()
        let repositories = QRepositoryStore.repositoriesForAccountId(QContext.sharedContext().currentFilter.account.identifier)
        repositoryPopupButton.addItemWithTitle("")
        repositories.forEach { (repo) in
            repositoryPopupButton.addItemWithTitle(repo.fullName)
        }
    }
    
    private func reloadMilestones() {
        self.milestonePopupButton.removeAllItems()
        if let repo = self.recentlySelectedRepository {
            
            let milestones: [QMilestone]
            
            if NSUserDefaults.shouldShowOnlyOpenMilestonesInIssueCreation() {
                milestones = QMilestoneStore.openMilestonesForAccountId(repo.account.identifier, repositoryId: repo.identifier)
            } else {
                milestones = QMilestoneStore.milestonesForAccountId(repo.account.identifier, repositoryId: repo.identifier, includeHidden: false)
            }
            
            self.milestonePopupButton.enabled = true
            
            self.milestonePopupButton.addItemWithTitle("")
            milestones.forEach { (milestone) in
                self.milestonePopupButton.addItemWithTitle(milestone.title)
            }
        } else {
            self.milestonePopupButton.enabled = false
        }
    }
    
    private func reloadTokenFields() {
        self.labelsTokenField.stringValue = ""
        self.assigneeTokenField.stringValue = ""
        self.labelsTokenFieldDelegate.repository = self.recentlySelectedRepository
        self.assigneeTokenFieldDelegate.repository = self.recentlySelectedRepository
        
        self.labelsTokenField.enabled = (self.labelsTokenFieldDelegate.repository != nil)
        self.assigneeTokenField.enabled = (self.assigneeTokenFieldDelegate.repository != nil)
    }
    
    private func reloadDataForCurrentRepository() {
        reloadMilestones()
        reloadTokenFields()
    }
    
    private func updateUIWithRequest() {
        if let request = self.request, let repoFullName = request.repositoryFullName {
            self.recentlySelectedRepository = nil
            self.repositoryPopupButton.selectItemWithTitle(repoFullName);
            self.repositoryValueDidChange(self.repositoryPopupButton)
            
            // set milestone if exists
            if let milestoneNumber = request.milestoneNumber, repo = self.recentlySelectedRepository {
                let milestones = QMilestoneStore.milestonesForAccountId(repo.account.identifier, repositoryId: repo.identifier, includeHidden: false)
                for milestone in milestones {
                    if milestoneNumber == milestone.number {
                        self.milestonePopupButton.selectItemWithTitle(milestone.title)
                    }
                }
            }
            
            // set assignee if exists
            if let assigneeLogin = request.assigneeLogin, repo = self.recentlySelectedRepository {
                let owners = QOwnerStore.searchUserWithQuery(assigneeLogin, forAccountId: repo.account.identifier, repositoryId:  repo.identifier)
                if owners.count > 0 {
                    self.assigneeTokenField.objectValue = [owners.first!.login]
                }
            }
            
            // set labels
            if let labels = request.labels {
                self.labelsTokenField.objectValue = labels
            }
            
        } else {
            self.recentlySelectedRepository = nil
            self.repositoryPopupButton.selectItemWithTitle("");
            repositoryValueDidChange(self.repositoryPopupButton)
        }
        
    }
    
    // MARK: Actions
    @IBAction func repositoryValueDidChange(sender: AnyObject) {
        
        if let newRepoFullName = self.repositoryPopupButton.selectedItem?.title {
            if self.recentlySelectedRepository?.fullName != newRepoFullName {
                if newRepoFullName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                    let repo = QRepositoryStore.repositoryForAccountId(QContext.sharedContext().currentFilter.account.identifier, fullName: newRepoFullName)
                    self.recentlySelectedRepository = repo
                    self.milestoneAssigneeLabelContainerViewHeightConstraint.constant = QAccount.isCurrentUserCollaboratorOfRepository(repo) ? NewIssueViewController.milestoneAssigneeLabelContainerViewHeight : 0
                } else {
                    self.recentlySelectedRepository = nil
                    self.milestoneAssigneeLabelContainerViewHeightConstraint.constant = NewIssueViewController.milestoneAssigneeLabelContainerViewHeight
                }
                
                if self.milestoneAssigneeLabelContainerViewHeightConstraint.constant == 0 {
                    //self.repositoryPopupButton.nextKeyView = self.descriptionTextView
                    self.descriptionTextView.setAsNextKeyViewForView(self.repositoryPopupButton)
                } else{
                    self.repositoryPopupButton.nextKeyView = self.milestonePopupButton
                    self.descriptionTextView.setAsNextKeyViewForView(self.labelsTokenField)
                }
                reloadDataForCurrentRepository()
            }
        }
    }
    
    
    @IBAction func milestoneValueDidChange(sender: AnyObject) {
        //print("milestone = \(milestonePopupButton.selectedItem)")
    }
    
    private func didClickSubmitNewIssueButton() {
        let hasTitle = (self.titleTextField.stringValue as NSString).trimmedString().length > 0
        if let repo = self.recentlySelectedRepository where hasTitle {
            self.titleLabel.textColor = NewIssueViewController.labelColor
            self.repositoryLabel.textColor = NewIssueViewController.labelColor
            
            transitionToInProgressState()
            
            let service = QIssuesService(forAccount: repo.account)
            var milestoneNumber: NSNumber?
            let hideExtras: Bool = self.milestoneAssigneeLabelContainerViewHeightConstraint.constant == 0
            
            if !hideExtras {
                let milestones = QMilestoneStore.milestonesForAccountId(repo.account.identifier, repositoryId: repo.identifier, includeHidden: false)
                for milestone in milestones {
                    if self.milestonePopupButton.selectedItem?.title == milestone.title {
                        milestoneNumber = milestone.number
                        break
                    }
                }
            }
            
            let labels: [String]? = hideExtras ? nil : self.labelsTokenField.objectValue as? [String]
            let assignee: String? = hideExtras ? nil : self.assigneeTokenField.stringValue
            let body: String? = self.descriptionTextView.string
            service.createIssueForRepository(repo, title: self.titleTextField.stringValue, body: body, assignee: assignee, milestone: milestoneNumber, labels: labels, onCompletion: { (anIssue, context, err) -> Void in
                
                guard let issue = anIssue as? QIssue where err == nil else {
                    dispatch_async(dispatch_get_main_queue())  {
                        self.transitionToActiveState()
                        let presentedErrorString: String
                        let errorString: String
                        if let error = err {
                            errorString = error.localizedDescription
                            presentedErrorString = "Error while trying to create Issue. (reason: \(errorString))"
                        } else {
                            errorString = ""
                            presentedErrorString = "Error while trying to create Issue."
                        }
                        
                        self.errorMessage.stringValue = presentedErrorString;
                        self.errorMessage.hidden = false
                        
                        
                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue(), {
                            NSAnimationContext.runAnimationGroup({ (context) in
                                context.duration = 0.3
                                self.errorMessage.hidden = true
                                }, completionHandler: nil)
                        })
                        
                        Analytics.logCustomEventWithName("Failed Save New Issue", customAttributes: ["error": errorString])
                    }
                    return
                }
                
                service.issuesEventsForRepository(repo, issueNumber: issue.number, pageNumber: 1, pageSize: 100, since: nil, onCompletion: { (issueEvents, context, err) in
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                        if let issueEvents = issueEvents as? [QIssueEvent] {
                            issueEvents.forEach({ (issueEvent) in
                                QIssueEventStore.saveIssueEvent(issueEvent)
                            })
                        }
                        
                        QIssueStore.saveIssue(issue)
                        Analytics.logCustomEventWithName("Successful Save New Issue", customAttributes: nil)
                    })
                    
                    dispatch_async(dispatch_get_main_queue())  {
                        if let onCancelClicked = self.onCancelClicked  {
                            onCancelClicked()
                        }
                    }
                })
                
            })
        } else {
            self.errorMessage.stringValue = "Missing required field. Try again."
            self.errorMessage.hidden = false
            if !hasTitle {
                self.titleLabel.textColor = NewIssueViewController.errorColor
            }
            if self.recentlySelectedRepository == nil {
                self.repositoryLabel.textColor = NewIssueViewController.errorColor
            }
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue(), {
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.duration = 0.3
                    self.titleLabel.textColor = NewIssueViewController.labelColor
                    self.repositoryLabel.textColor = NewIssueViewController.labelColor
                    self.errorMessage.hidden = true
                    }, completionHandler: nil)
            })
        }
    }
    
    private func transitionToInProgressState() {
        progressIndicator.hidden = false
        progressIndicator.startAnimation(nil)
        self.cancelButton.enabled = false
        self.submitNewIssueButton.enabled = false
        
        descriptionTextView.editable = false
        descriptionTextView.selectable = false
        titleTextField.enabled = false
        labelsTokenField.enabled = false
        assigneeTokenField.enabled = false
        repositoryPopupButton.enabled = false
        milestonePopupButton.enabled = false
    }
    
    private func transitionToActiveState() {
        self.progressIndicator.hidden = true
        self.progressIndicator.stopAnimation(nil)
        self.cancelButton.enabled = true
        self.submitNewIssueButton.enabled = true
        
        descriptionTextView.editable = true
        descriptionTextView.selectable = true
        titleTextField.enabled = true
        labelsTokenField.enabled = true
        assigneeTokenField.enabled = true
        repositoryPopupButton.enabled = true
        milestonePopupButton.enabled = true
    }
    
    func didClickCancelButton() {
        dispatch_async(dispatch_get_main_queue())  {
            NSAlert.showWarningMessage("Are you sure you want to discard issue?", onConfirmation: {
                if let onCancelClicked = self.onCancelClicked  {
                    onCancelClicked()
                }
            });
        }
    }
    
    // MARK: General Setup
    
    private func setupFileUploadProgressIndicator() {
        guard uploadFileProgressIndicator.superview == nil else { return }
        
        view.addSubview(uploadFileProgressIndicator)
        uploadFileProgressIndicator.hidden = true
        uploadFileProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        uploadFileProgressIndicator.leftAnchor.constraintEqualToAnchor(descriptionTextView.leftAnchor).active = true
        
        uploadFileProgressIndicator.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        uploadFileProgressIndicator.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        uploadFileProgressIndicator.heightAnchor.constraintEqualToConstant(NewIssueViewController.buttonSize.height).active = true
        uploadFileProgressIndicator.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -NewIssueViewController.buttonsBottomPadding).active = true
    }
    
    private func setupDescriptionTextView() {
        descriptionTextView.font = NSFont.systemFontOfSize(14)
        descriptionTextView.collapseToolbar = false
        descriptionTextView.onEnterKeyPressed = { [weak self] in
            self?.didClickSubmitNewIssueButton()
        }
        
        descriptionTextView.onDragExited = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.descriptionTextView.layer?.borderWidth = 0
        }
        
        descriptionTextView.onDragEntered = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.descriptionTextView.layer?.borderWidth = 2
            strongSelf.descriptionTextView.layer?.borderColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1).CGColor
        }
        
        descriptionTextView.onFileUploadChange = { [weak self] in
            guard let strongSelf = self else { return }
            let fileUploadCount = strongSelf.descriptionTextView.currentUploadCount
            if fileUploadCount == 0 {
                strongSelf.uploadFileProgressIndicator.hideProgress()
                strongSelf.uploadFileProgressIndicator.hidden = true
                strongSelf.submitNewIssueButton.enabled = true
                strongSelf.cancelButton.enabled = true
            } else {
                strongSelf.uploadFileProgressIndicator.showProgressWithString("Uploading \(fileUploadCount) file\(fileUploadCount == 1 ? "" : "s")")
                strongSelf.uploadFileProgressIndicator.hidden = false
                strongSelf.submitNewIssueButton.enabled = false
                strongSelf.cancelButton.enabled = false
            }
        }
    }
    
    private func setupButtons() {
        guard submitNewIssueButton.superview == nil && cancelButton.superview == nil else { return }
        submitNewIssueButton.text = "Create"
        cancelButton.text = "Discard"
        
        submitNewIssueButton.onClick = { [weak self] in
            self?.didClickSubmitNewIssueButton()
        }
        
        cancelButton.onClick = { [weak self] in
            self?.didClickCancelButton()
        }
        
        [submitNewIssueButton, cancelButton].forEach { (bttn) in
            view.addSubview(bttn)
            bttn.translatesAutoresizingMaskIntoConstraints = false
            bttn.heightAnchor.constraintEqualToConstant(NewIssueViewController.buttonSize.height).active = true
            bttn.widthAnchor.constraintEqualToConstant(NewIssueViewController.buttonSize.width).active = true
            bttn.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -NewIssueViewController.buttonsBottomPadding).active = true
        }
        
        submitNewIssueButton.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -NewIssueViewController.submitButtonRightPadding).active = true
        cancelButton.rightAnchor.constraintEqualToAnchor(submitNewIssueButton.leftAnchor, constant: -NewIssueViewController.buttonsSpacing).active = true
        
        titleLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(NewIssueViewController.didClickTitleLabel)))
        descriptionLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(NewIssueViewController.didClickDescriptionLabel)))
        labelsLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(NewIssueViewController.didClickLabelsLabel)))
        assigneeLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(NewIssueViewController.didClickAssigneeLabel)))
    }
    
    @objc
    private func didClickDescriptionLabel() {
        self.view.window?.makeFirstResponder(descriptionTextView)
    }
    
    @objc
    private func didClickLabelsLabel() {
        self.view.window?.makeFirstResponder(labelsTokenField)
    }
    
    @objc
    private func didClickAssigneeLabel() {
        self.view.window?.makeFirstResponder(assigneeTokenField)
    }
    
    @objc
    private func didClickTitleLabel() {
        self.view.window?.makeFirstResponder(titleTextField)
    }
    
    private func setupProgressIndicator() {
        guard progressIndicator.superview == nil else { return }
        view.addSubview(progressIndicator)
        progressIndicator.style = .SpinningStyle
        progressIndicator.hidden = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.heightAnchor.constraintEqualToConstant(NewIssueViewController.progressIndicatorSize.height).active = true
        progressIndicator.widthAnchor.constraintEqualToConstant(NewIssueViewController.progressIndicatorSize.width).active = true
        progressIndicator.rightAnchor.constraintEqualToAnchor(cancelButton.leftAnchor, constant: -NewIssueViewController.progressIndicatorRightPadding).active = true
        progressIndicator.centerYAnchor.constraintEqualToAnchor(cancelButton.centerYAnchor).active = true
    }
}


@objc(SRNewIssueMarkdownEditorTextView)
class NewIssueMarkdownEditorTextView: MarkdownEditorTextView {
    
    
}
