//
//  EditableMarkdownView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/11/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class EditableMarkdownView: BaseView {
    
    private static let textViewEdgeInset = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    private var markdownWebView: QIssueMarkdownWebView?
    private let textView = MarkdownEditorTextView()
    private var mardownWebViewContentSize: CGSize?
    
    deinit {
        markdownWebView = nil
        onFileUploadChange = nil
        onHeightChanged = nil
        onTextChange = nil
        onDragEntered = nil
        onDragExited = nil
        textView.delegate = nil
        
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    var disableScrolling = false {
        didSet {
            textView.disableScrolling = true
        }
    }
    
    var isFirstResponder: Bool {
        get {
            return textView.isFirstResponder
        }
    }
    
    var string: String? {
        get {
            guard textView.isFirstResponder else { return commentInfo.commentBody() }
            
            return textView.string
        }
        
        set(newValue) {
            textView.string = newValue
            markdown = newValue ?? ""
        }
    }
    
    var onTextChange: dispatch_block_t?
    
    var onHeightChanged: dispatch_block_t? {
        didSet {
            didSetHeightChanged()
        }
    }
    
    var didClickImageBlock: ((url: NSURL!) -> ())? {
        didSet {
            markdownWebView?.didClickImageBlock = didClickImageBlock
        }
    }
    
    var onEnterKeyPressed: dispatch_block_t? {
        didSet {
            textView.onEnterKeyPressed = onEnterKeyPressed
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
            return markdownWebView?.imageURLs ?? [NSURL]()
        }
    }
    
    var currentUploadCount: Int {
        get {
            return textView.currentUploadCount
        }
    }
    
    var commentInfo: QIssueCommentInfo {
        didSet {
            markdown = commentInfo.commentBody()
        }
    }
    
    var didDoubleClick: dispatch_block_t? {
        didSet {
            markdownWebView?.didDoubleClick = didDoubleClick
        }
    }
    
    var onFileUploadChange: dispatch_block_t? {
        didSet {
            textView.onFileUploadChange = onFileUploadChange
        }
    }
    
    var onDragEntered: dispatch_block_t? {
        didSet {
            textView.onDragEntered = onDragEntered
        }
    }
    
    var onDragExited: dispatch_block_t? {
        didSet {
            textView.onDragExited = onDragExited
        }
    }
    
    private(set) var markdown: String {
        didSet {
            didSetMarkdownString()
        }
    }
    
    private(set) var html: String?
    
    required init(commentInfo: QIssueCommentInfo) {
        self.commentInfo = commentInfo
        self.markdown = commentInfo.commentBody()
        super.init(frame: NSRect.zero)
        
        setupTextView()
        didSetEditing()
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(strongSelf)
                return;
            }
            strongSelf.backgroundColor = CashewColor.backgroundColor()
            strongSelf.textView.textColor = CashewColor.foregroundColor()
            if mode == .Dark {
                strongSelf.textView.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
            } else {
                strongSelf.textView.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func didSetMarkdownString() {
        setupMarkdownWebView()
        if textView.string != self.markdown {
            textView.string = self.markdown
        }
    }
    
    private func didSetHeightChanged() {
        guard let markdownWebView  = markdownWebView else { return }
        markdownWebView.didResizeBlock = { [weak self] (rect) in
            
            self?.mardownWebViewContentSize = rect.size
            if let onHeightChanged = self?.onHeightChanged {
                onHeightChanged()
            }
        }
    }
    
    private func didSetEditing() {
        setupMarkdownWebView()
        guard let markdownWebView = markdownWebView else { return }
        
        if editing {
            textView.hidden = false
            markdownWebView.hidden = true
            self.textView.collapseToolbar = false
            self.textView.activateTextViewConstraints = true
            
            dispatch_async(dispatch_get_main_queue(), {
                //self.window?.makeFirstResponder(self.textView)
                self.textView.makeFirstResponder()
            });
        } else {
            textView.hidden = true
            markdownWebView.hidden = false
            self.textView.activateTextViewConstraints = false
        }
        
        invalidateIntrinsicContentSize()
        if let onHeightChanged = onHeightChanged {
            onHeightChanged()
        }
    }
    
    override var intrinsicContentSize: NSSize {
        get {
            if editing {
                let textSize = textContentSize()
                return NSSize(width: bounds.width, height: textSize.height + EditableMarkdownView.textViewEdgeInset.top + EditableMarkdownView.textViewEdgeInset.bottom)
            } else {
                guard let mardownWebViewContentSize = mardownWebViewContentSize else {
                    return CGSize.zero
                }
                return NSSize(width: mardownWebViewContentSize.width, height: max(mardownWebViewContentSize.height,  EditableMarkdownView.textViewEdgeInset.top + EditableMarkdownView.textViewEdgeInset.bottom))
            }
        }
    }
    
    private func textContentSize() -> NSSize {
        let containerWidth: CGFloat = bounds.width //- EditableMarkdownView.textViewEdgeInset.left - EditableMarkdownView.textViewEdgeInset.right

        //borderColor = NSColor.redColor()
        return self.textView.calculatedSizeForWidth(containerWidth)
    }
    
    // MARK: General Setup
    
    private func setupTextView() {
        textView.string = self.markdown
        
        addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.delegate = self
        textView.drawsBackground = false
        textView.leftAnchor.constraintEqualToAnchor(leftAnchor, constant: 0).active = true
        textView.rightAnchor.constraintEqualToAnchor(rightAnchor, constant: 0).active = true
        textView.topAnchor.constraintEqualToAnchor(topAnchor, constant: EditableMarkdownView.textViewEdgeInset.top).active = true
        textView.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -EditableMarkdownView.textViewEdgeInset.bottom).active = true
        textView.focusRingType = NSFocusRingType.Default
        textView.font = NSFont.systemFontOfSize(14)
        textView.collapseToolbar = false
        textView.disableScrollViewBounce = true
        textView.registerDragAndDrop()
    }
    
    private func setupMarkdownWebView() {
        guard self.editing == false else { return }
        
        if let currentMarkdownWebView = self.markdownWebView {
            currentMarkdownWebView.removeFromSuperview()
            self.markdownWebView = nil
        }
        
        let markdownParser = MarkdownParser()
        let html = markdownParser.parse(commentInfo.commentBody(), forRepository: commentInfo.repo())
        self.html = html
        let markdownWebView = QIssueMarkdownWebView(HTMLString: html) { [weak self] (rect) in
            self?.mardownWebViewContentSize = rect.size
            self?.invalidateIntrinsicContentSize()
            if let onHeightChanged = self?.onHeightChanged {
                onHeightChanged()
            }
        }
        self.markdownWebView = markdownWebView
        markdownWebView.didDoubleClick = didDoubleClick
        
        addSubview(markdownWebView)
        markdownWebView.translatesAutoresizingMaskIntoConstraints = false
        
        markdownWebView.leftAnchor.constraintEqualToAnchor(leftAnchor).active = true
        markdownWebView.rightAnchor.constraintEqualToAnchor(rightAnchor, constant: -EditableMarkdownView.textViewEdgeInset.right).active = true
        markdownWebView.topAnchor.constraintEqualToAnchor(topAnchor).active = true
        markdownWebView.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        didSetHeightChanged()
    }
}

extension EditableMarkdownView: NSTextViewDelegate {
    
//    override func controlTextDidChange(obj: NSNotification) {
//        
//    }
    
    func textDidChange(notification: NSNotification) {
        markdown = textView.string ?? ""
        invalidateIntrinsicContentSize()
        setNeedsDisplayInRect(bounds)
        if let onHeightChanged = onHeightChanged {
            onHeightChanged()
        }
        if let onTextChange = onTextChange {
            onTextChange()
        }
    }
    
    func textDidBeginEditing(notification: NSNotification) {
        invalidateIntrinsicContentSize()
        setNeedsDisplayInRect(bounds)
    }
    
    func textDidEndEditing(notification: NSNotification) {
        invalidateIntrinsicContentSize()
        setNeedsDisplayInRect(bounds)
        if !textView.isShowingPopover {
        textView.undoManager?.removeAllActions()
        }
    }
}
