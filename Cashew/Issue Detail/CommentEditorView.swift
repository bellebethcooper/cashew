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
    
    fileprivate static let buttonSize = CGSize(width: 80, height: 24)
    fileprivate static let verticalSpacing: CGFloat = 8.0
    fileprivate static let leftSpacing: CGFloat = 8.0
    fileprivate static let rightSpacing: CGFloat = 8.0
    
    fileprivate static let buttonVerticalPadding: CGFloat = 3.0
    fileprivate static let buttonHorizontalPadding: CGFloat = 6.0
    fileprivate static let progressIndicatorSize = CGSize(width: 17, height: 17)
    fileprivate static let firstReponderMinTextViewHeight: CGFloat = 120.0
    
    
    @objc var onSubmit: (()->())?
    @objc var onTextChange: (()->())?
    @objc var onDiscard: (()->())?
    @objc var text: String? {
        get {
            return textView.string
        }
        set(newValue) {
            textView.string = newValue
        }
    }
    
    @objc var enabled: Bool = true {
        didSet {
            textView.editable = enabled
            submitButton.enabled = enabled
            cancelButton.enabled = enabled
        }
    }
    
    fileprivate let textView = MarkdownEditorTextView()
    fileprivate let uploadFileProgressIndicator = LabeledProgressIndicatorView()
    fileprivate let textViewContainerView = TextViewContainerView()
    fileprivate let submitButton = BaseButton.greenButton()
    fileprivate let cancelButton = BaseButton.whiteButton()
    fileprivate let progressIndicator = NSProgressIndicator()
    
    @objc var activateTextViewConstraints: Bool = false {
        didSet {
            textView.activateTextViewConstraints = activateTextViewConstraints
        }
    }
    
    @objc var loading: Bool = false {
        didSet {
            if loading {
                progressIndicator.isHidden = false
                progressIndicator.startAnimation(nil)
                cancelButton.enabled = false
                submitButton.enabled = false
            } else {
                progressIndicator.isHidden = true
                progressIndicator.stopAnimation(nil)
                cancelButton.enabled = true
                submitButton.enabled = true
            }
        }
    }
    
    @objc var isFirstResponder: Bool {
        get {
            return textView.isFirstResponder
        }
    }
    
    deinit {
        onSubmit = nil
        onTextChange = nil
        onDiscard = nil
        textView.delegate = nil
        
        NotificationCenter.default.removeObserver(self)
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
            let contentSize = CGSize(width: textContentSize().width, height: calculatedHeight)
            
            return contentSize
        }
    }
    
    fileprivate func setupFileUploadProgressIndicator() {
        guard uploadFileProgressIndicator.superview == nil else { return }
        
        addSubview(uploadFileProgressIndicator)
        
        uploadFileProgressIndicator.backgroundColor = NSColor.clear
        uploadFileProgressIndicator.isHidden = true
        uploadFileProgressIndicator.translatesAutoresizingMaskIntoConstraints = false
        uploadFileProgressIndicator.leftAnchor.constraint(equalTo: textView.leftAnchor).isActive = true
        
        uploadFileProgressIndicator.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        uploadFileProgressIndicator.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .horizontal)
        uploadFileProgressIndicator.heightAnchor.constraint(equalToConstant: CommentEditorView.buttonSize.height).isActive = true
        uploadFileProgressIndicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -CommentEditorView.verticalSpacing).isActive = true
    }
    
    @objc
    fileprivate func didBecomeFirstResponderNotifiation(_ notification: Notification) {
        if let obj = notification.object as? NSObject , textView.isEqualToTextView(obj) {
            needsLayout = true
            invalidateIntrinsicContentSize()
            layoutSubtreeIfNeeded()
            textView.collapseToolbar = !isFirstResponder
        } else if let window = self.window , textView.collapseToolbar != true && textView.textSizePopover == nil && !textView.isShowingPopover && window.isKeyWindow && !textView.isShowingPreview {
            textView.collapseToolbar = true
            needsLayout = true
            invalidateIntrinsicContentSize()
            layoutSubtreeIfNeeded()
        }
    }
    
    fileprivate func setupEditor() {
        NotificationCenter.default.addObserver(self, selector: #selector(CommentEditorView.didBecomeFirstResponderNotifiation(_:)), name: NSNotification.Name.didBecomeFirstResponder, object: nil)
        
        self.allowMouseToMoveWindow = false

        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if mode == .dark {
                strongSelf.backgroundColor = CashewColor.currentLineBackgroundColor()
                strongSelf.textViewContainerView.borderColor = NSColor.white
                strongSelf.progressIndicator.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
            } else {
                strongSelf.backgroundColor = NSColor.white
                strongSelf.textViewContainerView.borderColor = NSColor.clear //NSColor(calibratedWhite: 200/255.0, alpha: 1)
                strongSelf.progressIndicator.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
            }
        }
        
        guard textViewContainerView.superview == nil else { return }
        
        addSubview(textViewContainerView)
        textViewContainerView.addSubview(textView)
        
        textViewContainerView.disableThemeObserver = true
        textViewContainerView.backgroundColor = NSColor.white
        //textViewContainerView.borderColor = CashewColor.separatorColor() //NSColor(calibratedWhite: 220/255.0, alpha: 1)
        textViewContainerView.cornerRadius = 3.0
//        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(CommentEditorView.didClickTextViewContainerView(_:)))
//        textViewContainerView.addGestureRecognizer(clickRecognizer)
        
        textView.forceLightModeForMarkdownPreview = true
        textView.delegate = self
        textView.textColor = NSColor.black
        textView.backgroundColor = NSColor.white
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.disableScrollViewBounce = true
        
        textView.onEnterKeyPressed = { [weak self] in
            self?.didClickSubmit()
        }
        
        textView.onDragExited = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.textViewContainerView.layer?.borderWidth = 1
            strongSelf.textViewContainerView.layer?.borderColor = CashewColor.separatorColor().cgColor
            strongSelf.invalidateIntrinsicContentSize()
        }
        
        textView.onDragEntered = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.textViewContainerView.layer?.borderWidth = 2
            strongSelf.textViewContainerView.layer?.borderColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1).cgColor
            strongSelf.invalidateIntrinsicContentSize()
        }
        
        textView.onFileUploadChange = { [weak self] in
            guard let strongSelf = self else { return }
            let fileUploadCount = strongSelf.textView.currentUploadCount
            if fileUploadCount == 0 {
                strongSelf.uploadFileProgressIndicator.hideProgress()
                strongSelf.uploadFileProgressIndicator.isHidden = true
                strongSelf.submitButton.enabled = true
                strongSelf.cancelButton.enabled = true
            } else {
                strongSelf.uploadFileProgressIndicator.showProgressWithString("Uploading \(fileUploadCount) file\(fileUploadCount == 1 ? "" : "s")")
                strongSelf.uploadFileProgressIndicator.isHidden = false
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
    fileprivate func didClickTextViewContainerView(_ sender: AnyObject) {
        if !textView.isFirstResponder {
            textView.makeFirstResponder()
        }
    }
    
    override func layout() {
        
        let layouts = calculateLayouts(isFirstResponder)
        
        submitButton.isHidden = !isFirstResponder
        cancelButton.isHidden = !isFirstResponder
        
        textView.frame = layouts.textViewRect
        textViewContainerView.frame = layouts.textViewContainerViewRect
        cancelButton.frame = layouts.cancelButtonRect
        submitButton.frame = layouts.submitButtonRect
        progressIndicator.frame = layouts.progressIndicatorRect
        
        super.layout()
    }
    
    fileprivate func calculateLayouts(_ isFirstResponse: Bool) -> (textViewRect: CGRect, textViewContainerViewRect: CGRect, cancelButtonRect: CGRect, submitButtonRect: CGRect, progressIndicatorRect: CGRect) {
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
    
    fileprivate func textContentSize() -> NSSize {
        let containerWidth: CGFloat = bounds.width - CommentEditorView.leftSpacing - CommentEditorView.rightSpacing
        return textView.calculatedSizeForWidth(containerWidth)
    }
    
    fileprivate func textSizeForAttributedString(_ stringVal: NSAttributedString) -> NSSize {
        let textStorage = NSTextStorage(attributedString: stringVal)
        let textContainer = NSTextContainer(containerSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude) )
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        layoutManager.glyphRange(for: textContainer)
        let size = layoutManager.usedRect(for: textContainer).size
        
        return size
    }
    
    @objc func clearText() {
        textView.string = ""
    }

    @objc
    func clearPreviewModeIfNecessary() {
        textView.clearPreviewModeIfNecessary()
    }
    
    // MARK: Setup code
    
    fileprivate func setupProgressIndicator() {
        guard progressIndicator.superview == nil else { return }
        addSubview(progressIndicator)
        progressIndicator.isHidden = true
        progressIndicator.style = .spinning
    }
    
    fileprivate func setupCancelButton() {
        guard cancelButton.superview == nil else { return }
        addSubview(cancelButton)
        cancelButton.text = "Discard"
        cancelButton.onClick = { [weak self] in
            self?.didClickCancel()
        }
    }
    
    fileprivate func setupSubmitButton() {
        guard submitButton.superview == nil else { return }
        addSubview(submitButton)
        submitButton.text = "Comment"
        submitButton.onClick = { [weak self] in
            self?.didClickSubmit()
        }
    }
    
    // MARK: Actions
    
    @objc
    fileprivate func didClickCancel() {
        guard let onDiscard = onDiscard else  { return }
        onDiscard()
    }
    
    @objc
    fileprivate func didClickSubmit() {
        guard let onSubmit = onSubmit else { return }
        onSubmit()
    }
    
}

extension CommentEditorView: NSTextViewDelegate {
    
    func textViewDidChangeSelection(_ notification: Notification) {
        guard textView.editable else { return }
        
        invalidateIntrinsicContentSize()
        setNeedsDisplay(bounds)
        if let onTextChange = onTextChange {
            onTextChange()
        }
    }
    
    func textDidBeginEditing(_ notification: Notification) {
        guard textView.editable else { return }
        invalidateIntrinsicContentSize()
        setNeedsDisplay(bounds)
    }
    
    func textDidEndEditing(_ notification: Notification) {
        guard textView.editable && !textView.isShowingPopover && !textView.isShowingPreview else { return }
        invalidateIntrinsicContentSize()
        textView.undoManager?.removeAllActions()
        DispatchQueue.main.async(execute: {
            self.setNeedsDisplay(self.bounds)
            self.loading = false
            self.superview?.window?.makeFirstResponder(self.superview) // makes sure the current text view doesn't get first responder after nspopover
        })
    }
}
