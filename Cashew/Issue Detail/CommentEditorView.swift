//
//  CommentEditorView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/23/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

private class TextViewContainerView: BaseView {
    
}

class CommentEditorView: BaseView {
    
    private static let buttonSize = CGSize(width: 80, height: 24)
    private static let verticalSpacing: CGFloat = 8.0
    private static let leftSpacing: CGFloat = 8.0
    private static let rightSpacing: CGFloat = 8.0
    
    private static let buttonVerticalPadding: CGFloat = 3.0
    private static let buttonHorizontalPadding: CGFloat = 6.0
    private static let progressIndicatorSize = CGSizeMake(17, 17)
    private static let firstReponderMinTextViewHeight: CGFloat = 120.0
    
    
    var onSubmit: dispatch_block_t?
    var onTextChange: dispatch_block_t?
    var onDiscard: dispatch_block_t?
    var text: String? {
        get {
            return textView.string
        }
        set(newValue) {
            textView.string = newValue
        }
    }
    
    var enabled: Bool = true {
        didSet {
            textView.editable = enabled
            submitButton.enabled = enabled
            cancelButton.enabled = enabled
        }
    }
    
    private let textView = MarkdownEditorTextView()
    private let uploadFileProgressIndicator = LabeledProgressIndicatorView()
    private let textViewContainerView = TextViewContainerView()
    private let submitButton = BaseButton.greenButton()
    private let cancelButton = BaseButton.whiteButton()
    private let progressIndicator = NSProgressIndicator()
    
    var activateTextViewConstraints: Bool = false {
        didSet {
            textView.activateTextViewConstraints = activateTextViewConstraints
        }
    }
    
    var loading: Bool = false {
        didSet {
            if loading {
                progressIndicator.hidden = false
                progressIndicator.startAnimation(nil)
                cancelButton.enabled = false
                submitButton.enabled = false
            } else {
                progressIndicator.hidden = true
                progressIndicator.stopAnimation(nil)
                cancelButton.enabled = true
                submitButton.enabled = true
            }
        }
    }
    
    var isFirstResponder: Bool {
        get {
            return textView.isFirstResponder
        }
    }
    
    deinit {
        onSubmit = nil
        onTextChange = nil
        onDiscard = nil
        textView.delegate = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    convenience init() {
        self.init(frame: NSRect.zero);
        setupEditor()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupEditor()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEditor()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupEditor()
    }
    
    override var intrinsicContentSize: NSSize {
        get {
            let layouts = calculateLayouts(isFirstResponder)
            let rect = layouts.textViewContainerViewRect
            let size = rect.size
            let expandedHeight = (isFirstResponder ? layouts.submitButtonRect.height + CommentEditorView.verticalSpacing : 0)
            let calculatedHeight = size.height + CommentEditorView.verticalSpacing * 2.0 + expandedHeight
            let contentSize = CGSizeMake(textContentSize().width, calculatedHeight)
            
            return contentSize
        }
    }
    
    private func setupFileUploadProgressIndicator() {
        guard uploadFileProgressIndicator.superview == nil else { return }
        
        addSubview(uploadFileProgressIndicator)
        
        uploadFileProgressIndicator.backgroundColor = NSColor.clearColor()
        uploadFileProgressIndicator.hidden = true
        uploadFileProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        uploadFileProgressIndicator.leftAnchor.constraintEqualToAnchor(textView.leftAnchor).active = true
        
        uploadFileProgressIndicator.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        uploadFileProgressIndicator.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Horizontal)
        uploadFileProgressIndicator.heightAnchor.constraintEqualToConstant(CommentEditorView.buttonSize.height).active = true
        uploadFileProgressIndicator.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -CommentEditorView.verticalSpacing).active = true
    }
    
    @objc
    private func didBecomeFirstResponderNotifiation(notification: NSNotification) {
        if let obj = notification.object as? NSObject where textView.isEqualToTextView(obj) {
            needsLayout = true
            invalidateIntrinsicContentSize()
            layoutSubtreeIfNeeded()
            textView.collapseToolbar = !isFirstResponder
        } else if let window = self.window where textView.collapseToolbar != true && textView.textSizePopover == nil && !textView.isShowingPopover && window.keyWindow && !textView.isShowingPreview {
            textView.collapseToolbar = true
            needsLayout = true
            invalidateIntrinsicContentSize()
            layoutSubtreeIfNeeded()
        }
    }
    
    private func setupEditor() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentEditorView.didBecomeFirstResponderNotifiation(_:)), name: kDidBecomeFirstResponderNotification, object: nil)
        
        self.allowMouseToMoveWindow = false

        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if mode == .Dark {
                strongSelf.backgroundColor = CashewColor.currentLineBackgroundColor()
                strongSelf.textViewContainerView.borderColor = NSColor.whiteColor()
                strongSelf.progressIndicator.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
            } else {
                strongSelf.backgroundColor = CashewColor.sidebarBackgroundColor()
                strongSelf.textViewContainerView.borderColor = NSColor(calibratedWhite: 200/255.0, alpha: 1)
                strongSelf.progressIndicator.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
            }
        }
        
        guard textViewContainerView.superview == nil else { return }
        
        addSubview(textViewContainerView)
        textViewContainerView.addSubview(textView)
        
        textViewContainerView.disableThemeObserver = true
        textViewContainerView.backgroundColor = NSColor.whiteColor()
        //textViewContainerView.borderColor = CashewColor.separatorColor() //NSColor(calibratedWhite: 220/255.0, alpha: 1)
        textViewContainerView.cornerRadius = 3.0
//        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(CommentEditorView.didClickTextViewContainerView(_:)))
//        textViewContainerView.addGestureRecognizer(clickRecognizer)
        
        textView.forceLightModeForMarkdownPreview = true
        textView.delegate = self
        textView.textColor = NSColor.blackColor()
        textView.backgroundColor = NSColor.whiteColor()
        textView.font = NSFont.systemFontOfSize(14)
        textView.disableScrollViewBounce = true
        
        textView.onEnterKeyPressed = { [weak self] in
            self?.didClickSubmit()
        }
        
        textView.onDragExited = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.textViewContainerView.layer?.borderWidth = 1
            strongSelf.textViewContainerView.layer?.borderColor = CashewColor.separatorColor().CGColor
            strongSelf.invalidateIntrinsicContentSize()
        }
        
        textView.onDragEntered = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.textViewContainerView.layer?.borderWidth = 2
            strongSelf.textViewContainerView.layer?.borderColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1).CGColor
            strongSelf.invalidateIntrinsicContentSize()
        }
        
        textView.onFileUploadChange = { [weak self] in
            guard let strongSelf = self else { return }
            let fileUploadCount = strongSelf.textView.currentUploadCount
            if fileUploadCount == 0 {
                strongSelf.uploadFileProgressIndicator.hideProgress()
                strongSelf.uploadFileProgressIndicator.hidden = true
                strongSelf.submitButton.enabled = true
                strongSelf.cancelButton.enabled = true
            } else {
                strongSelf.uploadFileProgressIndicator.showProgressWithString("Uploading \(fileUploadCount) file\(fileUploadCount == 1 ? "" : "s")")
                strongSelf.uploadFileProgressIndicator.hidden = false
                strongSelf.submitButton.enabled = false
                strongSelf.cancelButton.enabled = false
            }
        }
        
        invalidateIntrinsicContentSize()
        
        setupCancelButton()
        setupSubmitButton()
        setupProgressIndicator()
        setupFileUploadProgressIndicator()
        disableThemeObserver = false
    }
    
    @objc
    private func didClickTextViewContainerView(sender: AnyObject) {
        if !textView.isFirstResponder {
            textView.makeFirstResponder()
        }
    }
    
    override func layout() {
        
        let layouts = calculateLayouts(isFirstResponder)
        
        submitButton.hidden = !isFirstResponder
        cancelButton.hidden = !isFirstResponder
        
        textView.frame = layouts.textViewRect
        textViewContainerView.frame = layouts.textViewContainerViewRect
        cancelButton.frame = layouts.cancelButtonRect
        submitButton.frame = layouts.submitButtonRect
        progressIndicator.frame = layouts.progressIndicatorRect
        
        super.layout()
    }
    
    private func calculateLayouts(isFirstResponse: Bool) -> (textViewRect: CGRect, textViewContainerViewRect: CGRect, cancelButtonRect: CGRect, submitButtonRect: CGRect, progressIndicatorRect: CGRect) {
        let containerWidth: CGFloat = bounds.width - CommentEditorView.leftSpacing - CommentEditorView.rightSpacing
        //  let isFirstResponse = self.window?.firstResponder == textView
        
        
        let submitButtonSize = CommentEditorView.buttonSize // textSizeForAttributedString(submitButton.attributedTitle)
        let submitButtonWidth = submitButtonSize.width + CommentEditorView.buttonHorizontalPadding * 2
        let submitButtonLeft = bounds.width - CommentEditorView.rightSpacing - submitButtonWidth
        let submitButtonHeight = submitButtonSize.height + CommentEditorView.buttonVerticalPadding * 2
        let submitButtonTop = bounds.height - CommentEditorView.verticalSpacing - submitButtonHeight
        let submitButtonRect = CGRectIntegralMake(x: submitButtonLeft, y: submitButtonTop, width: submitButtonWidth, height: submitButtonHeight)
        
        let cancelButtonSize = CommentEditorView.buttonSize //textSizeForAttributedString(cancelButton.attributedTitle)
        let cancelButtonWidth = cancelButtonSize.width + CommentEditorView.buttonHorizontalPadding * 2
        let cancelButtonLeft = submitButtonRect.minX - cancelButtonWidth - CommentEditorView.rightSpacing
        let cancelButtonHeight = submitButtonSize.height + CommentEditorView.buttonVerticalPadding * 2
        let cancelButtonRect = CGRectIntegralMake(x: cancelButtonLeft, y: submitButtonRect.minY, width: cancelButtonWidth, height: cancelButtonHeight)
        
        var size = textContentSize()
        if isFirstResponse {
            size = NSMakeSize(size.width, max(CommentEditorView.firstReponderMinTextViewHeight, size.height))
        }
        
        let textViewContainerViewHeight = size.height // + CommentEditorView.verticalSpacing * 2
        let textViewContainerViewRect = CGRectIntegralMake(x: CommentEditorView.leftSpacing, y: CommentEditorView.verticalSpacing, width: containerWidth, height: textViewContainerViewHeight)
        let textViewRect = CGRectIntegralMake(x: 0, y: (textViewContainerViewRect.height/2.0-textViewContainerViewHeight/2.0), width: textViewContainerViewRect.width, height: size.height)
        //textViewContainerView.backgroundColor = NSColor.yellowColor()
        
        let progressIndicatorTop:CGFloat = cancelButtonRect.minY + cancelButtonHeight/2.0 - (CommentEditorView.progressIndicatorSize.height / 2.0)
        let progressIndicatorLeft:CGFloat = cancelButtonRect.minX - CommentEditorView.progressIndicatorSize.width - CommentEditorView.buttonHorizontalPadding
        let progressIndicatorRect = CGRect(x: progressIndicatorLeft, y: progressIndicatorTop, width: CommentEditorView.progressIndicatorSize.width, height: CommentEditorView.progressIndicatorSize.height)
        return (textViewRect: textViewRect, textViewContainerViewRect: textViewContainerViewRect, cancelButtonRect: cancelButtonRect, submitButtonRect: submitButtonRect, progressIndicatorRect: progressIndicatorRect)
    }
    
    private func textContentSize() -> NSSize {
        let containerWidth: CGFloat = bounds.width - CommentEditorView.leftSpacing - CommentEditorView.rightSpacing
        return textView.calculatedSizeForWidth(containerWidth)
    }
    
    private func textSizeForAttributedString(stringVal: NSAttributedString) -> NSSize {
        let textStorage = NSTextStorage(attributedString: stringVal)
        let textContainer = NSTextContainer(containerSize: CGSizeMake(CGFloat.max, CGFloat.max) )
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        layoutManager.glyphRangeForTextContainer(textContainer)
        let size = layoutManager.usedRectForTextContainer(textContainer).size
        
        return size
    }
    
    func clearText() {
        textView.string = ""
    }
    
    func clearPreviewModeIfNecessary() {
        textView.clearPreviewModeIfNecessary()
    }
    
    // MARK: Setup code
    
    private func setupProgressIndicator() {
        guard progressIndicator.superview == nil else { return }
        addSubview(progressIndicator)
        progressIndicator.hidden = true
        progressIndicator.style = .SpinningStyle
    }
    
    private func setupCancelButton() {
        guard cancelButton.superview == nil else { return }
        addSubview(cancelButton)
        cancelButton.text = "Discard"
        cancelButton.onClick = { [weak self] in
            self?.didClickCancel()
        }
    }
    
    private func setupSubmitButton() {
        guard submitButton.superview == nil else { return }
        addSubview(submitButton)
        submitButton.text = "Comment"
        submitButton.onClick = { [weak self] in
            self?.didClickSubmit()
        }
    }
    
    // MARK: Actions
    
    @objc
    private func didClickCancel() {
        guard let onDiscard = onDiscard else  { return }
        onDiscard()
    }
    
    @objc
    private func didClickSubmit() {
        guard let onSubmit = onSubmit else { return }
        onSubmit()
    }
    
}

extension CommentEditorView: NSTextViewDelegate {
    
    func textViewDidChangeSelection(notification: NSNotification) {
        guard textView.editable else { return }
        
        invalidateIntrinsicContentSize()
        setNeedsDisplayInRect(bounds)
        if let onTextChange = onTextChange {
            onTextChange()
        }
    }
    
    func textDidBeginEditing(notification: NSNotification) {
        guard textView.editable else { return }
        invalidateIntrinsicContentSize()
        setNeedsDisplayInRect(bounds)
    }
    
    func textDidEndEditing(notification: NSNotification) {
        guard textView.editable && !textView.isShowingPopover && !textView.isShowingPreview else { return }
        invalidateIntrinsicContentSize()
        textView.undoManager?.removeAllActions()
        dispatch_async(dispatch_get_main_queue(), {
            self.setNeedsDisplayInRect(self.bounds)
            self.loading = false
            self.superview?.window?.makeFirstResponder(self.superview) // makes sure the current text view doesn't get first responder after nspopover
        })
    }
}
