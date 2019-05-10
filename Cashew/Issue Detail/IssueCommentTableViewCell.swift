//
//  IssueCommentTableViewCell.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/24/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa
import os.log

class CommentMarkdownContainerView: BaseView { }

class ReactionButton: NSButton {
    
    fileprivate var mouseTrackingArea: NSTrackingArea?
    var onMouseOver: (()->())?
    
    override func mouseEntered(with theEvent: NSEvent) {
        if let onMouseOver = onMouseOver {
            onMouseOver()
        }
        
        super.mouseEntered(with: theEvent)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let previousTrackingArea = mouseTrackingArea {
            removeTrackingArea(previousTrackingArea)
        }
        
        let area = NSTrackingArea(rect: bounds, options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited], owner: self, userInfo: nil)
        mouseTrackingArea = area
        addTrackingArea(area)
    }
    
    override func layout() {
        super.layout()
        updateTrackingAreas()
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let area = NSTrackingArea(rect: bounds, options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited], owner: self, userInfo: nil)
        mouseTrackingArea = area
        addTrackingArea(area)
    }
}

@IBDesignable class IssueCommentTableViewCell: BaseView {
    
    static let reactionViewerHeight: CGFloat = 26
    
    fileprivate static let willShowReactionNotification = "willShowReactionNotification"
    
    fileprivate static let menuButtonsColor = NSColor(calibratedWhite: 147/255.0, alpha: 0.85)
    fileprivate static let buttonSize = CGSize(width: 92, height: 30)
    fileprivate static let buttonsSpacing: CGFloat = 8
    fileprivate static let submitButtonRightPadding: CGFloat = 6
    fileprivate static let buttonsBottomPadding: CGFloat = 13
    fileprivate static let progressIndicatorRightPadding: CGFloat = 6.0
    fileprivate static let progressIndicatorSize = CGSize(width: 17, height: 17)
    fileprivate static let markdownCommentContainerViewBottomLayoutConstraintEditConstaint: CGFloat = 50.0
    
    @IBOutlet weak var commentContainerBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentContainerTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainContainerLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainContainerRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentMarkdownContainerView: CommentMarkdownContainerView!
    
    @IBOutlet weak fileprivate var usernameLabel: NSTextField!
    @IBOutlet weak fileprivate var dateLabel: NSTextField!
    @IBOutlet weak fileprivate var usernameAvatarView: BaseView!
    @IBOutlet weak var menuButton: NSButton!
    
    @IBOutlet weak var headerContainerView: BaseView!
    fileprivate var editableMarkdownView: EditableMarkdownView?
    
    fileprivate let cancelButton = BaseButton.whiteButton()
    fileprivate let commentButton = BaseButton.greenButton()
    fileprivate let progressIndicator = NSProgressIndicator()
    fileprivate let uploadFileProgressIndicator = LabeledProgressIndicatorView()
    
    @IBOutlet weak var likeButton: ReactionButton!
    //private var mouseTrackingArea: NSTrackingArea?
    
    @IBOutlet weak var bottomHorizontalLineView: BaseView!
    @IBOutlet weak var markdownCommentContainerViewBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    
    fileprivate var editableMarkdownViewBottomConstraint: NSLayoutConstraint?
    fileprivate let reactionsViewController: ReactionsViewController = ReactionsViewController(nibName: "ReactionsViewController", bundle: nil)
    fileprivate var reactionPickerPopover: NSPopover?
    
    @objc var text: String? {
        get {
            return editableMarkdownView?.string
        }
    }
    
    @objc var isMarkdownEditorFirstResponder: Bool {
        return editableMarkdownView?.isFirstResponder ?? false
    }
    
    @objc var draft: IssueCommentDraft? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                if let strongSelf = self, let draft = strongSelf.draft, let editableMarkdownView = strongSelf.editableMarkdownView {
                    strongSelf.editing = true
                    editableMarkdownView.string = draft.body
                    strongSelf.didSetEditing()
                }
            }
        }
    }
    
    @objc var editing: Bool = false {
        didSet {
            if oldValue != editing {
                didSetEditing()
            }
        }
    }
    
    @objc var imageURLs: [URL] {
        get {
            return editableMarkdownView?.imageURLs as [URL]? ?? [URL]()
        }
    }
    @objc var onTextChange: (()->())? {
        didSet {
            if let editableMarkdownView = editableMarkdownView,
                let onTextChange = onTextChange {
                editableMarkdownView.onTextChange = onTextChange
            }
        }
    }
    
    @objc var onCommentDiscard: (()->())?
    
    @objc var onHeightChanged: (()->())? {
        didSet {
            if let editableMarkdownView = editableMarkdownView,
                let onHeightChanged = onHeightChanged {
                editableMarkdownView.onHeightChanged = onHeightChanged
            }
        }
    }
    
    @objc var didClickImageBlock: ((_ url: URL?) -> ())? {
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
    
    @objc var commentInfo: QIssueCommentInfo? {
        didSet {
            
            if editableMarkdownView?.isFirstResponder == false {
                editing = false
            }
            assert(Thread.isMainThread, "not on main thread");
            
            
            if let aUsername = self.commentInfo?.username() {
                self.usernameLabel.stringValue = aUsername
            } else {
                self.usernameLabel.stringValue = ""
            }
            
            if let aDate = self.commentInfo?.commentedOn() as? NSDate {
                var didUseFullDate = ObjCBool(false)
                if let dateString = aDate.timeAgo(forWeekOrLessAndDidUseFullDate: &didUseFullDate) {
                    if didUseFullDate.boolValue {
                        self.dateLabel.stringValue = String(format: "commented on %@", dateString)
                    } else {
                        self.dateLabel.stringValue = String(format: "commented %@", dateString)
                    }
                }      
            } else {
                self.dateLabel.stringValue = ""
            }
            
            if let aUsernameAvararURL = self.commentInfo?.usernameAvatarURL() {
                self.usernameAvatarView.setImageURL(aUsernameAvararURL)
            } else {
                self.usernameAvatarView.setImageURL(nil)
            }
            
            if let commentInfo = commentInfo , oldValue == nil || oldValue!.commentBody() != commentInfo.commentBody() {
                if setupEditableMarkdownView() == false {
                    editableMarkdownView?.commentInfo = commentInfo
                }
            }
            
            reactionsViewController.commentInfo = commentInfo
            setupReactionsViewController()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(IssueCommentTableViewCell.willShowReactionNotification)
        editableMarkdownView?.onDragExited = nil
        editableMarkdownView?.onDragEntered = nil
        editableMarkdownView?.onHeightChanged = nil
        editableMarkdownView?.onFileUploadChange = nil
        QIssueStore.remove(self)
        QIssueCommentStore.remove(self)
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
        SRIssueCommentReactionStore.remove(self)
        SRIssueReactionStore.remove(self)
    }
    
    @objc override func awakeFromNib() {
        super.awakeFromNib()
        
        NotificationCenter.default.addObserver(self, selector: #selector(IssueCommentTableViewCell.willShowReaction(_:)), name: NSNotification.Name(rawValue: IssueCommentTableViewCell.willShowReactionNotification), object: nil)
        
        QIssueStore.add(self)
        QIssueCommentStore.add(self)
        SRIssueCommentReactionStore.add(self)
        SRIssueReactionStore.add(self)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        usernameAvatarView.layer?.cornerRadius = usernameAvatarView.frame.height / 2.0
        usernameAvatarView.layer?.masksToBounds = true
        
        self.menuButton.isHidden = false
        
        CATransaction.commit()
        
//        let trackingArea = NSTrackingArea(rect: bounds, options:  [NSTrackingAreaOptions.ActiveInKeyWindow, NSTrackingAreaOptions.MouseEnteredAndExited] , owner: self, userInfo: nil)
//        self.addTrackingArea(trackingArea);
//        self.mouseTrackingArea = trackingArea
        
        self.likeButton.image = self.likeButton.image?.withTintColor(NSColor(calibratedWhite: 125/255.0, alpha: 1))
        
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
            
            if mode == .light {
                strongSelf.backgroundColor = LightModeColor.sharedInstance.backgroundColor()
                strongSelf.usernameLabel.textColor = LightModeColor.sharedInstance.foregroundSecondaryColor()
                strongSelf.dateLabel.textColor = LightModeColor.sharedInstance.foregroundTertiaryColor()
                strongSelf.menuButton.image = NSImage(named: "chevron-down")?.withTintColor(IssueCommentTableViewCell.menuButtonsColor)
                strongSelf.progressIndicator.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
            } else if mode == .dark {
                strongSelf.backgroundColor = DarkModeColor.sharedInstance.backgroundColor()
                strongSelf.usernameLabel.textColor = DarkModeColor.sharedInstance.foregroundSecondaryColor()
                strongSelf.dateLabel.textColor = DarkModeColor.sharedInstance.foregroundTertiaryColor()
                strongSelf.menuButton.image = NSImage(named: "chevron-down")?.withTintColor(IssueCommentTableViewCell.menuButtonsColor)
                strongSelf.progressIndicator.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
            }
            
            strongSelf.likeButton.image = NSImage(named: "reactions")?.withTintColor(IssueCommentTableViewCell.menuButtonsColor)
        }
        
        likeButton.onMouseOver = { [weak self] in
            guard let strongSelf = self , strongSelf.reactionPickerPopover == nil else { return }
            strongSelf.didClickReactionsButton(strongSelf.likeButton)
        }
    }
    
    
    @objc
    fileprivate func willShowReaction(_ notification: Notification) {
        if let obj = notification.object as? NSPopover , obj != self.reactionPickerPopover {
            self.reactionPickerPopover?.close()
        }
    }
    
    
    fileprivate func didSetEditing() {
        if editing {
            markdownCommentContainerViewBottomLayoutConstraint.constant = IssueCommentTableViewCell.markdownCommentContainerViewBottomLayoutConstraintEditConstaint
            cancelButton.isHidden = false
            commentButton.isHidden = false
        } else {
            markdownCommentContainerViewBottomLayoutConstraint.constant = 0
            cancelButton.isHidden = true
            commentButton.isHidden = true
        }
        
        editableMarkdownView?.editing = editing
        setupReactionsViewController()
        invalidateIntrinsicContentSize()
        
    }
    
    fileprivate func setupFileUploadProgressIndicator() {
        guard uploadFileProgressIndicator.superview == nil else { return }
        
        addSubview(uploadFileProgressIndicator)
        uploadFileProgressIndicator.isHidden = true
        uploadFileProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        uploadFileProgressIndicator.leftAnchor.constraint(equalTo: commentMarkdownContainerView.leftAnchor).isActive = true
        
        uploadFileProgressIndicator.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        uploadFileProgressIndicator.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        uploadFileProgressIndicator.heightAnchor.constraint(equalToConstant: IssueCommentTableViewCell.buttonSize.height).isActive = true
        uploadFileProgressIndicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -IssueCommentTableViewCell.buttonsBottomPadding).isActive = true
    }
    
    fileprivate func didClickCommentButton() {
        let strongSelf = self
        
        guard let repository = strongSelf.commentInfo?.repo(), let account = strongSelf.commentInfo?.repo().account else { return }
        
        strongSelf.commentButton.enabled = false
        strongSelf.cancelButton.enabled = false
        strongSelf.progressIndicator.startAnimation(nil)
        strongSelf.progressIndicator.isHidden = false
        
        let service = QIssuesService(for: account)
        if let issue = strongSelf.commentInfo as? QIssue {
            service.saveIssueBody(strongSelf.editableMarkdownView?.markdown, for: repository, number: issue.number, onCompletion: { (updatedIssue, context, error) in
                if let updatedIssue = updatedIssue as? QIssue {
                    if let onCommentDiscard = strongSelf.onCommentDiscard {
                        onCommentDiscard()
                    }
                    
                    QIssueStore.save(updatedIssue)
                }
                
                DispatchQueue.main.async {
                    
                    strongSelf.commentButton.enabled = true
                    strongSelf.cancelButton.enabled = true
                    strongSelf.progressIndicator.stopAnimation(nil)
                    strongSelf.progressIndicator.isHidden = true
                    
                    self.editing = false
                }
            })
            
        } else if let issueComment = strongSelf.commentInfo as? QIssueComment, let issueCommentMarkdown = strongSelf.editableMarkdownView?.markdown {
            service.updateCommentText(issueCommentMarkdown, for: repository, issueNumber: issueComment.issueNumber, commentIdentifier: issueComment.identifier, onCompletion: { (updatedIssueComment, context, error) in
                if let updatedIssueComment = updatedIssueComment as? QIssueComment {
                    if let onCommentDiscard = strongSelf.onCommentDiscard {
                        onCommentDiscard()
                    }
                    QIssueCommentStore.save(updatedIssueComment)
                }
                DispatchQueue.main.async {
                    
                    strongSelf.commentButton.enabled = true
                    strongSelf.cancelButton.enabled = true
                    strongSelf.progressIndicator.stopAnimation(nil)
                    strongSelf.progressIndicator.isHidden = true
                    
                    self.editing = false
                }
            })
        }
    }
    
    fileprivate func setupReactionsViewController() {
//        DDLogDebug("IssueCommentTableViewCell setupReactionsVC - reactionsVC: \(reactionsViewController)")
        assert(Thread.isMainThread)
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
                        reactionsView.leftAnchor.constraint(equalTo: self.commentMarkdownContainerView.leftAnchor).isActive = true
                        //reactionsView.rightAnchor.constraintEqualToAnchor(commentMarkdownContainerView.rightAnchor).active = true
                        reactionsView.bottomAnchor.constraint(equalTo: self.commentMarkdownContainerView.bottomAnchor).isActive = true
                        reactionsView.heightAnchor.constraint(equalToConstant: reactionsHeight).isActive = true
                        self.editableMarkdownViewBottomConstraint?.constant = -reactionsHeight
                    }
                    
                } else {
                    self.editableMarkdownViewBottomConstraint?.constant = 0
                    reactionsView.removeFromSuperview()
                }
            }
            
            if Thread.isMainThread {
                block()
            } else {
                DispatchQueue.main.sync(execute: block)
            }
        }
        
    }
    
    
    fileprivate func setupEditableMarkdownView() -> Bool {
        guard let commentInfo = commentInfo , self.editableMarkdownView == nil else { return false }
        let editableMarkdownView = EditableMarkdownView(commentInfo: commentInfo)
        
        editableMarkdownView.disableScrolling = true
        commentMarkdownContainerView.addSubview(editableMarkdownView)
        //        editableMarkdownView.pinAnchorsToSuperview()
        editableMarkdownView.translatesAutoresizingMaskIntoConstraints = false
        editableMarkdownView.leftAnchor.constraint(equalTo: commentMarkdownContainerView.leftAnchor).isActive = true
        editableMarkdownView.rightAnchor.constraint(equalTo: commentMarkdownContainerView.rightAnchor).isActive = true
        editableMarkdownView.topAnchor.constraint(equalTo: commentMarkdownContainerView.topAnchor).isActive = true
        
        editableMarkdownViewBottomConstraint = editableMarkdownView.bottomAnchor.constraint(equalTo: commentMarkdownContainerView.bottomAnchor)
        editableMarkdownViewBottomConstraint?.isActive = true
        
        setupReactionsViewController()
        
        self.editableMarkdownView = editableMarkdownView
        editableMarkdownView.onHeightChanged = onHeightChanged
        editableMarkdownView.onTextChange = onTextChange
        
        editableMarkdownView.didDoubleClick = { [weak self] in
            guard let strongSelf = self , strongSelf.isCurrentUserACollaborator() && strongSelf.editing == false else { return }
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
            strongSelf.layer?.borderColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1).cgColor
        }
        
        editableMarkdownView.onFileUploadChange = { [weak self] in
            guard let strongSelf = self else { return }
            let fileUploadCount = editableMarkdownView.currentUploadCount
            if fileUploadCount == 0 {
                strongSelf.uploadFileProgressIndicator.hideProgress()
                strongSelf.uploadFileProgressIndicator.isHidden = true
                strongSelf.commentButton.enabled = true
                strongSelf.cancelButton.enabled = true
            } else {
                strongSelf.uploadFileProgressIndicator.showProgressWithString("Uploading \(fileUploadCount) file\(fileUploadCount == 1 ? "" : "s")")
                strongSelf.uploadFileProgressIndicator.isHidden = false
                strongSelf.commentButton.enabled = false
                strongSelf.cancelButton.enabled = false
            }
        }
        
        return true
    }
    
    fileprivate func setupButtons() {
        guard commentButton.superview == nil && cancelButton.superview == nil else { return }
        commentButton.text = "Comment"
        cancelButton.text = "Discard"
        
        commentButton.onClick = { [weak self] in
            self?.didClickCommentButton()
        }
        
        cancelButton.onClick = { [weak self] in
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
            bttn.heightAnchor.constraint(equalToConstant: IssueCommentTableViewCell.buttonSize.height).isActive = true
            bttn.widthAnchor.constraint(equalToConstant: IssueCommentTableViewCell.buttonSize.width).isActive = true
            bttn.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -IssueCommentTableViewCell.buttonsBottomPadding).isActive = true
        }
        
        commentButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -IssueCommentTableViewCell.submitButtonRightPadding).isActive = true
        cancelButton.rightAnchor.constraint(equalTo: commentButton.leftAnchor, constant: -IssueCommentTableViewCell.buttonsSpacing).isActive = true
    }
    
    fileprivate func setupProgressIndicator() {
        guard progressIndicator.superview == nil else { return }
        addSubview(progressIndicator)
        progressIndicator.style = .spinning
        progressIndicator.isHidden = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.heightAnchor.constraint(equalToConstant: IssueCommentTableViewCell.progressIndicatorSize.height).isActive = true
        progressIndicator.widthAnchor.constraint(equalToConstant: IssueCommentTableViewCell.progressIndicatorSize.width).isActive = true
        progressIndicator.rightAnchor.constraint(equalTo: cancelButton.leftAnchor, constant: -IssueCommentTableViewCell.progressIndicatorRightPadding).isActive = true
        progressIndicator.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor).isActive = true
    }
    
    @IBAction func didClickMenuButton(_ sender: AnyObject) {
        guard let event = NSApp.currentEvent else { return }
        let menu = SRMenu()
        
        let editComment = NSMenuItem(title: "Edit comment", action: #selector(IssueCommentTableViewCell.didClickEditComment), keyEquivalent: "")
        menu.addItem(editComment)
        
        if let _ = commentInfo as? QIssueComment {
            let deleteComment = NSMenuItem(title: "Delete comment", action: #selector(IssueCommentTableViewCell.didClickDeleteComment), keyEquivalent: "")
            menu.addItem(deleteComment)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let copyTextAsMarkdown = NSMenuItem(title: "Copy text as markdown", action: #selector(IssueCommentTableViewCell.copyTextAsMarkdown), keyEquivalent: "")
        menu.addItem(copyTextAsMarkdown)
        
        let copyTextAsHTML = NSMenuItem(title: "Copy text as HTML", action: #selector(IssueCommentTableViewCell.copyTextAsHTML), keyEquivalent: "")
        menu.addItem(copyTextAsHTML)
        
        menu.addItem(NSMenuItem.separator())
        
        if let commentInfo = commentInfo, let _ = commentInfo.htmlURL {
            let sharingServices = NSSharingService.sharingServices(forItems: itemsForShareService())
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
        
        let pointInWindow = menuButton.convert(CGPoint.zero, to: nil)
        let point = NSPoint(x: pointInWindow.x + menuButton.frame.width - menu.size.width, y: pointInWindow.y - menuButton.frame.height)
        if let windowNumber = window?.windowNumber, let popupEvent = NSEvent.mouseEvent(with: .leftMouseUp, location: point, modifierFlags: event.modifierFlags, timestamp: 0, windowNumber: windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0) {
            SRMenu.popUpContextMenu(menu, with: popupEvent, for: self.menuButton)
        }
    }
    
    fileprivate func itemsForShareService() -> [AnyObject] {
        if let commentInfo = commentInfo, let htmlURL = commentInfo.htmlURL {
            return ["\n Shared via @cashewappco\n" as AnyObject, htmlURL as AnyObject]
        } else {
            return [AnyObject]()
        }
    }
    
    @objc
    fileprivate func shareFromService(_ sender: AnyObject) {
        guard let menuItem = sender as? NSMenuItem, let shareService = menuItem.representedObject as? NSSharingService, let commentInfo = commentInfo, let _ = commentInfo.htmlURL else { return }
        shareService.perform(withItems: itemsForShareService())
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        if menuItem.action == #selector(IssueCommentTableViewCell.didClickEditComment) || menuItem.action == #selector(IssueCommentTableViewCell.didClickDeleteComment) {
            return isCurrentUserACollaborator()
        }
        
        return true;
    }
    
    fileprivate func isCurrentUserACollaborator() -> Bool {
        guard let commentInfo = commentInfo else { return false }
        let currentAccount = QContext.shared().currentAccount
        let currentUser = QOwnerStore.owner(forAccountId: currentAccount?.identifier, identifier: currentAccount?.userId)
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
    
    @IBAction func didClickReactionsButton(_ sender: AnyObject) {
        guard reactionPickerPopover == nil else { return }
        
        let size = NSMakeSize(288.0, 48.0)
        
        let reactionsPickerViewController = ReactionsPickerViewController(nibName: "ReactionsPickerViewController", bundle: nil)
        reactionsPickerViewController.view.frame = NSMakeRect(0, 0, size.width, size.height);
        reactionsPickerViewController.commentInfo = commentInfo
        
        let popover = NSPopover()
        
        if .dark == UserDefaults.themeMode() {
            let appearance = NSAppearance(named: NSAppearance.Name.aqua)
            popover.appearance = appearance;
        } else {
            let appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
            popover.appearance = appearance;
        }
        
        popover.delegate = self
        reactionsPickerViewController.popover = popover
        popover.contentSize = size
        popover.contentViewController = reactionsPickerViewController
        popover.animates = true
        popover.behavior = .transient
        popover.show(relativeTo: likeButton.bounds, of:likeButton, preferredEdge:.minY);
        self.reactionPickerPopover = popover
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: IssueCommentTableViewCell.willShowReactionNotification), object: popover, userInfo: nil)
    }
    
    
    @objc
    fileprivate func copyTextAsMarkdown() {
        if let markdown = self.editableMarkdownView?.markdown {
            let pasteboard = NSPasteboard.general
            //[pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(markdown, forType: .string)
        }
    }
    
    @objc
    fileprivate func copyTextAsHTML() {
        if let html = self.editableMarkdownView?.html {
            let pasteboard = NSPasteboard.general
            //[pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(html, forType: .string)
        }
    }
    
    @objc
    fileprivate func shareComment() {
        //        if let html = self.editableMarkdownView?.html {
        //            let pasteboard = NSPasteboard.generalPasteboard()
        //            //[pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        //            pasteboard.declareTypes([NSStringPboardType], owner: nil)
        //            pasteboard.setString(html, forType: NSStringPboardType)
        //        }
    }
    
    @objc
    fileprivate func didClickEditComment() {
        editing = true
    }
    
    @objc
    fileprivate func didClickDeleteComment() {
        guard let comment = commentInfo as? QIssueComment, let account = comment.account, let repository = comment.repository else { return }
        
        if let onCommentDiscard = self.onCommentDiscard {
            onCommentDiscard()
        }
        
        NSAlert.showWarningMessage("Are you sure you want to delete this comment?") {
            QIssuesService(for: account).delete(comment, onCompletion: { (responseObject, context, error) in
                if let error = error as? NSError, let data = error.userInfo["com.alamofire.serialization.response.error.data"] as? NSData {
                    let dataString = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)
                    os_log("deletedComment=> %@", log: .default, type: .debug, dataString ?? "")
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
    func popoverDidClose(_ notification: Notification) {
        if let popover = notification.object as? NSPopover , self.reactionPickerPopover == popover {
            self.reactionPickerPopover = nil
        }
    }
}


extension IssueCommentTableViewCell: QStoreObserver {
    
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {
        if let issue = record as? QIssue, let commentInfo = commentInfo as? QIssue , store == QIssueStore.self && issue == commentInfo {
            reloadReactionsAndNotifyHeightChangeWithCommentInfo(commentInfo)
        } else if let issueComment = record as? QIssueComment, let commentInfo = commentInfo as? QIssueComment , store == QIssueCommentStore.self && issueComment == commentInfo {
            reloadReactionsAndNotifyHeightChangeWithCommentInfo(commentInfo)
        } else if let reaction = record as? SRIssueReaction, let commentInfo = commentInfo as? QIssue , commentInfo.number == reaction.issueNumber && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            //  reloadReactionsAndNotifyHeightChange()
        } else if let reaction = record as? SRIssueCommentReaction, let commentInfo = commentInfo as? QIssueComment , commentInfo.identifier == reaction.issueCommentIdentifier && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            //  reloadReactionsAndNotifyHeightChange()
        }
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {
        if let reaction = record as? SRIssueReaction, let commentInfo = commentInfo as? QIssue , commentInfo.number == reaction.issueNumber && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            // reloadReactionsAndNotifyHeightChange()
        } else if let reaction = record as? SRIssueCommentReaction, let commentInfo = commentInfo as? QIssueComment , commentInfo.identifier == reaction.issueCommentIdentifier && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            // reloadReactionsAndNotifyHeightChange()
        }
    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        if let issue = record as? QIssue, let commentInfo = commentInfo as? QIssue , store == QIssueStore.self && issue == commentInfo {
            reloadReactionsAndNotifyHeightChangeWithCommentInfo(commentInfo)
        } else if let issueComment = record as? QIssueComment, let commentInfo = commentInfo as? QIssueComment , store == QIssueCommentStore.self && issueComment == commentInfo {
            reloadReactionsAndNotifyHeightChangeWithCommentInfo(commentInfo)
        } else if let reaction = record as? SRIssueReaction, let commentInfo = commentInfo as? QIssue , commentInfo.number == reaction.issueNumber && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            reloadReactionsAndNotifyHeightChangeWithCommentInfo(commentInfo)
        } else if let reaction = record as? SRIssueCommentReaction, let commentInfo = commentInfo as? QIssueComment , commentInfo.identifier == reaction.issueCommentIdentifier && commentInfo.repository == reaction.repository && reaction.account == commentInfo.account {
            // reloadReactionsAndNotifyHeightChange()
        }
    }
    
    fileprivate func reloadReactionsAndNotifyHeightChangeWithCommentInfo(_ commentInfo: QIssueCommentInfo) {
        let block = {
            self.commentInfo = commentInfo
            self.setupReactionsViewController()
            self.invalidateIntrinsicContentSize()
            if let onHeightChanged = self.onHeightChanged {
                onHeightChanged()
            }
        }
        
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync(execute: block)
        }
        
    }
}



