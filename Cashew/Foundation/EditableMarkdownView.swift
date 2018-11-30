//
//  EditableMarkdownView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/11/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class EditableMarkdownView: BaseView {
    
    fileprivate static let textViewEdgeInset = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    fileprivate var markdownWebView: QIssueMarkdownWebView?
    fileprivate let textView = MarkdownEditorTextView()
    fileprivate var mardownWebViewContentSize: CGSize?
    
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
    
    var onTextChange: (()->())?
    
    var onHeightChanged: (()->())? {
        didSet {
            didSetHeightChanged()
        }
    }
    
    var didClickImageBlock: ((_ url: URL?) -> ())? {
        didSet {
            markdownWebView?.didClickImageBlock = didClickImageBlock
        }
    }
    
    var onEnterKeyPressed: (()->())? {
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
    
    var imageURLs: [URL] {
        get {
            return markdownWebView?.imageURLs ?? [URL]()
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
    
    var didDoubleClick: (()->())? {
        didSet {
            markdownWebView?.didDoubleClick = didDoubleClick
        }
    }
    
    var onFileUploadChange: (()->())? {
        didSet {
            textView.onFileUploadChange = onFileUploadChange
        }
    }
    
    var onDragEntered: (()->())? {
        didSet {
            textView.onDragEntered = onDragEntered
        }
    }
    
    var onDragExited: (()->())? {
        didSet {
            textView.onDragExited = onDragExited
        }
    }
    
    fileprivate(set) var markdown: String {
        didSet {
            didSetMarkdownString()
        }
    }
    
    fileprivate(set) var html: String?
    
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
            strongSelf.textView.textColor = CashewColor.foregroundSecondaryColor()
            if mode == .dark {
                strongSelf.textView.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
            } else {
                strongSelf.textView.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func didSetMarkdownString() {
        setupMarkdownWebView()
        if textView.string != self.markdown {
            textView.string = self.markdown
        }
    }
    
    fileprivate func didSetHeightChanged() {
        guard let markdownWebView  = markdownWebView else { return }
        markdownWebView.didResizeBlock = { [weak self] (rect) in
            
            self?.mardownWebViewContentSize = rect.size
            if let onHeightChanged = self?.onHeightChanged {
                onHeightChanged()
            }
        }
    }
    
    fileprivate func didSetEditing() {
        setupMarkdownWebView()
        guard let markdownWebView = markdownWebView else { return }
        
        if editing {
            textView.isHidden = false
            markdownWebView.isHidden = true
            self.textView.collapseToolbar = false
            self.textView.activateTextViewConstraints = true
            
            DispatchQueue.main.async(execute: {
                //self.window?.makeFirstResponder(self.textView)
                self.textView.makeFirstResponder()
            });
        } else {
            textView.isHidden = true
            markdownWebView.isHidden = false
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
    
    fileprivate func textContentSize() -> NSSize {
        let containerWidth: CGFloat = bounds.width //- EditableMarkdownView.textViewEdgeInset.left - EditableMarkdownView.textViewEdgeInset.right

        //borderColor = NSColor.redColor()
        return self.textView.calculatedSizeForWidth(containerWidth)
    }
    
    // MARK: General Setup
    
    fileprivate func setupTextView() {
        textView.string = self.markdown
        
        addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.delegate = self
        textView.drawsBackground = false
        textView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        textView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
        textView.topAnchor.constraint(equalTo: topAnchor, constant: EditableMarkdownView.textViewEdgeInset.top).isActive = true
        textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -EditableMarkdownView.textViewEdgeInset.bottom).isActive = true
        textView.focusRingType = NSFocusRingType.default
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.collapseToolbar = false
        textView.disableScrollViewBounce = true
        textView.registerDragAndDrop()
    }
    
    fileprivate func setupMarkdownWebView() {
        guard self.editing == false else { return }
        
        if let currentMarkdownWebView = self.markdownWebView {
            currentMarkdownWebView.removeFromSuperview()
            self.markdownWebView = nil
        }
        
        let markdownParser = MarkdownParser()
        let html = markdownParser.parse(commentInfo.commentBody(), for: commentInfo.repo())
        self.html = html
        let markdownWebView = QIssueMarkdownWebView(htmlString: html) { [weak self] (rect) in
            self?.mardownWebViewContentSize = rect.size
            self?.invalidateIntrinsicContentSize()
            if let onHeightChanged = self?.onHeightChanged {
                onHeightChanged()
            }
        }
        self.markdownWebView = markdownWebView
        markdownWebView?.didDoubleClick = didDoubleClick
        
        addSubview(markdownWebView!)
        markdownWebView?.translatesAutoresizingMaskIntoConstraints = false
        
        markdownWebView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        markdownWebView?.rightAnchor.constraint(equalTo: rightAnchor, constant: -EditableMarkdownView.textViewEdgeInset.right).isActive = true
        markdownWebView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        markdownWebView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        didSetHeightChanged()
    }
}

extension EditableMarkdownView: NSTextViewDelegate {
    
//    override func controlTextDidChange(obj: NSNotification) {
//        
//    }
    
    func textDidChange(_ notification: Notification) {
        markdown = textView.string ?? ""
        invalidateIntrinsicContentSize()
        setNeedsDisplay(bounds)
        if let onHeightChanged = onHeightChanged {
            onHeightChanged()
        }
        if let onTextChange = onTextChange {
            onTextChange()
        }
    }
    
    func textDidBeginEditing(_ notification: Notification) {
        invalidateIntrinsicContentSize()
        setNeedsDisplay(bounds)
    }
    
    func textDidEndEditing(_ notification: Notification) {
        invalidateIntrinsicContentSize()
        setNeedsDisplay(bounds)
        if !textView.isShowingPopover {
        textView.undoManager?.removeAllActions()
        }
    }
}
