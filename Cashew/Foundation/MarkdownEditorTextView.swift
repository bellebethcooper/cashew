//
//  MarkdownEditorTextView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/21/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRMarkdownEditorTextView)
class MarkdownEditorTextView: BaseView {
    
    // private static let dragBorderColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1)
    
    private static let toolbarHeight: CGFloat = 26.0
    private static let verticalSpacing: CGFloat = 8.0
    
    private let internalTextView = InternalMarkdownEditorTextView()
    private let internalTextViewScrollView = BaseScrollView()
    private let toolbarView = MarkdownEditorToolbarView()
    private var toolbarViewHeightConstraint: NSLayoutConstraint?
    private var textViewConstraints = [NSLayoutConstraint]()
    private var previewWebView: QIssueMarkdownWebView?
    private var previewWebViewConstraints = [NSLayoutConstraint]()
    
    private(set) var textSizePopover: NSPopover?
    private(set) var giphyPopover: NSPopover?
    
    
    
    var disableScrolling = false {
        didSet {
            internalTextViewScrollView.disableScrolling = disableScrolling
        }
    }
    
    var string: String? {
        get {
            return internalTextView.string
        }
        set {
            internalTextView.string = newValue
        }
    }
    
    override var backgroundColor: NSColor! {
        didSet {
            internalTextView.backgroundColor = backgroundColor
            toolbarView.backgroundColor = backgroundColor
        }
    }
    
    var isShowingPreview: Bool {
        return internalTextView.hidden
    }
    
    var isShowingPopover: Bool {
        return self.textSizePopover != nil || self.giphyPopover != nil
    }
    
    var isFirstResponder: Bool {
        return self.window?.firstResponder == internalTextView || self.textSizePopover != nil || self.giphyPopover != nil
    }
    
    var activateTextViewConstraints: Bool = false {
        didSet {
            if activateTextViewConstraints {
                NSLayoutConstraint.activateConstraints(textViewConstraints)
                NSLayoutConstraint.activateConstraints(previewWebViewConstraints)
            } else {
                NSLayoutConstraint.deactivateConstraints(textViewConstraints)
                NSLayoutConstraint.deactivateConstraints(previewWebViewConstraints)
            }
        }
    }
    
    var hidePlaceholder: Bool {
        get {
            return internalTextView.hidePlaceholder
        }
        set {
            internalTextView.hidePlaceholder = newValue
        }
    }
    
    func isEqualToTextView(obj: NSObject) -> Bool {
        return internalTextView == obj
    }
    
    func setAsNextKeyViewForView(view: NSView) {
        view.nextKeyView = internalTextView
    }
    
    override func becomeFirstResponder() -> Bool {
//        dispatch_async(dispatch_get_main_queue()) { 
//            self.makeFirstResponder()
//        }
        return internalTextView.becomeFirstResponder();
    }
    
    func makeFirstResponder() {
        if self.window?.firstResponder != self {
            self.window?.makeFirstResponder(internalTextView)
        }
    }
    
    var currentUploadCount: Int {
        return internalTextView.currentUploadCount
    }
    
    
    var onEnterKeyPressed: dispatch_block_t? {
        didSet {
            internalTextView.onEnterKeyPressed = onEnterKeyPressed
        }
    }
    
    var onFileUploadChange: dispatch_block_t? {
        didSet {
            internalTextView.onFileUploadChange = onFileUploadChange
        }
    }
    
    var onDragEntered: dispatch_block_t? {
        didSet {
            internalTextView.onDragEntered = onDragEntered
        }
    }
    
    var onDragExited: dispatch_block_t? {
        didSet {
            internalTextView.onDragExited = onDragExited
        }
    }
    
    var editable: Bool {
        get {
            return internalTextView.editable
        }
        set {
            internalTextView.editable = newValue
        }
    }
    
    var selectable: Bool {
        get {
            return internalTextView.selectable
        }
        set {
            internalTextView.selectable = newValue
        }
    }
    
    var textColor: NSColor? {
        get {
            return internalTextView.textColor
        }
        set {
            internalTextView.textColor = newValue
        }
    }
    
    var font: NSFont? {
        get {
            return internalTextView.font
        }
        set {
            internalTextView.font = newValue
        }
    }
    
    var drawsBackground: Bool {
        get {
            return internalTextView.drawsBackground
        }
        set {
            internalTextView.drawsBackground = newValue
        }
    }
    
    var delegate: NSTextViewDelegate? {
        get {
            return internalTextView.delegate
        }
        set {
            internalTextView.delegate = newValue
        }
    }
    
    var forceLightModeForMarkdownPreview: Bool = false {
        didSet {
            if forceLightModeForMarkdownPreview {
                disableThemeObserver = true
                internalTextViewScrollView.disableThemeObserver = true
                internalTextViewScrollView.backgroundColor = NSColor.whiteColor()
                backgroundColor = NSColor.whiteColor()
            } else {
                internalTextViewScrollView.disableThemeObserver = false
            }
        }
    }
    
    var collapseToolbar = false {
        didSet {
            toolbarView.collapse = collapseToolbar
            if let toolbarViewHeightConstraint = toolbarViewHeightConstraint {
                if collapseToolbar {
                    toolbarViewHeightConstraint.constant = 0
                } else {
                    toolbarViewHeightConstraint.constant = MarkdownEditorTextView.toolbarHeight
                }
            }
        }
    }
    
    var disableScrollViewBounce: Bool = false {
        didSet {
            if disableScrollViewBounce {
                internalTextViewScrollView.verticalScrollElasticity = .None
                internalTextViewScrollView.horizontalScrollElasticity = .None
            } else {
                internalTextViewScrollView.verticalScrollElasticity = .Automatic
                internalTextViewScrollView.horizontalScrollElasticity = .Automatic
            }
        }
    }
    
    deinit {
        onFileUploadChange = nil
        onDragExited = nil
        onDragEntered = nil
        internalTextView.delegate = nil
    }
    
    func registerDragAndDrop() {
        internalTextView.registerDragAndDrop()
    }
    
    func uploadFilePaths(paths: [String]) {
        internalTextView.uploadFilePaths(paths)
    }
    
    convenience init() {
        self.init(frame: NSRect.zero)
        setup()
    }
    
    override func awakeFromNib() {
        setup()
    }
    
    func clearPreviewModeIfNecessary() {
        turnPreviewModeOff()
    }
    
    func calculatedSizeForWidth(containerWidth: CGFloat) -> NSSize {
        let stringVal = (internalTextView.string ?? "RANDOM")
        let font = internalTextView.font!
        let textStorage = NSTextStorage(string: stringVal)
        let textContainer = NSTextContainer(containerSize: CGSizeMake(containerWidth, CGFloat.max) )
        let layoutManager = NSLayoutManager()
        let attributes = [ NSFontAttributeName: font ] as [String : AnyObject]?
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textStorage.addAttributes(attributes!, range: NSMakeRange(0, (stringVal as NSString).length))
        
        layoutManager.glyphRangeForTextContainer(textContainer)
        let size = layoutManager.usedRectForTextContainer(textContainer).size
        
        return NSMakeSize(size.width,  size.height + ( collapseToolbar ? 0 : MarkdownEditorTextView.toolbarHeight) + MarkdownEditorTextView.verticalSpacing * 2)
    }
    
    private func setup() {
        disableThemeObserver = true;
        
        addSubview(internalTextViewScrollView)
        addSubview(toolbarView)
        
        // toolbar
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.disableThemeObserver = true
        
        textViewConstraints.append(toolbarView.topAnchor.constraintEqualToAnchor(topAnchor))
        textViewConstraints.append(toolbarView.leftAnchor.constraintEqualToAnchor(leftAnchor))
        textViewConstraints.append(toolbarView.rightAnchor.constraintEqualToAnchor(rightAnchor))
        toolbarViewHeightConstraint = toolbarView.heightAnchor.constraintEqualToConstant(MarkdownEditorTextView.toolbarHeight)
        textViewConstraints.append(toolbarViewHeightConstraint!)
        
        // text view
        internalTextViewScrollView.borderType = .NoBorder
        internalTextViewScrollView.translatesAutoresizingMaskIntoConstraints = false
        textViewConstraints.append(internalTextViewScrollView.topAnchor.constraintEqualToAnchor(toolbarView.bottomAnchor, constant: MarkdownEditorTextView.verticalSpacing))
        textViewConstraints.append(internalTextViewScrollView.leftAnchor.constraintEqualToAnchor(leftAnchor))
        textViewConstraints.append(internalTextViewScrollView.rightAnchor.constraintEqualToAnchor(rightAnchor))
        textViewConstraints.append(internalTextViewScrollView.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -MarkdownEditorTextView.verticalSpacing))
        
        internalTextView.minSize = NSMakeSize(0, 0)
        internalTextView.maxSize = NSMakeSize(CGFloat.max, CGFloat.max)
        internalTextView.verticallyResizable = true
        internalTextView.horizontallyResizable = false
        internalTextView.autoresizingMask = [.ViewWidthSizable , .ViewHeightSizable]
        internalTextView.textContainer!.widthTracksTextView = true
        internalTextViewScrollView.documentView = internalTextView
        
        
        // bold text
        toolbarView.onBoldButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Bold button on toolbar", customAttributes:nil)
            self?.boldSelectedText()
        }
        internalTextView.onBoldKeyboardShortcut = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Bold keyboard shortcut on toolbar", customAttributes:nil)
            self?.boldSelectedText()
        }
        
        
        toolbarView.onItalicButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Italic button on toolbar", customAttributes:nil)
            self?.italicSelectedText()
        }
        
        toolbarView.onCodeButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Code button on toolbar", customAttributes:nil)
            self?.codeSelectedText()
        }
        
        toolbarView.onQuoteButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Quote button on toolbar", customAttributes:nil)
            self?.quoteSelectedText()
        }
        
        toolbarView.onLinkButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Link button on toolbar", customAttributes:nil)
            self?.linkSelectedText()
        }
        
        toolbarView.onEmojiButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Emoji button on toolbar", customAttributes:nil)
            self?.emojiButtonClick()
        }
        
        toolbarView.onFilePickerButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked File Picker button on toolbar", customAttributes:nil)
            self?.showFilePicker()
        }
        
        toolbarView.onUnorderedListButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Unordered button on toolbar", customAttributes:nil)
            self?.unorderedListButtonClick()
        }
        
        toolbarView.onOrderedListButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Ordered button on toolbar", customAttributes:nil)
            self?.orderedListButtonClick()
        }
        
        toolbarView.onTasklistButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Tasklist button on toolbar", customAttributes:nil)
            self?.taskListButtonClick()
        }
        
        toolbarView.onTextSizeButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked TextSize button on toolbar", customAttributes:nil)
            self?.textSizeButtonClick()
        }
        
        toolbarView.onGifButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked GIF button on toolbar", customAttributes:nil)
            self?.gifButtonClick()
        }
        
        toolbarView.onPreviewButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Preview button on toolbar", customAttributes:nil)
            self?.previewButtonClick()
        }
        
        toolbarView.onHelpButtonClick = { [weak self] in
            Analytics.logCustomEventWithName("Clicked Help button on toolbar", customAttributes:nil)
            self?.helpButtonClick()
        }
        
        collapseToolbar = true
    }
    
    @objc
    private func didClickLargeHeaderButton(sender: AnyObject) {
        prefixSelectedRangeWithString("# ")
        if let textSizePopover = textSizePopover {
            textSizePopover.close()
        }
    }
    
    private func turnPreviewModeOff() {
        if let previewWebView = previewWebView {
            toolbarView.enableAllButton()
            previewWebView.removeFromSuperview()
            self.previewWebView = nil
            internalTextView.hidden = false
            previewWebViewConstraints.removeAll()
            self.makeFirstResponder()
        }
    }
    
    private func previewButtonClick() {
        if  previewWebView != nil {
            turnPreviewModeOff()
        } else {
            internalTextView.hidden = true
            toolbarView.disableAllButton()
            let previewWebView = QIssueMarkdownWebView(HTMLString: MarkdownParser().parse(internalTextView.string, forRepository: nil), onFrameLoadCompletion: { (rect) in
                //rect
                }, scrollingEnabled: true, forceLightMode: forceLightModeForMarkdownPreview)
            
            
            addSubview(previewWebView)
            previewWebView.translatesAutoresizingMaskIntoConstraints = false
            
            let rightConstraint = previewWebView.rightAnchor.constraintEqualToAnchor(rightAnchor, constant: -5)
            let leftConstraint = previewWebView.leftAnchor.constraintEqualToAnchor(leftAnchor, constant:  5)
            let topConstraint = previewWebView.topAnchor.constraintEqualToAnchor(toolbarView.bottomAnchor, constant: MarkdownEditorTextView.verticalSpacing)
            let bottomConstraint = previewWebView.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -MarkdownEditorTextView.verticalSpacing)
            
            
            topConstraint.active = true
            bottomConstraint.active = true
            rightConstraint.active = true
            leftConstraint.active = true
            
            previewWebViewConstraints.append(bottomConstraint)
            previewWebViewConstraints.append(leftConstraint)
            previewWebViewConstraints.append(rightConstraint)
            previewWebViewConstraints.append(topConstraint)
            

            self.previewWebView = previewWebView
            
        }
    }
    
    private func helpButtonClick() {
        if let url = NSURL(string: "https://guides.github.com/features/mastering-markdown/") {
            NSWorkspace.sharedWorkspace().openURL(url)
        }
    }
    
    @objc
    private func didClickSmallHeaderButton(sender: AnyObject) {
        prefixSelectedRangeWithString("### ")
        if let textSizePopover = textSizePopover {
            textSizePopover.close()
        }
    }
    
    @objc
    private func didClickMediumHeaderButton(sender: AnyObject) {
        prefixSelectedRangeWithString("## ")
        if let textSizePopover = textSizePopover {
            textSizePopover.close()
        }
    }
    
    private func textSizeButtonClick() {
        let viewController = BaseViewController()
        let stackView = NSStackView()
        
        viewController.view.addSubview(stackView)
        stackView.pinAnchorsToSuperview()
        stackView.orientation = .Vertical
        stackView.spacing = 0;
        stackView.distribution = .FillEqually
        
        let largeHeaderButton = NSButton()
        largeHeaderButton.font = NSFont.boldSystemFontOfSize(18)
        largeHeaderButton.title = "Header"
        largeHeaderButton.action = #selector(MarkdownEditorTextView.didClickLargeHeaderButton(_:))
        
        let mediumButton = NSButton()
        mediumButton.font = NSFont.boldSystemFontOfSize(16)
        mediumButton.title = "Header"
        mediumButton.action = #selector(MarkdownEditorTextView.didClickMediumHeaderButton(_:))
        
        let smallButton = NSButton()
        smallButton.font = NSFont.boldSystemFontOfSize(14)
        smallButton.title = "Header"
        smallButton.action = #selector(MarkdownEditorTextView.didClickSmallHeaderButton(_:))
        
        [largeHeaderButton, smallButton, mediumButton].forEach { (btn) in
            btn.wantsLayer = true
            btn.bordered = false
            btn.target = self
            //            btn.layer?.borderColor = NSColor.redColor().CGColor
            //            btn.layer?.borderWidth = 1
        }
        
        stackView.addView(largeHeaderButton, inGravity: .Center)
        stackView.addView(mediumButton, inGravity: .Center)
        stackView.addView(smallButton, inGravity: .Center)
        
        let size = NSMakeSize(100, 100)
        let popover = NSPopover()
        
        textSizePopover = popover
        viewController.view.frame = NSMakeRect(0, 0, size.width, size.height);
        
        let foregroundColor: NSColor
        if .Dark == NSUserDefaults.themeMode() {
            let appearance = NSAppearance(named: NSAppearanceNameAqua)
            popover.appearance = appearance;
            foregroundColor = NSColor.whiteColor()
        } else {
            let appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
            popover.appearance = appearance;
            foregroundColor = NSColor.blackColor()
        }
        
        smallButton.appearance = popover.appearance;
        mediumButton.appearance = popover.appearance;
        largeHeaderButton.appearance = popover.appearance;
        
        smallButton.attributedTitle = NSAttributedString(string: "Header", attributes: [NSFontAttributeName: NSFont.boldSystemFontOfSize(16), NSForegroundColorAttributeName: foregroundColor])
        mediumButton.attributedTitle = NSAttributedString(string: "Header", attributes: [NSFontAttributeName: NSFont.boldSystemFontOfSize(18), NSForegroundColorAttributeName: foregroundColor])
        largeHeaderButton.attributedTitle = NSAttributedString(string: "Header", attributes: [NSFontAttributeName: NSFont.boldSystemFontOfSize(20), NSForegroundColorAttributeName: foregroundColor])
        
        popover.delegate = self
        popover.contentSize = size
        popover.contentViewController = viewController
        popover.animates = true
        popover.behavior = .Transient
        popover.showRelativeToRect(toolbarView.textSizeButton.bounds, ofView:toolbarView.textSizeButton, preferredEdge:.MinY);
        
    }
    
    private func gifButtonClick() {
        guard let viewController = GiphyViewController(nibName: "GiphyViewController", bundle: nil) else { return }
        let size = NSMakeSize(320, 480)
        let popover = NSPopover()
        
        viewController.onGifSelection = { [weak self] (gif) in
            guard let strongSelf = self else { return }
            strongSelf.internalTextView.insertText("\n![\(gif.caption ?? "gif")](\(gif.url))", replacementRange: strongSelf.internalTextView.selectedRange())
            strongSelf.giphyPopover?.close()
        }
        
        giphyPopover = popover
        viewController.view.frame = NSMakeRect(0, 0, size.width, size.height);

        let appearance = NSAppearance(named: NSAppearanceNameAqua)
        popover.appearance = appearance;

        popover.delegate = self
        popover.contentSize = size
        popover.contentViewController = viewController
        popover.animates = true
        popover.behavior = .Transient
        popover.showRelativeToRect(toolbarView.gifButton.bounds, ofView:toolbarView.gifButton, preferredEdge:.MinY);
    }
    
    private func unorderedListButtonClick() {
        prefixSelectedRangeWithString("- ")
    }
    

    private func taskListButtonClick() {
        prefixSelectedRangeWithString("- [ ] ")
    }
    
    func boldSelectedText() {
        surroundSelectedRangeWithString("**")
    }
    
    func italicSelectedText() {
        surroundSelectedRangeWithString("*")
    }
    
    private func codeSelectedText() {
        let selectedRange = internalTextView.selectedRange()
        let text = ((internalTextView.string ?? "") as NSString)
        let currentSelectedText = text.substringWithRange(selectedRange)
        if currentSelectedText.containsString("\n") {
            surroundSelectedRangeWithString("\n```\n")
        } else {
            surroundSelectedRangeWithString("`")
        }
    }
    
    private func quoteSelectedText() {
        prefixSelectedRangeWithString("> ")
    }
    
    private func replaceRange(selectedRange: NSRange, withString str: String) {
        let text = (internalTextView.string ?? "") as NSString
        
        if text.length == 0 {
            internalTextView.insertText(str, replacementRange: internalTextView.selectedRange())
        } else if let textStorage = internalTextView.textStorage where internalTextView.shouldChangeTextInRange(selectedRange, replacementString: str) {
            textStorage.beginEditing()
            textStorage.replaceCharactersInRange(selectedRange, withString: str)
            textStorage.endEditing()
            internalTextView.didChangeText()
        }
    }
    
    func linkSelectedText() {
        let selectedRange = internalTextView.selectedRange()
        let currentText = ( (internalTextView.string ?? "") as NSString).substringWithRange(selectedRange)
        let isURL = currentText.isURL()
        let titleString = "title"
        let urlString = "url"
        let linkText = isURL ? "[\(titleString)](\(currentText))" : "[\(currentText)](\(urlString))"
        replaceRange(selectedRange, withString: linkText)
        if isURL || selectedRange.length == 0 {
            let caretRange = NSMakeRange(selectedRange.location + 1, selectedRange.length == 0 ? 0 : titleString.characters.count)
            internalTextView.setSelectedRange(caretRange)
        } else {
            let caretRange = NSMakeRange(selectedRange.location + 3 + currentText.characters.count, urlString.characters.count)
            internalTextView.setSelectedRange(caretRange)
        }
    }
    
    private func emojiButtonClick() {
        makeFirstResponder()
        NSApp.orderFrontCharacterPalette(toolbarView.emojiButton)
    }
    
    private func showFilePicker() {
        let picker = NSOpenPanel()
        picker.canChooseFiles = true
        picker.canChooseDirectories = false
        picker.allowsMultipleSelection = true
        if picker.runModal() == NSFileHandlingPanelOKButton {
            let paths: [String] = picker.URLs.flatMap({ $0.path })
            uploadFilePaths(paths)
        }
    }
    
    private func surroundSelectedRangeWithString(wrapper: String) {
        let selectedRange = internalTextView.selectedRange()
        let text = ((internalTextView.string ?? "") as NSString)
        let currentSelectedText = text.substringWithRange(selectedRange)
        
        let escapedWrapper = wrapper.characters.map({ "\\\($0)" }).joinWithSeparator("")
        let pattern = "^\(escapedWrapper){1}(.*)\(escapedWrapper){1}$"
        var matchedContent: String?
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.CaseInsensitive, .DotMatchesLineSeparators])
            let matches = regex.matchesInString(currentSelectedText, options: .ReportCompletion, range: NSMakeRange(0, currentSelectedText.characters.count))
            for result in matches {
                matchedContent = (currentSelectedText as NSString).substringWithRange(result.rangeAtIndex(1))
                break;
            }
        } catch {
            DDLogDebug("error regex -> \(error)")
        }
        
        if let matchedContent = matchedContent {
            replaceRange(selectedRange, withString: matchedContent)
            let caretRange = NSMakeRange(selectedRange.location, matchedContent.characters.count)
            internalTextView.setSelectedRange(caretRange)
            return;
        }
        
        let wrapperTextCount = wrapper.characters.count
        let adjustedText = "\(wrapper)\(currentSelectedText)\(wrapper)"
        
        if (selectedRange.location - wrapperTextCount) >= 0 && (selectedRange.location + selectedRange.length + wrapperTextCount) <= text.length {
            let potentialWrapperRange = NSMakeRange(selectedRange.location - wrapperTextCount, selectedRange.length + wrapperTextCount * 2)
            let currentSelectedWrapperText = text.substringWithRange(potentialWrapperRange)
            if currentSelectedWrapperText == adjustedText {
                
                replaceRange(potentialWrapperRange, withString: currentSelectedText)
                let caretRange = NSMakeRange(potentialWrapperRange.location, currentSelectedText.characters.count)
                internalTextView.setSelectedRange(caretRange)
                return
            }
        }
        
        replaceRange(selectedRange, withString: adjustedText)
        let caretRange = NSMakeRange(selectedRange.location + wrapperTextCount, currentSelectedText.characters.count)
        internalTextView.setSelectedRange(caretRange)
    }
    
    private func orderedListButtonClick() {
        let selectedRange = internalTextView.selectedRange()
        let text = ((internalTextView.string ?? "") as NSString)
        
        /*
        // get text from beginning of line
        var location = selectedRange.location
        for index in selectedRange.location.stride(through: 0, by: -1) where index >= 0 && index+1 <= text.length {
            if index == 0 {
                location = index
                break
            }
            let character = text.substringWithRange(NSMakeRange(index, 1))
            DDLogDebug("character = \(character)")
            if "\n" == character {
                //location = index
                break
            }
            location = index
        }
        
        selectedRange = NSMakeRange(location, selectedRange.length + (selectedRange.location - location))
 */
        let currentSelectedText = text.substringWithRange(selectedRange)
        
        let originalLines = currentSelectedText.componentsSeparatedByString("\n")
        //let lines = originalLines.map({ ($0 as NSString).trimmedString() })
        let shouldRemovePrefix = originalLines.reduce(0, combine: { $0 + (($1 as String).hasPrefixMatchingRegex("^\\d*?\\.\\s{1}") ? 1 : 0) }) == originalLines.count
        
        let updatedText: String
        var addLineBreakOnFirstLine = false
        if shouldRemovePrefix {
            updatedText = originalLines.flatMap({ ($0 as String).stringByReplaceOccurrencesOfRegex("^\\d*?\\.\\s{1}(.*)", withTemplate: "$1") }).joinWithSeparator("\n")
            replaceRange(selectedRange, withString: updatedText)
        } else {
            addLineBreakOnFirstLine = selectedRange.location != 0 && text.substringWithRange(NSMakeRange(selectedRange.location - 1, 1)) != "\n"
            updatedText = originalLines.enumerate().map({ (index, str) in "\(index == 0 && addLineBreakOnFirstLine ? "\n" : "")\(index+1). \(str)" }).joinWithSeparator("\n")
            replaceRange(selectedRange, withString: updatedText)
        }
        
        internalTextView.setSelectedRange(NSMakeRange(selectedRange.location + (addLineBreakOnFirstLine ? 1 : 0), updatedText.characters.count - (addLineBreakOnFirstLine ? 1 : 0)))
    }
    
    
    private func prefixSelectedRangeWithString(prefix: String) {
        let selectedRange = internalTextView.selectedRange()
        let text = ((internalTextView.string ?? "") as NSString)
        var currentSelectedText = text.substringWithRange(selectedRange)
        
        let escapedPrefix = prefix.characters.map({ "\\\($0)" }).joinWithSeparator("")
        let pattern = "^\(escapedPrefix){1}(.*)$"
        var matchedContent: String?
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
            let matches = regex.matchesInString(currentSelectedText, options: .ReportCompletion, range: NSMakeRange(0, currentSelectedText.characters.count))
            for result in matches {
                matchedContent = (currentSelectedText as NSString).substringWithRange(result.rangeAtIndex(1))
                break;
            }
        } catch {
            DDLogDebug("error regex -> \(error)")
        }
        
        if let matchedContent = matchedContent {
            replaceRange(selectedRange, withString: matchedContent)
            let caretRange = NSMakeRange(selectedRange.location, matchedContent.characters.count)
            internalTextView.setSelectedRange(caretRange)
            return;
        }
        
        let prefixTextCount = prefix.characters.count
        
        let originalLines = currentSelectedText.componentsSeparatedByString("\n")
        let lines = originalLines.map({ ($0 as NSString).trimmedString() })
        let shouldRemovePrefix = lines.reduce(0, combine: { $0 + ($1.hasPrefix(prefix) ? 1 : 0) }) == lines.count
        
        // just to make sure it's not a one liner
        var oneLineRemovePrefix = false
        var oneLineRange = selectedRange
        if !shouldRemovePrefix && lines.count == 1 && (selectedRange.location - prefixTextCount) >= 0 {
            oneLineRange = NSMakeRange(selectedRange.location - prefixTextCount, selectedRange.length + prefixTextCount)
            let oneLineString = text.substringWithRange(oneLineRange)
            if oneLineString == "\(prefix)\(currentSelectedText)" {
                oneLineRemovePrefix = true
                //selectedRange = oneLineRange
                currentSelectedText = oneLineString
            }
        }
        
        var adjustedText = ""
        if oneLineRemovePrefix {
            let index = prefixTextCount as Int
            adjustedText = (currentSelectedText as NSString).substringFromIndex(index)
            
            replaceRange(oneLineRange, withString: adjustedText)
            let caretRange = NSMakeRange(oneLineRange.location, adjustedText.characters.count)
            internalTextView.setSelectedRange(caretRange)
            
        } else if shouldRemovePrefix {
            
            adjustedText = originalLines.map({ (line) -> String in
                if let range = line.rangeOfString(prefix) {
                    return line.stringByReplacingCharactersInRange(range, withString: "")
                }
                return line
            }).joinWithSeparator("\n") //.reduce("", combine: { "\($0)\n\($1)"})
            
            replaceRange(selectedRange, withString: adjustedText)
            let caretRange = originalLines.count <= 1 ? NSMakeRange(selectedRange.location + prefixTextCount, currentSelectedText.characters.count) : NSMakeRange(selectedRange.location, adjustedText.characters.count)
            internalTextView.setSelectedRange(caretRange)
            
        } else {
            
            adjustedText = originalLines.map({ (line) -> String in
                return "\(prefix)\(line)"
            }).joinWithSeparator("\n")  //.reduce("", combine: { "\($0)\n\($1)"})
            
            var didAddLineBreak = false
            for index in selectedRange.location.stride(through: 0, by: -1) where index > 0 && index+1 <= text.length {
                //                guard selectedRange.location == index else { continue }
                let character = text.substringWithRange(NSMakeRange(index, 1))
                //DDLogDebug("character = \(character)")
                if "\n" == character {
                    break
                }
                if ["\t", "\r", " "].contains(character) == false {
                    adjustedText = "\n\(adjustedText)"
                    didAddLineBreak = true
                    break
                }
            }
            
            replaceRange(selectedRange, withString: adjustedText)
            let caretRange = originalLines.count <= 1 ? NSMakeRange(selectedRange.location + prefixTextCount + (didAddLineBreak ? 1 : 0), currentSelectedText.characters.count) : NSMakeRange(selectedRange.location + (didAddLineBreak ? 1 : 0), adjustedText.characters.count)
            internalTextView.setSelectedRange(caretRange)
        }
        
    }
}

extension MarkdownEditorTextView: NSPopoverDelegate {
    
    func popoverDidClose(notification: NSNotification) {
        self.window?.makeFirstResponder(internalTextView)
        self.textSizePopover?.contentViewController = nil
        self.textSizePopover = nil
        self.giphyPopover?.contentViewController = nil
        self.giphyPopover = nil
    }
    
}


@objc(SRInternalMarkdownEditorTextView)
class InternalMarkdownEditorTextView: NSTextView {
    
    var onEnterKeyPressed: dispatch_block_t?
    var onFileUploadChange: dispatch_block_t?
    var onDragEntered: dispatch_block_t?
    var onDragExited: dispatch_block_t?
    var onBoldKeyboardShortcut: dispatch_block_t?
    
    deinit {
        onFileUploadChange = nil
        onDragExited = nil
        onDragEntered = nil
    }
    
    override var string: String? {
        didSet {
            setNeedsDisplayInRect(bounds)
        }
    }
    
    
    
    override var opaque: Bool {
        return false
    }
    
    var hidePlaceholder = false {
        didSet {
            setNeedsDisplayInRect(bounds)
        }
    }
    
    var currentUploadCount: Int {
        var total: Int = 0
        dispatch_sync(self.fileUploadSetAccessQueue, {
            total = self.fileUploadsSet.count
        })
        return total
    }
    
    // private let customUndoManager = NSUndoManager()
    private var dragDropRange: NSRange?
    private var fileUploadsSet = NSMutableSet()
    private let fileUploadSetAccessQueue = dispatch_queue_create("co.cashewapp.markdownUpload", DISPATCH_QUEUE_SERIAL)
    
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        let txtColor = NSColor(calibratedWhite: 174/255.0, alpha: 1)
        let txtDict = [NSForegroundColorAttributeName: txtColor, NSFontAttributeName: NSFont.systemFontOfSize(14)]
        let placeholderString = NSAttributedString(string: "Leave a comment", attributes: txtDict)
        
        let isEmptyField = (string == nil || string == "")
        if !hidePlaceholder && (isEmptyField || (isEmptyField && self != window?.firstResponder && self.selectedRange().length == 0 )) {
            placeholderString.drawAtPoint(CGPoint(x: 5, y: -3))
        }
    }
    
    internal override func becomeFirstResponder() -> Bool {
        setNeedsDisplayInRect(bounds)
        let firstResponder = super.becomeFirstResponder()
        return firstResponder
    }
    
    convenience init() {
        self.init(frame: NSRect.zero)
        setup()
    }
    
    override func awakeFromNib() {
        setup()
    }
    
    func registerDragAndDrop() {
        registerForDraggedTypes([NSFilenamesPboardType])
    }
    
    let fileUploaderService = FileUploaderService()
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        self.window?.makeFirstResponder(self)
        superview?.invalidateIntrinsicContentSize()
        updateDragDropRange(sender)
        if let onDragEntered = onDragEntered {
            onDragEntered()
        }
        return super.draggingEntered(sender)
    }
    
    override func draggingUpdated(sender: NSDraggingInfo) -> NSDragOperation {
        updateDragDropRange(sender)
        return super.draggingEntered(sender)
    }
    
    override func draggingExited(sender: NSDraggingInfo?) {
        updateDragDropRange(sender)
        if let onDragExited = onDragExited {
            onDragExited()
        }
    }
    
    override func draggingEnded(sender: NSDraggingInfo?) {
        updateDragDropRange(sender)
        if let onDragExited = onDragExited {
            onDragExited()
        }
    }
    
    private func updateDragDropRange(sender: NSDraggingInfo?) {
        guard let sender = sender else  { return }
        let mouseLocation = sender.draggingLocation()
        let dropLocation = characterIndexForInsertionAtPoint(convertPoint(mouseLocation, fromView: nil))  //[self characterIndexForInsertionAtPoint:[self convertPoint:mouseLocation fromView:nil]];
        dragDropRange = NSMakeRange(dropLocation, 0)
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        guard editable else { return false }
        
        let pasteboard = sender.draggingPasteboard()
        
        if let types = pasteboard.types where types.contains(NSFilenamesPboardType) {
            if let paths = sender.draggingPasteboard().propertyListForType("NSFilenamesPboardType") as? [String] {
                self.uploadFilePaths(paths)
            }
        } else if let types = pasteboard.types where types.contains(NSStringPboardType) {
            if let types = pasteboard.types where types.contains(NSStringPboardType) {
                if let text = sender.draggingPasteboard().stringForType(NSStringPboardType) as? AnyObject as? String {
                    self.insertText(text, replacementRange: self.selectedRange())
                }
            }
        }
        
        
        return true
    }
    
    override func keyDown(event: NSEvent) {
        //DDLogDebug("key code => \()")
        
        if let onBoldKeyboardShortcut = onBoldKeyboardShortcut where event.keyCode == 11 && event.modifierFlags.contains(NSEventModifierFlags.Command) { // intercept command+b
            onBoldKeyboardShortcut()
            return;
        }
        
        if let onEnterKeyPressed = onEnterKeyPressed where (event.keyCode == 36 || event.keyCode == 76) && event.modifierFlags.contains(NSEventModifierFlags.Command) {
            onEnterKeyPressed()
        }
        
        super.keyDown(event)
    }
    
    override func validateUserInterfaceItem(anItem: NSValidatedUserInterfaceItem) -> Bool {
        let action = anItem.action
        DDLogDebug("NSTextView.action => \(action)")
        return true
    }
    
    private func setup() {
        self.wantsLayer = true
        self.richText = true // needed for pasting images
        self.allowsUndo = true
        self.usesFontPanel = false
        self.usesFindBar = false
        self.usesInspectorBar = false
        self.usesRuler = false
        self.importsGraphics = true
        font = NSFont.systemFontOfSize(14)
        self.typingAttributes = [NSFontNameAttribute: font!]
        //        self.layer?.borderColor = NSColor.orangeColor().CGColor
        //        self.layer?.borderWidth = 1
    }
    
    override func paste(sender: AnyObject?) {
        let pasteboard = NSPasteboard.generalPasteboard()
        let ok = pasteboard.canReadObjectForClasses([NSImage.self], options: nil)
        if (ok) {
            self.dragDropRange = NSMakeRange(selectedRange().location, 0)
            if let objectsToPaste = NSPasteboard.generalPasteboard().readObjectsForClasses([NSImage.self], options: nil) as? [MarkdownTextViewUploadable] {
                uploadFiles(objectsToPaste)
            }
        } else {
            super.pasteAsPlainText(sender)
        }
    }
    
    func uploadFilePaths(paths: [String]) {
        let imagePaths = paths.filter { $0.isImage() || $0.isPDF() || $0.isZIP() || $0.isGZIP() || $0.isText() || $0.isOfficeDocument() }
        
        if let imagePaths = imagePaths as [AnyObject] as? [MarkdownTextViewUploadable] {
            uploadFiles(imagePaths)
        }
    }
    
    private func uploadFiles(paths: [MarkdownTextViewUploadable]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            let group = dispatch_group_create()
            var images = [String]()
            for path in paths {
                
                if let filePath = path as? String {
                    self.addObjectToSet(filePath)
                    dispatch_group_enter(group);
                    self.fileUploaderService.uploadFile(filePath, onCompletion: { (json, context, err) in
                        guard let url = json?["content_url"] as? String else {
                            self.removeObjectFromSet(filePath)
                            Analytics.logCustomEventWithName("failed to upload file", customAttributes: ["uploadType":"drag_n_drop"])
                            dispatch_group_leave(group);
                            return
                        }
                        
                        if let str = path as? String where str.isImage() {
                            let img = "![\((str as NSString).lastPathComponent)](\(url))"
                            images.append(img)
                        } else if let path = path as? NSString {
                            let img = "[\(path.lastPathComponent)](\(url))"
                            images.append(img)
                        } else {
                            let img = "![image](\(url))"
                            images.append(img)
                        }
                        
                        
                        self.removeObjectFromSet(filePath)
                        Analytics.logCustomEventWithName("Successfully uploaded file", customAttributes: ["uploadType":"drag_n_drop"])
                        dispatch_group_leave(group);
                    })
                } else if let image = path as? NSImage {
                    self.addObjectToSet(image)
                    dispatch_group_enter(group);
                    self.fileUploaderService.uploadImage(image, onCompletion: { (json, context, err) in
                        guard let url = json?["content_url"] as? String else {
                            self.removeObjectFromSet(image)
                            Analytics.logCustomEventWithName("failed to upload file", customAttributes: ["uploadType":"image"])
                            dispatch_group_leave(group);
                            return
                        }
                        
                        let img = "![image](\(url))"
                        images.append(img)
                        self.removeObjectFromSet(image)
                        Analytics.logCustomEventWithName("Successfully uploaded file", customAttributes: ["uploadType":"image"])
                        dispatch_group_leave(group);
                    })
                }
            }
            
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
            
            DispatchOnMainQueue {
                if images.count > 0 {
                    
                    let text = "\n\((images as NSArray).componentsJoinedByString("\n\n  "))\n"
                    
                    let replacementRange: NSRange
                    let textLength: Int
                    
                    if let string = self.string {
                        textLength = (string as NSString).length
                    } else {
                        textLength = 0
                    }
                    
                    if let dragDropRange = self.dragDropRange where (dragDropRange.location) <= textLength {
                        replacementRange = dragDropRange
                    } else {
                        replacementRange = NSMakeRange(textLength, 0)
                    }
                    
                    self.insertText( text, replacementRange: replacementRange )
                    self.dragDropRange = nil
                }
            }
        })
    }
    
    private func addObjectToSet(obj: AnyObject) {
        dispatch_sync(self.fileUploadSetAccessQueue, {
            self.fileUploadsSet.addObject(obj)
            dispatch_async(dispatch_get_main_queue(), {
                if let onFileUploadChange = self.onFileUploadChange {
                    onFileUploadChange()
                }
            })
        })
    }
    
    private func removeObjectFromSet(obj: AnyObject) {
        dispatch_sync(self.fileUploadSetAccessQueue, {
            self.fileUploadsSet.removeObject(obj)
            dispatch_async(dispatch_get_main_queue(), {
                if let onFileUploadChange = self.onFileUploadChange {
                    onFileUploadChange()
                }
            })
        })
    }
    
}


@objc
protocol MarkdownTextViewUploadable: NSObjectProtocol { }

extension NSString: MarkdownTextViewUploadable { }
extension NSImage: MarkdownTextViewUploadable { }
