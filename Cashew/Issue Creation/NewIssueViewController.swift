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
    fileprivate static let buttonSize = CGSize(width: 92, height: 30)
    fileprivate static let buttonsSpacing: CGFloat = 8
    fileprivate static let milestoneAssigneeLabelContainerViewHeight: CGFloat = 123
    fileprivate static let submitButtonRightPadding: CGFloat = 12
    fileprivate static let buttonsBottomPadding: CGFloat = 13
    fileprivate static let progressIndicatorRightPadding: CGFloat = 6.0
    fileprivate static let progressIndicatorSize = CGSize(width: 17, height: 17)
    fileprivate static let labelColor = NSColor(calibratedWhite: 111/255.0, alpha: 0.85)
    fileprivate static let errorColor = NSColor(calibratedRed: 230/255.0, green: 86/255.0, blue: 13/255.0, alpha: 1)
    
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
    
    fileprivate let cancelButton = BaseButton.whiteButton()
    fileprivate let submitNewIssueButton = BaseButton.greenButton()
    fileprivate let progressIndicator = NSProgressIndicator()
    fileprivate let uploadFileProgressIndicator = LabeledProgressIndicatorView()
    
    fileprivate var recentlySelectedRepository: QRepository?
    
    fileprivate lazy var assigneeTokenFieldDelegate = {
        return NewIssueAssigneeTokenFieldDelegate()
    }()
    
    fileprivate lazy var labelsTokenFieldDelegate = {
        return NewIssueLabelsTokenFieldDelegate()
    }()
    
    @objc var request: CreateIssueRequest?
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
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.descriptionTextView.textColor = CashewColor.foregroundSecondaryColor()
            if (.dark == mode) {
                let appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
                strongSelf.progressIndicator.appearance = appearance
            } else {
                let appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
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
    
    fileprivate func loadRepositories() {
        repositoryPopupButton.removeAllItems()
        let repositories = QRepositoryStore.repositories(forAccountId: QContext.shared().currentFilter.account.identifier)
        repositoryPopupButton.addItem(withTitle: "")
        repositories?.forEach { (repo) in
            repositoryPopupButton.addItem(withTitle: repo.fullName)
        }
    }
    
    fileprivate func reloadMilestones() {
        self.milestonePopupButton.removeAllItems()
        if let repo = self.recentlySelectedRepository {
            
            let milestones: [QMilestone]
            
            if UserDefaults.shouldShowOnlyOpenMilestonesInIssueCreation() {
                milestones = QMilestoneStore.openMilestones(forAccountId: repo.account.identifier, repositoryId: repo.identifier)
            } else {
                milestones = QMilestoneStore.milestones(forAccountId: repo.account.identifier, repositoryId: repo.identifier, includeHidden: false)
            }
            
            self.milestonePopupButton.isEnabled = true
            
            self.milestonePopupButton.addItem(withTitle: "")
            milestones.forEach { (milestone) in
                self.milestonePopupButton.addItem(withTitle: milestone.title)
            }
        } else {
            self.milestonePopupButton.isEnabled = false
        }
    }
    
    fileprivate func reloadTokenFields() {
        self.labelsTokenField.stringValue = ""
        self.assigneeTokenField.stringValue = ""
        self.labelsTokenFieldDelegate.repository = self.recentlySelectedRepository
        self.assigneeTokenFieldDelegate.repository = self.recentlySelectedRepository
        
        self.labelsTokenField.isEnabled = (self.labelsTokenFieldDelegate.repository != nil)
        self.assigneeTokenField.isEnabled = (self.assigneeTokenFieldDelegate.repository != nil)
    }
    
    fileprivate func reloadDataForCurrentRepository() {
        reloadMilestones()
        reloadTokenFields()
    }
    
    fileprivate func updateUIWithRequest() {
        if let request = self.request, let repoFullName = request.repositoryFullName {
            self.recentlySelectedRepository = nil
            self.repositoryPopupButton.selectItem(withTitle: repoFullName);
            self.repositoryValueDidChange(self.repositoryPopupButton)
            
            // set milestone if exists
            if let milestoneNumber = request.milestoneNumber, let repo = self.recentlySelectedRepository {
                let milestones = QMilestoneStore.milestones(forAccountId: repo.account.identifier, repositoryId: repo.identifier, includeHidden: false)
                for milestone in milestones! {
                    if milestoneNumber == milestone.number {
                        self.milestonePopupButton.selectItem(withTitle: milestone.title)
                    }
                }
            }
            
            // set assignee if exists
            if let assigneeLogin = request.assigneeLogin, let repo = self.recentlySelectedRepository {
                let owners = QOwnerStore.searchUser(withQuery: assigneeLogin, forAccountId: repo.account.identifier, repositoryId:  repo.identifier)
                if (owners?.count)! > 0 {
                    self.assigneeTokenField.objectValue = [owners?.first!.login]
                }
            }
            
            // set labels
            if let labels = request.labels {
                self.labelsTokenField.objectValue = labels
            }
            
        } else {
            self.recentlySelectedRepository = nil
            self.repositoryPopupButton.selectItem(withTitle: "");
            repositoryValueDidChange(self.repositoryPopupButton)
        }
        
    }
    
    // MARK: Actions
    @IBAction func repositoryValueDidChange(_ sender: AnyObject) {
        
        if let newRepoFullName = self.repositoryPopupButton.selectedItem?.title {
            if self.recentlySelectedRepository?.fullName != newRepoFullName {
                if newRepoFullName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lengthOfBytes(using: String.Encoding.utf8) > 0 {
                    let repo = QRepositoryStore.repository(forAccountId: QContext.shared().currentFilter.account.identifier, fullName: newRepoFullName)
                    self.recentlySelectedRepository = repo
                    self.milestoneAssigneeLabelContainerViewHeightConstraint.constant = QAccount.isCurrentUserCollaboratorOfRepository(repo!) ? NewIssueViewController.milestoneAssigneeLabelContainerViewHeight : 0
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
    
    
    @IBAction func milestoneValueDidChange(_ sender: AnyObject) {
        //print("milestone = \(milestonePopupButton.selectedItem)")
    }
    
    fileprivate func didClickSubmitNewIssueButton() {
        let hasTitle = (self.titleTextField.stringValue as NSString).trimmedString().length > 0
        if let repo = self.recentlySelectedRepository , hasTitle {
            self.titleLabel.textColor = NewIssueViewController.labelColor
            self.repositoryLabel.textColor = NewIssueViewController.labelColor
            
            transitionToInProgressState()
            
            let service = QIssuesService(for: repo.account)
            var milestoneNumber: NSNumber?
            let hideExtras: Bool = self.milestoneAssigneeLabelContainerViewHeightConstraint.constant == 0
            
            if !hideExtras {
                let milestones = QMilestoneStore.milestones(forAccountId: repo.account.identifier, repositoryId: repo.identifier, includeHidden: false)
                for milestone in milestones! {
                    if self.milestonePopupButton.selectedItem?.title == milestone.title {
                        milestoneNumber = milestone.number
                        break
                    }
                }
            }
            
            let labels: [String]? = hideExtras ? nil : self.labelsTokenField.objectValue as? [String]
            let assignee: String? = hideExtras ? nil : self.assigneeTokenField.stringValue
            let body: String? = self.descriptionTextView.string
            service.createIssue(for: repo, title: self.titleTextField.stringValue, body: body, assignee: assignee, milestone: milestoneNumber, labels: labels, onCompletion: { (anIssue, context, err) -> Void in
                
                guard let issue = anIssue as? QIssue , err == nil else {
                    DispatchQueue.main.async {
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
                        self.errorMessage.isHidden = false
                        
                        let delay = 10 * NSEC_PER_SEC
                        let deadline = DispatchTime.now() + Double(delay)
                        DispatchQueue.main.asyncAfter(deadline: deadline, execute: {
                            NSAnimationContext.runAnimationGroup({ (context) in
                                context.duration = 0.3
                                self.errorMessage.isHidden = true
                                }, completionHandler: nil)
                        })
                    }
                    return
                }
                
                service.issuesEvents(for: repo, issueNumber: issue.number, pageNumber: 1, pageSize: 100, since: nil, onCompletion: { (issueEvents, context, err) in
                    
                    DispatchQueue.global().async {
                        if let issueEvents = issueEvents as? [QIssueEvent] {
                            issueEvents.forEach({ (issueEvent) in
                                QIssueEventStore.save(issueEvent)
                            })
                        }
                        
                        QIssueStore.save(issue)
                    }
                    
                    DispatchQueue.main.async  {
                        if let onCancelClicked = self.onCancelClicked  {
                            onCancelClicked()
                        }
                    }
                })
                
            })
        } else {
            self.errorMessage.stringValue = "Missing required field. Try again."
            self.errorMessage.isHidden = false
            if !hasTitle {
                self.titleLabel.textColor = NewIssueViewController.errorColor
            }
            if self.recentlySelectedRepository == nil {
                self.repositoryLabel.textColor = NewIssueViewController.errorColor
            }
            
            let delayTime = DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.duration = 0.3
                    self.titleLabel.textColor = NewIssueViewController.labelColor
                    self.repositoryLabel.textColor = NewIssueViewController.labelColor
                    self.errorMessage.isHidden = true
                    }, completionHandler: nil)
            })
        }
    }
    
    fileprivate func transitionToInProgressState() {
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(nil)
        self.cancelButton.enabled = false
        self.submitNewIssueButton.enabled = false
        
        descriptionTextView.editable = false
        descriptionTextView.selectable = false
        titleTextField.isEnabled = false
        labelsTokenField.isEnabled = false
        assigneeTokenField.isEnabled = false
        repositoryPopupButton.isEnabled = false
        milestonePopupButton.isEnabled = false
    }
    
    fileprivate func transitionToActiveState() {
        self.progressIndicator.isHidden = true
        self.progressIndicator.stopAnimation(nil)
        self.cancelButton.enabled = true
        self.submitNewIssueButton.enabled = true
        
        descriptionTextView.editable = true
        descriptionTextView.selectable = true
        titleTextField.isEnabled = true
        labelsTokenField.isEnabled = true
        assigneeTokenField.isEnabled = true
        repositoryPopupButton.isEnabled = true
        milestonePopupButton.isEnabled = true
    }
    
    func didClickCancelButton() {
        DispatchQueue.main.async  {
            NSAlert.showWarningMessage("Are you sure you want to discard issue?", onConfirmation: {
                if let onCancelClicked = self.onCancelClicked  {
                    onCancelClicked()
                }
            });
        }
    }
    
    // MARK: General Setup
    
    fileprivate func setupFileUploadProgressIndicator() {
        guard uploadFileProgressIndicator.superview == nil else { return }
        
        view.addSubview(uploadFileProgressIndicator)
        uploadFileProgressIndicator.isHidden = true
        uploadFileProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        uploadFileProgressIndicator.leftAnchor.constraint(equalTo: descriptionTextView.leftAnchor).isActive = true
        
        uploadFileProgressIndicator.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        uploadFileProgressIndicator.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        uploadFileProgressIndicator.heightAnchor.constraint(equalToConstant: NewIssueViewController.buttonSize.height).isActive = true
        uploadFileProgressIndicator.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -NewIssueViewController.buttonsBottomPadding).isActive = true
    }
    
    fileprivate func setupDescriptionTextView() {
        descriptionTextView.font = NSFont.systemFont(ofSize: 14)
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
            strongSelf.descriptionTextView.layer?.borderColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1).cgColor
        }
        
        descriptionTextView.onFileUploadChange = { [weak self] in
            guard let strongSelf = self else { return }
            let fileUploadCount = strongSelf.descriptionTextView.currentUploadCount
            if fileUploadCount == 0 {
                strongSelf.uploadFileProgressIndicator.hideProgress()
                strongSelf.uploadFileProgressIndicator.isHidden = true
                strongSelf.submitNewIssueButton.enabled = true
                strongSelf.cancelButton.enabled = true
            } else {
                strongSelf.uploadFileProgressIndicator.showProgressWithString("Uploading \(fileUploadCount) file\(fileUploadCount == 1 ? "" : "s")")
                strongSelf.uploadFileProgressIndicator.isHidden = false
                strongSelf.submitNewIssueButton.enabled = false
                strongSelf.cancelButton.enabled = false
            }
        }
    }
    
    fileprivate func setupButtons() {
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
            bttn.heightAnchor.constraint(equalToConstant: NewIssueViewController.buttonSize.height).isActive = true
            bttn.widthAnchor.constraint(equalToConstant: NewIssueViewController.buttonSize.width).isActive = true
            bttn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -NewIssueViewController.buttonsBottomPadding).isActive = true
        }
        
        submitNewIssueButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -NewIssueViewController.submitButtonRightPadding).isActive = true
        cancelButton.rightAnchor.constraint(equalTo: submitNewIssueButton.leftAnchor, constant: -NewIssueViewController.buttonsSpacing).isActive = true
        
        titleLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(NewIssueViewController.didClickTitleLabel)))
        descriptionLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(NewIssueViewController.didClickDescriptionLabel)))
        labelsLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(NewIssueViewController.didClickLabelsLabel)))
        assigneeLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(NewIssueViewController.didClickAssigneeLabel)))
    }
    
    @objc
    fileprivate func didClickDescriptionLabel() {
        self.view.window?.makeFirstResponder(descriptionTextView)
    }
    
    @objc
    fileprivate func didClickLabelsLabel() {
        self.view.window?.makeFirstResponder(labelsTokenField)
    }
    
    @objc
    fileprivate func didClickAssigneeLabel() {
        self.view.window?.makeFirstResponder(assigneeTokenField)
    }
    
    @objc
    fileprivate func didClickTitleLabel() {
        self.view.window?.makeFirstResponder(titleTextField)
    }
    
    fileprivate func setupProgressIndicator() {
        guard progressIndicator.superview == nil else { return }
        view.addSubview(progressIndicator)
        progressIndicator.style = .spinning
        progressIndicator.isHidden = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.heightAnchor.constraint(equalToConstant: NewIssueViewController.progressIndicatorSize.height).isActive = true
        progressIndicator.widthAnchor.constraint(equalToConstant: NewIssueViewController.progressIndicatorSize.width).isActive = true
        progressIndicator.rightAnchor.constraint(equalTo: cancelButton.leftAnchor, constant: -NewIssueViewController.progressIndicatorRightPadding).isActive = true
        progressIndicator.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor).isActive = true
    }
}


@objc(SRNewIssueMarkdownEditorTextView)
class NewIssueMarkdownEditorTextView: MarkdownEditorTextView {
    
    
}
