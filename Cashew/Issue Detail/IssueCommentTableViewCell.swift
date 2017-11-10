//
//  IssueCommentTableViewCell.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/24/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class CommentMarkdownContainerView: BaseView { }

class ReactionButton: NSButton {
    
    private var mouseTrackingArea: NSTrackingArea?
    var onMouseOver: dispatch_block_t?
    
    override func mouseEntered(theEvent: NSEvent) {
        if let onMouseOver = onMouseOver {
            onMouseOver()
        }
        
        super.mouseEntered(theEvent)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let previousTrackingArea = mouseTrackingArea {
            removeTrackingArea(previousTrackingArea)
        }
        
        let area = NSTrackingArea(rect: bounds, options: [.ActiveAlways, .MouseEnteredAndExited], owner: self, userInfo: nil)
        mouseTrackingArea = area
        addTrackingArea(area)
    }
    
    override func layout() {
        super.layout()
        updateTrackingAreas()
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let area = NSTrackingArea(rect: bounds, options: [.ActiveAlways, .MouseEnteredAndExited], owner: self, userInfo: nil)
        mouseTrackingArea = area
        addTrackingArea(area)
    }
}

@IBDesignable class IssueCommentTableViewCell: BaseView {
    
    static let reactionViewerHeight: CGFloat = 26
    
    private static let willShowReactionNotification = "willShowReactionNotification"
    
    private static let menuButtonsColor = NSColor(calibratedWhite: 147/255.0, alpha: 0.85)
    private static let buttonSize = CGSize(width: 92, height: 30)
    private static let buttonsSpacing: CGFloat = 8
    private static let submitButtonRightPadding: CGFloat = 6
    private static let buttonsBottomPadding: CGFloat = 13
    private static let progressIndicatorRightPadding: CGFloat = 6.0
    private static let progressIndicatorSize = CGSizeMake(17, 17)
    private static let markdownCommentContainerViewBottomLayoutConstraintEditConstaint: CGFloat = 50.0
    
    @IBOutlet weak var commentContainerBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentContainerTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainContainerLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainContainerRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentMarkdownContainerView: CommentMarkdownContainerView!
    
    @IBOutlet weak private var usernameLabel: NSTextField!
    @IBOutlet weak private var dateLabel: NSTextField!
    @IBOutlet weak private var usernameAvatarView: BaseView!
    @IBOutlet weak var menuButton: NSButton!
    
    @IBOutlet weak var headerContainerView: BaseView!
    private var editableMarkdownView: EditableMarkdownView?
    
    private let cancelButton = BaseButton.whiteButton()
    private let commentButton = BaseButton.greenButton()
    private let progressIndicator = NSProgressIndicator()
    private let uploadFileProgressIndicator = LabeledProgressIndicatorView()
    
    @IBOutlet weak var likeButton: ReactionButton!
    //private var mouseTrackingArea: NSTrackingArea?
    
    @IBOutlet weak var bottomHorizontalLineView: BaseView!
    @IBOutlet weak var markdownCommentContainerViewBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    
    private var editableMarkdownViewBottomConstraint: NSLayoutConstraint?
    private let reactionsViewController: ReactionsViewController = ReactionsViewController(nibName: "ReactionsViewController", bundle: nil)!
    private var reactionPickerPopover: NSPopover?
    
    var text: String? {
        get {
            return editableMarkdownView?.string
        }
    }
    
    var isMarkdownEditorFirstResponder: Bool {
        return editableMarkdownView?.isFirstResponder ?? false
    }
    
    var draft: IssueCommentDraft? {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                if let strongSelf = self, draft = strongSelf.draft, editableMarkdownView = strongSelf.editableMarkdownView {
                    strongSelf.editing = true
                    editableMarkdownView.string = draft.body
                    strongSelf.didSetEditing()
                }
            }
        }
    }
    
    var editing: Bool = false {
        didSet {
            if oldValue != editing {
                didSetEditing()
            }
        }
    }
    
    var imageURLs: [NSURL] {
        get {
            return editableMarkdownView?.imageURLs ?? [NSURL]()
        }
    }
    var onTextChange: dispatch_block_t? {
        didSet {
            if let editableMarkdownView = editableMarkdownView {
                editableMarkdownView.onTextChange = onTextChange
            }
        }
    }
    
    var onCommentDiscard: dispatch_block_t?
    
    var onHeightChanged: dispatch_block_t? {
        didSet {
            if let editableMarkdownView = editableMarkdownView {
                editableMarkdownView.onHeightChanged = onHeightChanged
            }
        }
    }
    
    var didClickImageBlock: ((url: NSURL!) -> ())? {
        didSet {
            if let editableMarkdownView = editableMarkdownView {
                editableMarkdownView.didClickImageBlock = didClickImageBlock
            }
        }
    }
    
    override var intrinsicContentSize: NSSize {
        get {
            guard let editableMarkdownView = editableMarkdownView else { return NSSize.zero }
            let reactionsHeight = reactionsViewController.view.superview == nil ? 0 : reactionsViewController.view.frame.height
            return NSSize(width: bounds.width, height: reactionsHeight + headerHeightConstraint.constant + editableMarkdownView.intrinsicContentSize.height + markdownCommentContainerViewBottomLayoutConstraint.constant)
        }
    }
    
    var commentInfo: QIssueCommentInfo? {
        didSet {
            
            if editableMarkdownView?.isFirstResponder == false {
                editing = false
            }
            assert(NSThread.isMainThread(), "not on main thread");
            
            
            if let aUsername = self.commentInfo?.username() {
                self.usernameLabel.stringValue = aUsername
            } else {
                self.usernameLabel.stringValue = ""
            }
            
            if let aDate = self.commentInfo?.commentedOn() {
                var didUseFullDate = ObjCBool(false)
                let dateString = aDate.timeAgoForWeekOrLessAndDidUseFullDate(&didUseFullDate);
                
                if didUseFullDate.boolValue {
                    self.dateLabel.stringValue = String(format: "commented on %@", dateString)
                } else {
                    self.dateLabel.stringValue = String(format: "commented %@", dateString)
                }
            } else {
                self.dateLabel.stringValue = ""
            }
            
            if let aUsernameAvararURL = self.commentInfo?.usernameAvatarURL() {
                self.usernameAvatarView.setImageURL(aUsernameAvararURL)
            } else {
                self.usernameAvatarView.setImageURL(nil)
            }
            
            if let commentInfo = commentInfo where oldValue == nil || oldValue!.commentBody() != commentInfo.commentBody() {
                if setupEditableMarkdownView() == false {
                    editableMarkdownView?.commentInfo = commentInfo
                }
            }
            
            reactionsViewController.commentInfo = commentInfo
            setupReactionsViewController()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(IssueCommentTableViewCell.willShowReactionNotification)
        editableMarkdownView?.onDragExited = nil
        editableMarkdownView?.onDragEntered = nil
        editableMarkdownView?.onHeightChanged = nil
        editableMarkdownView?.onFileUploadChange = nil
        QIssueStore.removeObserver(self)
        QIssueCommentStore.removeObserver(self)
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
        SRIssueCommentReactionStore.removeObserver(self)
        SRIssueReactionStore.removeObserver(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(IssueCommentTableViewCell.willShowReaction(_:)), name: IssueCommentTableViewCell.willShowReactionNotification, object: nil)
        
        QIssueStore.addObserver(self)
        QIssueCommentStore.addObserver(self)
        SRIssueCommentReactionStore.addObserver(self)
        SRIssueReactionStore.addObserver(self)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        usernameAvatarView.layer?.cornerRadius = CGRectGetHeight(usernameAvatarView.frame) / 2.0
        usernameAvatarView.layer?.masksToBounds = true
        
        self.menuButton.hidden = false
        
        CATransaction.commit()
        
//        let trackingArea = NSTrackingArea(rect: bounds, options:  [NSTrackingAreaOptions.ActiveInKeyWindow, NSTrackingAreaOptions.MouseEnteredAndExited] , owner: self, userInfo: nil)
//        self.addTrackingArea(trackingArea);
//        self.mouseTrackingArea = trackingArea
        
        self.likeButton.image = self.likeButton.image?.imageWithTintColor(NSColor(calibratedWhite: 125/255.0, alpha: 1))
        
        setupButtons()
        setupProgressIndicator()
        setupFileUploadProgressIndicator()
        didSetEditing()
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(strongSelf)
                return;
            }
            
            if mode == .Light {
                strongSelf.backgroundColor = LightModeColor.sharedInstance.backgroundColor()
                strongSelf.usernameLabel.textColor = LightModeColor.sharedInstance.foregroundSecondaryColor()
                strongSelf.dateLabel.textColor = LightModeColor.sharedInstance.foregroundTertiaryColor()
                strongSelf.menuButton.image = NSImage(named: "chevron-down")?.imageWithTintColor(IssueCommentTableViewCell.menuButtonsColor)
                strongSelf.progressIndicator.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
            } else if mode == .Dark {
                strongSelf.backgroundColor = DarkModeColor.sharedInstance.backgroundColor()
                strongSelf.usernameLabel.textColor = DarkModeColor.sharedInstance.foregroundSecondaryColor()
                strongSelf.dateLabel.textColor = DarkModeColor.sharedInstance.foregroundTertiaryColor()
                strongSelf.menuButton.image = NSImage(named: "chevron-down")?.imageWithTintColor(IssueCommentTableViewCell.menuButtonsColor)
                strongSelf.progressIndicator.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
            }
            
            strongSelf.likeButton.image = NSImage(named: "reactions")?.imageWithTintColor(IssueCommentTableViewCell.menuButtonsColor)
        }
        
        likeButton.onMouseOver = { [weak self] in
            guard let strongSelf = self where strongSelf.reactionPickerPopover == nil else { return }
            strongSelf.didClickReactionsButton(strongSelf.likeButton)
        }
    }
    
    
    @objc
    private func willShowReaction(notification: NSNotification) {
        if let obj = notification.object as? NSPopover where obj != self.reactionPickerPopover {
            self.reactionPickerPopover?.close()
        }
    }
    
    
    private func didSetEditing() {
        if editing {
            markdownCommentContainerViewBottomLayoutConstraint.constant = IssueCommentTableViewCell.markdownCommentContainerViewBottomLayoutConstraintEditConstaint
            cancelButton.hidden = false
            commentButton.hidden = false
        } else {
            markdownCommentContainerViewBottomLayoutConstraint.constant = 0
            cancelButton.hidden = true
            commentButton.hidden = true
        }
        
        editableMarkdownView?.editing = editing
        setupReactionsViewController()
        invalidateIntrinsicContentSize()
        
    }
    
    private func setupFileUploadProgressIndicator() {
        guard uploadFileProgressIndicator.superview == nil else { return }
        
        addSubview(uploadFileProgressIndicator)
        uploadFileProgressIndicator.hidden = true
        uploadFileProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        uploadFileProgressIndicator.leftAnchor.constraintEqualToAnchor(commentMarkdownContainerView.leftAnchor).active = true
        
        uploadFileProgressIndicator.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        uploadFileProgressIndicator.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        uploadFileProgressIndicator.heightAnchor.constraintEqualToConstant(IssueCommentTableViewCell.buttonSize.height).active = true
        uploadFileProgressIndicator.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -IssueCommentTableViewCell.buttonsBottomPadding).active = true
    }
    
    private func didClickCommentButton() {
        let strongSelf = self
        
        guard let repository = strongSelf.commentInfo?.repo(), account = strongSelf.commentInfo?.repo().account else { return }
        
        strongSelf.commentButton.enabled = false
        strongSelf.cancelButton.enabled = false
        strongSelf.progressIndicator.startAnimation(nil)
        strongSelf.progressIndicator.hidden = false
        
        let service = QIssuesService(forAccount: account)
        if let issue = strongSelf.commentInfo as? QIssue {
            Analytics.logCustomEventWithName("Clicked Save Issue Description", customAttributes: nil)
            service.saveIssueBody(strongSelf.editableMarkdownView?.markdown, forRepository: repository, number: issue.number, onCompletion: { (updatedIssue, context, error) in
                if let updatedIssue = updatedIssue as? QIssue {
                    if let onCommentDiscard = strongSelf.onCommentDiscard {
                        onCommentDiscard()
                    }
                    
                    QIssueStore.saveIssue(updatedIssue)
                    Analytics.logCustomEventWithName("Successful Save Issue Description", customAttributes: nil)
                } else {
                    let errorString: String
                    if let error = error {
                        errorString = error.localizedDescription
                    } else {
                        errorString = ""
                    }
                    Analytics.logCustomEventWithName("Failed Save Issue Description", customAttributes: ["error": errorString])
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    strongSelf.commentButton.enabled = true
                    strongSelf.cancelButton.enabled = true
                    strongSelf.progressIndicator.stopAnimation(nil)
                    strongSelf.progressIndicator.hidden = true
                    
                    self.editing = false
                }
            })
            
        } else if let issueComment = strongSelf.commentInfo as? QIssueComment, issueCommentMarkdown = strongSelf.editableMarkdownView?.markdown {
            Analytics.logCustomEventWithName("Clicked Save Issue Comment", customAttributes: nil)
            service.updateCommentText(issueCommentMarkdown, forRepository: repository, issueNumber: issueComment.issueNumber, commentIdentifier: issueComment.identifier, onCompletion: { (updatedIssueComment, context, error) in
                if let updatedIssueComment = updatedIssueComment as? QIssueComment {
                    if let onCommentDiscard = strongSelf.onCommentDiscard {
                        onCommentDiscard()
                    }
                    QIssueCommentStore.saveIssueComment(updatedIssueComment)
                    Analytics.logCustomEventWithName("Successful Save Issue Comment", customAttributes: nil)
                } else {
                    let errorString: String
                    if let error = error {
                        errorString = error.localizedDescription
                    } else {
                        errorString = ""
                    }
                    Analytics.logCustomEventWithName("Failed Save Issue Comment", customAttributes: ["error": errorString])
                }
                dispatch_async(dispatch_get_main_queue()) {
                    
                    strongSelf.commentButton.enabled = true
                    strongSelf.cancelButton.enabled = true
                    strongSelf.progressIndicator.stopAnimation(nil)
                    strongSelf.progressIndicator.hidden = true
                    
                    self.editing = false
                }
            })
        }
    }
    
    private func setupReactionsViewController() {
        assert(NSThread.isMainThread())
        let reactionsView = reactionsViewController.view
        
        if editing {
            editableMarkdownViewBottomConstraint?.constant = 0
            reactionsView.removeFromSuperview()
        } else {
            reactionsViewController.reloadReactions()
            
            let block = {
                if self.reactionsViewController.hasReactions {
                    if reactionsView.superview == nil {
                        self.commentMarkdownContainerView.addSubview(reactionsView)
                        reactionsView.translatesAutoresizingMaskIntoConstraints = false
                        let reactionsHeight: CGFloat = IssueCommentTableViewCell.reactionViewerHeight
                        reactionsView.leftAnchor.constraintEqualToAnchor(self.commentMarkdownContainerView.leftAnchor).active = true
                        //reactionsView.rightAnchor.constraintEqualToAnchor(commentMarkdownContainerView.rightAnchor).active = true
                        reactionsView.bottomAnchor.constraintEqualToAnchor(self.commentMarkdownContainerView.bottomAnchor).active = true
                        reactionsView.heightAnchor.constraintEqualToConstant(reactionsHeight).active = true
                        self.editableMarkdownViewBottomConstraint?.constant = -reactionsHeight
                    }
                    
                } else {
                    self.editableMarkdownViewBottomConstraint?.constant = 0
                    reactionsView.removeFromSuperview()
                }
            }
            
            if NSThread.isMainThread() {
                block()
            } else {
                dispatch_sync(dispatch_get_main_queue(), block)
            }
        }
        
    }
    
    
    private func setupEditableMarkdownView() -> Bool {
        guard let commentInfo = commentInfo where self.editableMarkdownView == nil else { return false }
        let editableMarkdownView = EditableMarkdownView(commentInfo: commentInfo)
        
        editableMarkdownView.disableScrolling = true
        commentMarkdownContainerView.addSubview(editableMarkdownView)
        //        editableMarkdownView.pinAnchorsToSuperview()
        editableMarkdownView.translatesAutoresizingMaskIntoConstraints = false
        editableMarkdownView.leftAnchor.constraintEqualToAnchor(commentMarkdownContainerView.leftAnchor).active = true
        editableMarkdownView.rightAnchor.constraintEqualToAnchor(commentMarkdownContainerView.rightAnchor).active = true
        editableMarkdownView.topAnchor.constraintEqualToAnchor(commentMarkdownContainerView.topAnchor).active = true
        
        editableMarkdownViewBottomConstraint = editableMarkdownView.bottomAnchor.constraintEqualToAnchor(commentMarkdownContainerView.bottomAnchor)
        editableMarkdownViewBottomConstraint?.active = true
        
        setupReactionsViewController()
        
        self.editableMarkdownView = editableMarkdownView
        editableMarkdownView.onHeightChanged = onHeightChanged
        editableMarkdownView.onTextChange = onTextChange
        
        editableMarkdownView.didDoubleClick = { [weak self] in
            guard let strongSelf = self where strongSelf.isCurrentUserACollaborator() && strongSelf.editing == false else { return }
            strongSelf.editing = true
        }
        
        editableMarkdownView.onEnterKeyPressed = { [weak self] in
            self?.didClickCommentButton()
        }
        
        editableMarkdownView.onDragExited = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.layer?.borderWidth = 0
        }
        
        editableMarkdownView.onDragEntered = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.layer?.borderWidth = 2
            strongSelf.layer?.borderColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1).CGColor
        }
        
        editableMarkdownView.onFileUploadChange = { [weak self] in
            guard let strongSelf = self else { return }
            let fileUploadCount = editableMarkdownView.currentUploadCount
            if fileUploadCount == 0 {
                strongSelf.uploadFileProgressIndicator.hideProgress()
                strongSelf.uploadFileProgressIndicator.hidden = true
                strongSelf.commentButton.enabled = true
                strongSelf.cancelButton.enabled = true
            } else {
                strongSelf.uploadFileProgressIndicator.showProgressWithString("Uploading \(fileUploadCount) file\(fileUploadCount == 1 ? "" : "s")")
                strongSelf.uploadFileProgressIndicator.hidden = false
                strongSelf.commentButton.enabled = false
                strongSelf.cancelButton.enabled = false
            }
        }
        
        return true
    }
    
    private func setupButtons() {
        guard commentButton.superview == nil && cancelButton.superview == nil else { return }
        commentButton.text = "Comment"
        cancelButton.text = "Discard"
        
        commentButton.onClick = { [weak self] in
            self?.didClickCommentButton()
        }
        
        cancelButton.onClick = { [weak self] in
            if let _ = self?.commentInfo as? QIssue {
                Analytics.logCustomEventWithName("Clicked Discard Issue Description", customAttributes: nil)
            } else {
                Analytics.logCustomEventWithName("Clicked Discard Issue Comment", customAttributes: nil)
            }
            
            let discardAction = {
                guard let commentInfo = self?.commentInfo else { return }
                self?.editableMarkdownView?.commentInfo = commentInfo
                
                if let onCommentDiscard = self?.onCommentDiscard {
                    onCommentDiscard()
                }
                
                self?.editing = false
            }
            
            if self?.commentInfo?.commentBody() != self?.editableMarkdownView?.string {
                NSAlert.showWarningMessage("Are you sure you want to discard your changes?", onConfirmation: discardAction);
            } else {
                discardAction()
            }
        }
        
        [commentButton, cancelButton].forEach { (bttn) in
            addSubview(bttn)
            bttn.translatesAutoresizingMaskIntoConstraints = false
            bttn.heightAnchor.constraintEqualToConstant(IssueCommentTableViewCell.buttonSize.height).active = true
            bttn.widthAnchor.constraintEqualToConstant(IssueCommentTableViewCell.buttonSize.width).active = true
            bttn.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -IssueCommentTableViewCell.buttonsBottomPadding).active = true
        }
        
        commentButton.rightAnchor.constraintEqualToAnchor(rightAnchor, constant: -IssueCommentTableViewCell.submitButtonRightPadding).active = true
        cancelButton.rightAnchor.constraintEqualToAnchor(commentButton.leftAnchor, constant: -IssueCommentTableViewCell.buttonsSpacing).active = true
    }
    
    private func setupProgressIndicator() {
        guard progressIndicator.superview == nil else { return }
        addSubview(progressIndicator)
        progressIndicator.style = .SpinningStyle
        progressIndicator.hidden = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.heightAnchor.constraintEqualToConstant(IssueCommentTableViewCell.progressIndicatorSize.height).active = true
        progressIndicator.widthAnchor.constraintEqualToConstant(IssueCommentTableViewCell.progressIndicatorSize.width).active = true
        progressIndicator.rightAnchor.constraintEqualToAnchor(cancelButton.leftAnchor, constant: -IssueCommentTableViewCell.progressIndicatorRightPadding).active = true
        progressIndicator.centerYAnchor.constraintEqualToAnchor(cancelButton.centerYAnchor).active = true
    }
    
    @IBAction func didClickMenuButton(sender: AnyObject) {
        guard let event = NSApp.currentEvent else { return }
        let menu = SRMenu()
        
        let editComment = NSMenuItem(title: "Edit comment", action: #selector(IssueCommentTableViewCell.didClickEditComment), keyEquivalent: "")
        menu.addItem(editComment)
        
        if let _ = commentInfo as? QIssueComment {
            let deleteComment = NSMenuItem(title: "Delete comment", action: #selector(IssueCommentTableViewCell.didClickDeleteComment), keyEquivalent: "")
            menu.addItem(deleteComment)
        }
        
        menu.addItem(NSMenuItem.separatorItem())
        
        let copyTextAsMarkdown = NSMenuItem(title: "Copy text as markdown", action: #selector(IssueCommentTableViewCell.copyTextAsMarkdown), keyEquivalent: "")
        menu.addItem(copyTextAsMarkdown)
        
        let copyTextAsHTML = NSMenuItem(title: "Copy text as HTML", action: #selector(IssueCommentTableViewCell.copyTextAsHTML), keyEquivalent: "")
        menu.addItem(copyTextAsHTML)
        
        menu.addItem(NSMenuItem.separatorItem())
        
        if let commentInfo = commentInfo, _ = commentInfo.htmlURL {
            let sharingServices = NSSharingService.sharingServicesForItems(itemsForShareService())
            if sharingServices.count > 0 {
                let shareMenu = NSMenuItem(title: "Share", action: nil, keyEquivalent: "") //, action: #selector(IssueCommentTableViewCell.shareComment), keyEquivalent: "")
                let shareSubmenu = SRMenu()
                sharingServices.forEach({ (service) in
                    let item = NSMenuItem(title: service.title, action: #selector(IssueCommentTableViewCell.shareFromService(_:)), keyEquivalent: "")
                    item.representedObject = service
                    service.delegate = self
                    item.target = self
                    item.image = service.image
                    shareSubmenu.addItem(item);
                })
                
                shareMenu.submenu = shareSubmenu
                menu.addItem(shareMenu)
            }
        }
        
        let pointInWindow = menuButton.convertPoint(CGPoint.zero, toView: nil)
        let point = NSPoint(x: pointInWindow.x + menuButton.frame.width - menu.size.width, y: pointInWindow.y - menuButton.frame.height)
        if let windowNumber = window?.windowNumber, popupEvent = NSEvent.mouseEventWithType(.LeftMouseUp, location: point, modifierFlags: event.modifierFlags, timestamp: 0, windowNumber: windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0) {
            SRMenu.popUpContextMenu(menu, withEvent: popupEvent, forView: self.menuButton)
        }
    }
    
    private func itemsForShareService() -> [AnyObject] {
        if let commentInfo = commentInfo, htmlURL = commentInfo.htmlURL {
            return ["\n Shared via @cashewappco\n", htmlURL]
        } else {
            return [AnyObject]()
        }
    }
    
    @objc
    private func shareFromService(sender: AnyObject) {
        guard let menuItem = sender as? NSMenuItem, shareService = menuItem.representedObject as? NSSharingService, commentInfo = commentInfo, _ = commentInfo.htmlURL else { return }
        shareService.performWithItems(itemsForShareService())
    }
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        
        if menuItem.action == #selector(IssueCommentTableViewCell.didClickEditComment) || menuItem.action == #selector(IssueCommentTableViewCell.didClickDeleteComment) {
            return isCurrentUserACollaborator()
        }
        
        return true;
    }
    
    private func isCurrentUserACollaborator() -> Bool {
        guard let commentInfo = commentInfo else { return false }
        let currentAccount = QContext.sharedContext().currentAccount
        let currentUser = QOwnerStore.ownerForAccountId(currentAccount.identifier, identifier: currentAccount.userId)
        return QAccount.isCurrentUserCollaboratorOfRepository(commentInfo.repo()) || commentInfo.author() == currentUser
    }
    
//    override func updateTrackingAreas() {
//        if let trackingArea = mouseTrackingArea {
//            removeTrackingArea(trackingArea)
//        }
//        
//        let trackingArea = NSTrackingArea(rect: bounds, options: [NSTrackingAreaOptions.ActiveInKeyWindow, NSTrackingAreaOptions.MouseEnteredAndExited] , owner: self, userInfo: nil)
//        self.addTrackingArea(trackingArea);
//        self.mouseTrackingArea = trackingArea
//    }
//    
//    override func mouseEntered(theEvent: NSEvent) {
//        // self.menuButton.hidden = false
//    }
//    
//    override func mouseExited(theEvent: NSEvent) {
//        //  self.menuButton.hidden = true
//    }
    
    // MARK: Actions
    
    @IBAction func didClickReactionsButton(sender: AnyObject) {
        guard reactionPickerPopover == nil else { return }
        
        let size = NSMakeSize(288.0, 48.0)
        
        guard let reactionsPickerViewController = ReactionsPickerViewController(nibName: "ReactionsPickerViewController", bundle: nil) else { return }
        reactionsPickerViewController.view.frame = NSMakeRect(0, 0, size.width, size.height);
        reactionsPickerViewController.commentInfo = commentInfo
        
        let popover = NSPopover()
        
        if .Dark == NSUserDefaults.themeMode() {
            let appearance = NSAppearance(named: NSAppearanceNameAqua)
            popover.appearance = appearance;
        } else {
            let appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
            popover.appearance = appearance;
        }
        
        popover.delegate = self
        reactionsPickerViewController.popover = popover
        popover.contentSize = size
        popover.contentViewController = reactionsPickerViewController
        popover.animates = true
        popover.behavior = .Transient
        popover.showRelativeToRect(likeButton.bounds, ofView:likeButton, preferredEdge:.MinY);
        self.reactionPickerPopover = popover
        
        NSNotificationCenter.defaultCenter().postNotificationName(IssueCommentTableViewCell.willShowReactionNotification, object: popover, userInfo: nil)
    }
    
    
    @objc
    private func copyTextAsMarkdown() {
        if let markdown = self.editableMarkdownView?.markdown {
            let pasteboard = NSPasteboard.generalPasteboard()
            //[pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            pasteboard.declareTypes([NSStringPboardType], owner: nil)
            pasteboard.setString(markdown, forType: NSStringPboardType)
        }
    }
    
    @objc
    private func copyTextAsHTML() {
        if let html = self.editableMarkdownView?.html {
            let pasteboard = NSPasteboard.generalPasteboard()
            //[pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            pasteboard.declareTypes([NSStringPboardType], owner: nil)
            pasteboard.setString(html, forType: NSStringPboardType)
        }
    }
    
    @objc
    private func shareComment() {
        //        if let html = self.editableMarkdownView?.html {
        //            let pasteboard = NSPasteboard.generalPasteboard()
        //            //[pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        //            pasteboard.declareTypes([NSStringPboardType], owner: nil)
        //            pasteboard.setString(html, forType: NSStringPboardType)
        //        }
    }
    
    @objc
    private func didClickEditComment() {
        if let _ = commentInfo as? QIssue {
            Analytics.logCustomEventWithName("Clicked Edit Issue Description", customAttributes: nil)
        } else {
            Analytics.logCustomEventWithName("Clicked Edit Issue Comment", customAttributes: nil)
        }
        editing = true
    }
    
    @objc
    private func didClickDeleteComment() {
        guard let comment = commentInfo as? QIssueComment, account = comment.account, repository = comment.repository else { return }
        
        if let onCommentDiscard = self.onCommentDiscard {
            onCommentDiscard()
        }
        
        Analytics.logCustomEventWithName("Clicked Delete Issue Comment", customAttributes: nil)
        
        NSAlert.showWarningMessage("Are you sure you want to delete this comment?") {
            QIssuesService(forAccount: account).deleteIssueComment(comment, onCompletion: { (responseObject, context, error) in
                if let error = error, data = error.userInfo["com.alamofire.serialization.response.error.data"] as? NSData {
                    let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                    DDLogDebug("deletedComment=> \(dataString)");
                } else {
                    QIssueCommentStore.deleteIssueCommentId(comment.identifier, accountId:account.identifier, repositoryId:repository.identifier)
                }
                
            })
        }
    }
}

extension IssueCommentTableViewCell: NSSharingServiceDelegate {
    
}

extension IssueCommentTableViewCell: NSPopoverDelegate {
    func popoverDidClose(notification: NSNotification) {
        if let popover = notification.object as? NSPopover where self.reactionPickerPopover == popover {
            self.reactionPickerPopover = nil
        }
    }
}


extension IssueCommentTableViewCell: QStoreObserver {
    
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {
        if let issue = record as? QIssue, commentInfo = commentInfo as? QIssue where store == QIssueStore.self && issue == commentInfo {
            reloadReactionsAndNotifyHeightChangeWithCommentInfo(commentInfo)
        } else if let issueComment = record as? QIssueComment, commentInfo = commentInfo as? QIssueComment where store == QIssueCommentStore.self && issueComment == commentInfo {
            reloadReactionsAndNotifyHeightChangeWithCommentInfo(commentInfo)
        } else if let reaction = record as? SRIssueReaction, commentInfo = commentInfo as? QIssue where commentInfo.number == reaction.issueNumber && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            //  reloadReactionsAndNotifyHeightChange()
        } else if let reaction = record as? SRIssueCommentReaction, commentInfo = commentInfo as? QIssueComment where commentInfo.identifier == reaction.issueCommentIdentifier && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            //  reloadReactionsAndNotifyHeightChange()
        }
    }
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {
        if let reaction = record as? SRIssueReaction, commentInfo = commentInfo as? QIssue where commentInfo.number == reaction.issueNumber && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            // reloadReactionsAndNotifyHeightChange()
        } else if let reaction = record as? SRIssueCommentReaction, commentInfo = commentInfo as? QIssueComment where commentInfo.identifier == reaction.issueCommentIdentifier && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            // reloadReactionsAndNotifyHeightChange()
        }
    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        if let issue = record as? QIssue, commentInfo = commentInfo as? QIssue where store == QIssueStore.self && issue == commentInfo {
            reloadReactionsAndNotifyHeightChangeWithCommentInfo(commentInfo)
        } else if let issueComment = record as? QIssueComment, commentInfo = commentInfo as? QIssueComment where store == QIssueCommentStore.self && issueComment == commentInfo {
            reloadReactionsAndNotifyHeightChangeWithCommentInfo(commentInfo)
        } else if let reaction = record as? SRIssueReaction, commentInfo = commentInfo as? QIssue where commentInfo.number == reaction.issueNumber && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            reloadReactionsAndNotifyHeightChangeWithCommentInfo(commentInfo)
        } else if let reaction = record as? SRIssueCommentReaction, commentInfo = commentInfo as? QIssueComment where commentInfo.identifier == reaction.issueCommentIdentifier && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            // reloadReactionsAndNotifyHeightChange()
        }
    }
    
    private func reloadReactionsAndNotifyHeightChangeWithCommentInfo(commentInfo: QIssueCommentInfo) {
        let block = {
            self.commentInfo = commentInfo
            self.setupReactionsViewController()
            self.invalidateIntrinsicContentSize()
            if let onHeightChanged = self.onHeightChanged {
                onHeightChanged()
            }
        }
        
        if NSThread.isMainThread() {
            block()
        } else {
            dispatch_sync(dispatch_get_main_queue(), block)
        }
        
    }
}



