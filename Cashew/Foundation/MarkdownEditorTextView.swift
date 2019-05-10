//
//  MarkdownEditorTextView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/21/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import os.log

@objc(SRMarkdownEditorTextView)
class MarkdownEditorTextView: BaseView {
    
    // private static let dragBorderColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1)
    
    fileprivate static let toolbarHeight: CGFloat = 26.0
    fileprivate static let verticalSpacing: CGFloat = 8.0
    
    fileprivate let internalTextView = InternalMarkdownEditorTextView()
    fileprivate let internalTextViewScrollView = BaseScrollView()
    fileprivate let toolbarView = MarkdownEditorToolbarView()
    fileprivate var toolbarViewHeightConstraint: NSLayoutConstraint?
    fileprivate var textViewConstraints = [NSLayoutConstraint]()
    fileprivate var previewWebView: QIssueMarkdownWebView?
    fileprivate var previewWebViewConstraints = [NSLayoutConstraint]()
    
    fileprivate(set) var textSizePopover: NSPopover?
    fileprivate(set) var giphyPopover: NSPopover?
    
    
    
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
            internalTextView.string = newValue!
        }
    }
    
    override var backgroundColor: NSColor! {
        didSet {
            internalTextView.backgroundColor = backgroundColor
            toolbarView.backgroundColor = backgroundColor
        }
    }
    
    var isShowingPreview: Bool {
        return internalTextView.isHidden
    }
    
    var isShowingPopover: Bool {
        return self.textSizePopover != nil || self.giphyPopover != nil
    }
    
    var isFirstResponder: Bool {
        return self.window?.firstResponder == internalTextView || self.textSizePopover != nil || self.giphyPopover != nil
    }
    
    @objc var activateTextViewConstraints: Bool = false {
        didSet {
            if activateTextViewConstraints {
                NSLayoutConstraint.activate(textViewConstraints)
                NSLayoutConstraint.activate(previewWebViewConstraints)
            } else {
                NSLayoutConstraint.deactivate(textViewConstraints)
                NSLayoutConstraint.deactivate(previewWebViewConstraints)
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
    
    func isEqualToTextView(_ obj: NSObject) -> Bool {
        return internalTextView == obj
    }
    
    func setAsNextKeyViewForView(_ view: NSView) {
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
    
    
    var onEnterKeyPressed: (()->())? {
        didSet {
            internalTextView.onEnterKeyPressed = onEnterKeyPressed
        }
    }
    
    var onFileUploadChange: (()->())? {
        didSet {
            internalTextView.onFileUploadChange = onFileUploadChange
        }
    }
    
    var onDragEntered: (()->())? {
        didSet {
            internalTextView.onDragEntered = onDragEntered
        }
    }
    
    var onDragExited: (()->())? {
        didSet {
            internalTextView.onDragExited = onDragExited
        }
    }
    
    var editable: Bool {
        get {
            return internalTextView.isEditable
        }
        set {
            internalTextView.isEditable = newValue
        }
    }
    
    var selectable: Bool {
        get {
            return internalTextView.isSelectable
        }
        set {
            internalTextView.isSelectable = newValue
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
                internalTextViewScrollView.backgroundColor = NSColor.white
                backgroundColor = NSColor.white
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
                internalTextViewScrollView.verticalScrollElasticity = .none
                internalTextViewScrollView.horizontalScrollElasticity = .none
            } else {
                internalTextViewScrollView.verticalScrollElasticity = .automatic
                internalTextViewScrollView.horizontalScrollElasticity = .automatic
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
    
    func uploadFilePaths(_ paths: [String]) {
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
    
    func calculatedSizeForWidth(_ containerWidth: CGFloat) -> NSSize {
        let stringVal = (internalTextView.string ?? "RANDOM")
        let font = internalTextView.font!
        let textStorage = NSTextStorage(string: stringVal)
        let textContainer = NSTextContainer(containerSize: CGSize(width: containerWidth, height: CGFloat.greatestFiniteMagnitude) )
        let layoutManager = NSLayoutManager()
        let attributes = [ NSAttributedStringKey.font.rawValue: font ]
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
//        textStorage.addAttributes(attributes, range: NSMakeRange(0, (stringVal as NSString).length))
        
        layoutManager.glyphRange(for: textContainer)
        let size = layoutManager.usedRect(for: textContainer).size
        
        return NSMakeSize(size.width,  size.height + ( collapseToolbar ? 0 : MarkdownEditorTextView.toolbarHeight) + MarkdownEditorTextView.verticalSpacing * 2)
    }
    
    fileprivate func setup() {
        disableThemeObserver = true;
        
        addSubview(internalTextViewScrollView)
        addSubview(toolbarView)
        
        // toolbar
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.disableThemeObserver = true
        
        textViewConstraints.append(toolbarView.topAnchor.constraint(equalTo: topAnchor))
        textViewConstraints.append(toolbarView.leftAnchor.constraint(equalTo: leftAnchor))
        textViewConstraints.append(toolbarView.rightAnchor.constraint(equalTo: rightAnchor))
        toolbarViewHeightConstraint = toolbarView.heightAnchor.constraint(equalToConstant: MarkdownEditorTextView.toolbarHeight)
        textViewConstraints.append(toolbarViewHeightConstraint!)
        
        // text view
        internalTextViewScrollView.borderType = .noBorder
        internalTextViewScrollView.translatesAutoresizingMaskIntoConstraints = false
        textViewConstraints.append(internalTextViewScrollView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor, constant: MarkdownEditorTextView.verticalSpacing))
        textViewConstraints.append(internalTextViewScrollView.leftAnchor.constraint(equalTo: leftAnchor))
        textViewConstraints.append(internalTextViewScrollView.rightAnchor.constraint(equalTo: rightAnchor))
        textViewConstraints.append(internalTextViewScrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -MarkdownEditorTextView.verticalSpacing))
        
        internalTextView.minSize = NSMakeSize(0, 0)
        internalTextView.maxSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
        internalTextView.isVerticallyResizable = true
        internalTextView.isHorizontallyResizable = false
        internalTextView.autoresizingMask = [NSView.AutoresizingMask.width , NSView.AutoresizingMask.height]
        internalTextView.textContainer!.widthTracksTextView = true
        internalTextViewScrollView.documentView = internalTextView
        
        
        // bold text
        toolbarView.onBoldButtonClick = { [weak self] in
            self?.boldSelectedText()
        }
        internalTextView.onBoldKeyboardShortcut = { [weak self] in
            self?.boldSelectedText()
        }
        
        
        toolbarView.onItalicButtonClick = { [weak self] in
            self?.italicSelectedText()
        }
        
        toolbarView.onCodeButtonClick = { [weak self] in
            self?.codeSelectedText()
        }
        
        toolbarView.onQuoteButtonClick = { [weak self] in
            self?.quoteSelectedText()
        }
        
        toolbarView.onLinkButtonClick = { [weak self] in
            self?.linkSelectedText()
        }
        
        toolbarView.onEmojiButtonClick = { [weak self] in
            self?.emojiButtonClick()
        }
        
        toolbarView.onFilePickerButtonClick = { [weak self] in
            self?.showFilePicker()
        }
        
        toolbarView.onUnorderedListButtonClick = { [weak self] in
            self?.unorderedListButtonClick()
        }
        
        toolbarView.onOrderedListButtonClick = { [weak self] in
            self?.orderedListButtonClick()
        }
        
        toolbarView.onTasklistButtonClick = { [weak self] in
            self?.taskListButtonClick()
        }
        
        toolbarView.onTextSizeButtonClick = { [weak self] in
            self?.textSizeButtonClick()
        }
        
        toolbarView.onGifButtonClick = { [weak self] in
            self?.gifButtonClick()
        }
        
        toolbarView.onPreviewButtonClick = { [weak self] in
            self?.previewButtonClick()
        }
        
        toolbarView.onHelpButtonClick = { [weak self] in
            self?.helpButtonClick()
        }
        
        collapseToolbar = true
    }
    
    @objc
    fileprivate func didClickLargeHeaderButton(_ sender: AnyObject) {
        prefixSelectedRangeWithString("# ")
        if let textSizePopover = textSizePopover {
            textSizePopover.close()
        }
    }
    
    fileprivate func turnPreviewModeOff() {
        if let previewWebView = previewWebView {
            toolbarView.enableAllButton()
            previewWebView.removeFromSuperview()
            self.previewWebView = nil
            internalTextView.isHidden = false
            previewWebViewConstraints.removeAll()
            self.makeFirstResponder()
        }
    }
    
    fileprivate func previewButtonClick() {
        if  previewWebView != nil {
            turnPreviewModeOff()
        } else {
            internalTextView.isHidden = true
            toolbarView.disableAllButton()
            let previewWebView = QIssueMarkdownWebView(htmlString: MarkdownParser().parse(internalTextView.string, for: nil), onFrameLoadCompletion: { (rect) in
                //rect
                }, scrollingEnabled: true, forceLightMode: forceLightModeForMarkdownPreview)
            
            addSubview(previewWebView!)
            previewWebView!.translatesAutoresizingMaskIntoConstraints = false
            
            let rightConstraint = previewWebView!.rightAnchor.constraint(equalTo: rightAnchor, constant: -5)
            let leftConstraint = previewWebView!.leftAnchor.constraint(equalTo: leftAnchor, constant:  5)
            let topConstraint = previewWebView!.topAnchor.constraint(equalTo: toolbarView.bottomAnchor, constant: MarkdownEditorTextView.verticalSpacing)
            let bottomConstraint = previewWebView!.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -MarkdownEditorTextView.verticalSpacing)
            
            
            topConstraint.isActive = true
            bottomConstraint.isActive = true
            rightConstraint.isActive = true
            leftConstraint.isActive = true
            
            previewWebViewConstraints.append(bottomConstraint)
            previewWebViewConstraints.append(leftConstraint)
            previewWebViewConstraints.append(rightConstraint)
            previewWebViewConstraints.append(topConstraint)

            self.previewWebView = previewWebView
            
        }
    }
    
    fileprivate func helpButtonClick() {
        if let url = URL(string: "https://guides.github.com/features/mastering-markdown/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc
    fileprivate func didClickSmallHeaderButton(_ sender: AnyObject) {
        prefixSelectedRangeWithString("### ")
        if let textSizePopover = textSizePopover {
            textSizePopover.close()
        }
    }
    
    @objc
    fileprivate func didClickMediumHeaderButton(_ sender: AnyObject) {
        prefixSelectedRangeWithString("## ")
        if let textSizePopover = textSizePopover {
            textSizePopover.close()
        }
    }
    
    fileprivate func textSizeButtonClick() {
        let viewController = BaseViewController()
        let stackView = NSStackView()
        
        viewController.view.addSubview(stackView)
        stackView.pinAnchorsToSuperview()
        stackView.orientation = .vertical
        stackView.spacing = 0;
        stackView.distribution = .fillEqually
        
        let largeHeaderButton = NSButton()
        largeHeaderButton.font = NSFont.boldSystemFont(ofSize: 18)
        largeHeaderButton.title = "Header"
        largeHeaderButton.action = #selector(MarkdownEditorTextView.didClickLargeHeaderButton(_:))
        
        let mediumButton = NSButton()
        mediumButton.font = NSFont.boldSystemFont(ofSize: 16)
        mediumButton.title = "Header"
        mediumButton.action = #selector(MarkdownEditorTextView.didClickMediumHeaderButton(_:))
        
        let smallButton = NSButton()
        smallButton.font = NSFont.boldSystemFont(ofSize: 14)
        smallButton.title = "Header"
        smallButton.action = #selector(MarkdownEditorTextView.didClickSmallHeaderButton(_:))
        
        [largeHeaderButton, smallButton, mediumButton].forEach { (btn) in
            btn.wantsLayer = true
            btn.isBordered = false
            btn.target = self
            //            btn.layer?.borderColor = NSColor.redColor().CGColor
            //            btn.layer?.borderWidth = 1
        }
        
        stackView.addView(largeHeaderButton, in: .center)
        stackView.addView(mediumButton, in: .center)
        stackView.addView(smallButton, in: .center)
        
        let size = NSMakeSize(100, 100)
        let popover = NSPopover()
        
        textSizePopover = popover
        viewController.view.frame = NSMakeRect(0, 0, size.width, size.height);
        
        let foregroundColor: NSColor
        if .dark == UserDefaults.themeMode() {
            let appearance = NSAppearance(named: NSAppearance.Name.aqua)
            popover.appearance = appearance;
            foregroundColor = NSColor.white
        } else {
            let appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
            popover.appearance = appearance;
            foregroundColor = NSColor.black
        }
        
        smallButton.appearance = popover.appearance;
        mediumButton.appearance = popover.appearance;
        largeHeaderButton.appearance = popover.appearance;
        
        smallButton.attributedTitle = NSAttributedString(string: "Header", attributes: [NSAttributedStringKey.font: NSFont.boldSystemFont(ofSize: 16), NSAttributedStringKey.foregroundColor: foregroundColor])
        mediumButton.attributedTitle = NSAttributedString(string: "Header", attributes: [NSAttributedStringKey.font: NSFont.boldSystemFont(ofSize: 18), NSAttributedStringKey.foregroundColor: foregroundColor])
        largeHeaderButton.attributedTitle = NSAttributedString(string: "Header", attributes: [NSAttributedStringKey.font: NSFont.boldSystemFont(ofSize: 20), NSAttributedStringKey.foregroundColor: foregroundColor])
        
        popover.delegate = self
        popover.contentSize = size
        popover.contentViewController = viewController
        popover.animates = true
        popover.behavior = .transient
        popover.show(relativeTo: toolbarView.textSizeButton.bounds, of:toolbarView.textSizeButton, preferredEdge:.minY);
        
    }
    
    fileprivate func gifButtonClick() {
        let viewController = GiphyViewController(nibName: NSNib.Name(rawValue: "GiphyViewController"), bundle: nil)
        let size = NSMakeSize(320, 480)
        let popover = NSPopover()
        
        viewController.onGifSelection = { [weak self] (gif) in
            guard let strongSelf = self else { return }
            strongSelf.internalTextView.insertText("\n![\(gif.caption ?? "gif")](\(gif.url))", replacementRange: strongSelf.internalTextView.selectedRange())
            strongSelf.giphyPopover?.close()
        }
        
        giphyPopover = popover
        viewController.view.frame = NSMakeRect(0, 0, size.width, size.height);

        let appearance = NSAppearance(named: NSAppearance.Name.aqua)
        popover.appearance = appearance;

        popover.delegate = self
        popover.contentSize = size
        popover.contentViewController = viewController
        popover.animates = true
        popover.behavior = .transient
        popover.show(relativeTo: toolbarView.gifButton.bounds, of:toolbarView.gifButton, preferredEdge:.minY);
    }
    
    fileprivate func unorderedListButtonClick() {
        prefixSelectedRangeWithString("- ")
    }
    

    fileprivate func taskListButtonClick() {
        prefixSelectedRangeWithString("- [ ] ")
    }
    
    func boldSelectedText() {
        surroundSelectedRangeWithString("**")
    }
    
    func italicSelectedText() {
        surroundSelectedRangeWithString("*")
    }
    
    fileprivate func codeSelectedText() {
        let selectedRange = internalTextView.selectedRange()
        let text = ((internalTextView.string ?? "") as NSString)
        let currentSelectedText = text.substring(with: selectedRange)
        if currentSelectedText.contains("\n") {
            surroundSelectedRangeWithString("\n```\n")
        } else {
            surroundSelectedRangeWithString("`")
        }
    }
    
    fileprivate func quoteSelectedText() {
        prefixSelectedRangeWithString("> ")
    }
    
    fileprivate func replaceRange(_ selectedRange: NSRange, withString str: String) {
        let text = (internalTextView.string ?? "") as NSString
        
        if text.length == 0 {
            internalTextView.insertText(str, replacementRange: internalTextView.selectedRange())
        } else if let textStorage = internalTextView.textStorage , internalTextView.shouldChangeText(in: selectedRange, replacementString: str) {
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: selectedRange, with: str)
            textStorage.endEditing()
            internalTextView.didChangeText()
        }
    }
    
    func linkSelectedText() {
        let selectedRange = internalTextView.selectedRange()
        let currentText = ( (internalTextView.string ?? "") as NSString).substring(with: selectedRange)
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
    
    fileprivate func emojiButtonClick() {
        makeFirstResponder()
        NSApp.orderFrontCharacterPalette(toolbarView.emojiButton)
    }
    
    fileprivate func showFilePicker() {
        let picker = NSOpenPanel()
        picker.canChooseFiles = true
        picker.canChooseDirectories = false
        picker.allowsMultipleSelection = true
        if picker.runModal().rawValue == NSFileHandlingPanelOKButton {
            let paths: [String] = picker.urls.flatMap({ $0.path })
            uploadFilePaths(paths)
        }
    }
    
    fileprivate func surroundSelectedRangeWithString(_ wrapper: String) {
        let selectedRange = internalTextView.selectedRange()
        let text = ((internalTextView.string ?? "") as NSString)
        let currentSelectedText = text.substring(with: selectedRange)
        
        let escapedWrapper = wrapper.characters.map({ "\\\($0)" }).joined(separator: "")
        let pattern = "^\(escapedWrapper){1}(.*)\(escapedWrapper){1}$"
        var matchedContent: String?
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let matches = regex.matches(in: currentSelectedText, options: .reportCompletion, range: NSMakeRange(0, currentSelectedText.characters.count))
            for result in matches {
                matchedContent = (currentSelectedText as NSString).substring(with: result.range(at: 1))
                break;
            }
        } catch {
            os_log("error regex -> %@", log: .default, type: .debug, error.localizedDescription)
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
            let currentSelectedWrapperText = text.substring(with: potentialWrapperRange)
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
    
    fileprivate func orderedListButtonClick() {
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
        let currentSelectedText = text.substring(with: selectedRange)
        
        let originalLines = currentSelectedText.components(separatedBy: "\n")
        //let lines = originalLines.map({ ($0 as NSString).trimmedString() })
        let shouldRemovePrefix = originalLines.reduce(0, { $0 + (($1 as String).hasPrefixMatchingRegex("^\\d*?\\.\\s{1}") ? 1 : 0) }) == originalLines.count
        
        let updatedText: String
        var addLineBreakOnFirstLine = false
        if shouldRemovePrefix {
            updatedText = originalLines.flatMap({ ($0 as String).stringByReplaceOccurrencesOfRegex("^\\d*?\\.\\s{1}(.*)", withTemplate: "$1") }).joined(separator: "\n")
            replaceRange(selectedRange, withString: updatedText)
        } else {
            addLineBreakOnFirstLine = selectedRange.location != 0 && text.substring(with: NSMakeRange(selectedRange.location - 1, 1)) != "\n"
            updatedText = originalLines.enumerated().map({ (index, str) in "\(index == 0 && addLineBreakOnFirstLine ? "\n" : "")\(index+1). \(str)" }).joined(separator: "\n")
            replaceRange(selectedRange, withString: updatedText)
        }
        
        internalTextView.setSelectedRange(NSMakeRange(selectedRange.location + (addLineBreakOnFirstLine ? 1 : 0), updatedText.characters.count - (addLineBreakOnFirstLine ? 1 : 0)))
    }
    
    
    fileprivate func prefixSelectedRangeWithString(_ prefix: String) {
        let selectedRange = internalTextView.selectedRange()
        let text = ((internalTextView.string ?? "") as NSString)
        var currentSelectedText = text.substring(with: selectedRange)
        
        let escapedPrefix = prefix.characters.map({ "\\\($0)" }).joined(separator: "")
        let pattern = "^\(escapedPrefix){1}(.*)$"
        var matchedContent: String?
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex.matches(in: currentSelectedText, options: .reportCompletion, range: NSMakeRange(0, currentSelectedText.characters.count))
            for result in matches {
                matchedContent = (currentSelectedText as NSString).substring(with: result.range(at: 1))
                break;
            }
        } catch {
            os_log("error regex -> %@", log: .default, type: .debug, error.localizedDescription)
        }
        
        if let matchedContent = matchedContent {
            replaceRange(selectedRange, withString: matchedContent)
            let caretRange = NSMakeRange(selectedRange.location, matchedContent.characters.count)
            internalTextView.setSelectedRange(caretRange)
            return;
        }
        
        let prefixTextCount = prefix.characters.count
        
        let originalLines = currentSelectedText.components(separatedBy: "\n")
        let lines = originalLines.map({ ($0 as NSString).trimmedString() })
        let shouldRemovePrefix = lines.reduce(0, { $0 + ($1.hasPrefix(prefix) ? 1 : 0) }) == lines.count
        
        // just to make sure it's not a one liner
        var oneLineRemovePrefix = false
        var oneLineRange = selectedRange
        if !shouldRemovePrefix && lines.count == 1 && (selectedRange.location - prefixTextCount) >= 0 {
            oneLineRange = NSMakeRange(selectedRange.location - prefixTextCount, selectedRange.length + prefixTextCount)
            let oneLineString = text.substring(with: oneLineRange)
            if oneLineString == "\(prefix)\(currentSelectedText)" {
                oneLineRemovePrefix = true
                //selectedRange = oneLineRange
                currentSelectedText = oneLineString
            }
        }
        
        var adjustedText = ""
        if oneLineRemovePrefix {
            let index = prefixTextCount as Int
            adjustedText = (currentSelectedText as NSString).substring(from: index)
            
            replaceRange(oneLineRange, withString: adjustedText)
            let caretRange = NSMakeRange(oneLineRange.location, adjustedText.characters.count)
            internalTextView.setSelectedRange(caretRange)
            
        } else if shouldRemovePrefix {
            
            adjustedText = originalLines.map({ (line) -> String in
                if let range = line.range(of: prefix) {
                    return line.replacingCharacters(in: range, with: "")
                }
                return line
            }).joined(separator: "\n") //.reduce("", combine: { "\($0)\n\($1)"})
            
            replaceRange(selectedRange, withString: adjustedText)
            let caretRange = originalLines.count <= 1 ? NSMakeRange(selectedRange.location + prefixTextCount, currentSelectedText.characters.count) : NSMakeRange(selectedRange.location, adjustedText.characters.count)
            internalTextView.setSelectedRange(caretRange)
            
        } else {
            
            adjustedText = originalLines.map({ (line) -> String in
                return "\(prefix)\(line)"
            }).joined(separator: "\n")  //.reduce("", combine: { "\($0)\n\($1)"})
            
            var didAddLineBreak = false
            for index in stride(from: selectedRange.location, through: 0, by: -1) where index > 0 && index+1 <= text.length {
                //                guard selectedRange.location == index else { continue }
                let character = text.substring(with: NSMakeRange(index, 1))
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
    
    func popoverDidClose(_ notification: Notification) {
        self.window?.makeFirstResponder(internalTextView)
        self.textSizePopover?.contentViewController = nil
        self.textSizePopover = nil
        self.giphyPopover?.contentViewController = nil
        self.giphyPopover = nil
    }
    
}


@objc(SRInternalMarkdownEditorTextView)
class InternalMarkdownEditorTextView: NSTextView {
    
    var onEnterKeyPressed: (()->())?
    var onFileUploadChange: (()->())?
    var onDragEntered: (()->())?
    var onDragExited: (()->())?
    var onBoldKeyboardShortcut: (()->())?
    
    deinit {
        onFileUploadChange = nil
        onDragExited = nil
        onDragEntered = nil
    }
    
    override var string: String {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    
    
    override var isOpaque: Bool {
        return false
    }
    
    var hidePlaceholder = false {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    var currentUploadCount: Int {
        var total: Int = 0
        self.fileUploadSetAccessQueue.sync(execute: {
            total = self.fileUploadsSet.count
        })
        return total
    }
    
    // private let customUndoManager = NSUndoManager()
    fileprivate var dragDropRange: NSRange?
    fileprivate var fileUploadsSet = NSMutableSet()
    fileprivate let fileUploadSetAccessQueue = DispatchQueue(label: "co.cashewapp.markdownUpload", attributes: [])
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let txtColor = NSColor(calibratedWhite: 174/255.0, alpha: 1)
        let txtDict = [NSAttributedStringKey.foregroundColor: txtColor, NSAttributedStringKey.font: NSFont.systemFont(ofSize: 14)]
        let placeholderString = NSAttributedString(string: "Leave a comment", attributes: txtDict)
        
        let isEmptyField = (string == nil || string == "")
        if !hidePlaceholder && (isEmptyField || (isEmptyField && self != window?.firstResponder && self.selectedRange().length == 0 )) {
            placeholderString.draw(at: CGPoint(x: 5, y: -3))
        }
    }
    
    internal override func becomeFirstResponder() -> Bool {
        setNeedsDisplay(bounds)
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
        if #available(OSX 10.13, *) {
            registerForDraggedTypes([.fileURL])
        } else {
            // Fallback on earlier versions
        }
    }
    
    let fileUploaderService = FileUploaderService()
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.window?.makeFirstResponder(self)
        superview?.invalidateIntrinsicContentSize()
        updateDragDropRange(sender)
        if let onDragEntered = onDragEntered {
            onDragEntered()
        }
        return super.draggingEntered(sender)
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        updateDragDropRange(sender)
        return super.draggingEntered(sender)
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        updateDragDropRange(sender)
        if let onDragExited = onDragExited {
            onDragExited()
        }
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        updateDragDropRange(sender)
        if let onDragExited = onDragExited {
            onDragExited()
        }
    }
    
    fileprivate func updateDragDropRange(_ sender: NSDraggingInfo?) {
        guard let sender = sender else  { return }
        let mouseLocation = sender.draggingLocation()
        let dropLocation = characterIndexForInsertion(at: convert(mouseLocation, from: nil))  //[self characterIndexForInsertionAtPoint:[self convertPoint:mouseLocation fromView:nil]];
        dragDropRange = NSMakeRange(dropLocation, 0)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard isEditable else { return false }
        
        let pasteboard = sender.draggingPasteboard()
        
        if #available(OSX 10.13, *) {
            if let types = pasteboard.types , types.contains(.fileURL) {
                if let paths = sender.draggingPasteboard().propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? [String] {
                    self.uploadFilePaths(paths)
                }
            } else if let types = pasteboard.types , types.contains(.string) {
                if let types = pasteboard.types , types.contains(.string) {
                    if let text = sender.draggingPasteboard().string(forType: .string) as? AnyObject as? String {
                        self.insertText(text, replacementRange: self.selectedRange())
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
        
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        //DDLogDebug("key code => \()")
        
        if let onBoldKeyboardShortcut = onBoldKeyboardShortcut , event.keyCode == 11 && event.modifierFlags.contains(NSEvent.ModifierFlags.command) { // intercept command+b
            onBoldKeyboardShortcut()
            return;
        }
        
        if let onEnterKeyPressed = onEnterKeyPressed , (event.keyCode == 36 || event.keyCode == 76) && event.modifierFlags.contains(NSEvent.ModifierFlags.command) {
            onEnterKeyPressed()
        }
        
        super.keyDown(with: event)
    }
    
    override func validateUserInterfaceItem(_ anItem: NSValidatedUserInterfaceItem) -> Bool {
        let action = anItem.action
        os_log("NSTextView.action => %@", log: .default, type: .debug, String(describing: action))
        return true
    }
    
    fileprivate func setup() {
        self.wantsLayer = true
        self.isRichText = true // needed for pasting images
        self.allowsUndo = true
        self.usesFontPanel = false
        self.usesFindBar = false
        self.usesInspectorBar = false
        self.usesRuler = false
        self.importsGraphics = true
        font = NSFont.systemFont(ofSize: 14)
//        self.typingAttributes = [NSFontDescriptor.AttributeName.name: font!]
        //        self.layer?.borderColor = NSColor.orangeColor().CGColor
        //        self.layer?.borderWidth = 1
    }
    
    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        let ok = pasteboard.canReadObject(forClasses: [NSImage.self], options: nil)
        if (ok) {
            self.dragDropRange = NSMakeRange(selectedRange().location, 0)
            if let objectsToPaste = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil) as? [MarkdownTextViewUploadable] {
                uploadFiles(objectsToPaste)
            }
        } else {
            super.pasteAsPlainText(sender)
        }
    }
    
    func uploadFilePaths(_ paths: [String]) {
        let imagePaths = paths.filter { $0.isImage() || $0.isPDF() || $0.isZIP() || $0.isGZIP() || $0.isText() || $0.isOfficeDocument() }
        
        if let imagePaths = imagePaths as [AnyObject] as? [MarkdownTextViewUploadable] {
            uploadFiles(imagePaths)
        }
    }
    
    fileprivate func uploadFiles(_ paths: [MarkdownTextViewUploadable]) {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async(execute: {
            let group = DispatchGroup()
            var images = [String]()
            for path in paths {
                
                if let filePath = path as? String {
                    self.addObjectToSet(filePath as AnyObject)
                    group.enter();
                    self.fileUploaderService.uploadFile(filePath, onCompletion: { (json, context, err) in
                        guard let json = json as? [String: Any],
                            let url = json["content_url"] as? String else {
                            self.removeObjectFromSet(filePath as AnyObject)
                            group.leave()
                            return
                        }
                        
                        if let str = path as? String , str.isImage() {
                            let img = "![\((str as NSString).lastPathComponent)](\(url))"
                            images.append(img)
                        } else if let path = path as? NSString {
                            let img = "[\(path.lastPathComponent)](\(url))"
                            images.append(img)
                        } else {
                            let img = "![image](\(url))"
                            images.append(img)
                        }
                        
                        
                        self.removeObjectFromSet(filePath as AnyObject)
                        group.leave()
                    })
                } else if let image = path as? NSImage {
                    self.addObjectToSet(image)
                    group.enter();
                    self.fileUploaderService.uploadImage(image, onCompletion: { (json, context, err) in
                        guard let json = json as? [String: Any],
                            let url = json["content_url"] as? String else {
                            self.removeObjectFromSet(image)
                            group.leave()
                            return
                        }
                        
                        let img = "![image](\(url))"
                        images.append(img)
                        self.removeObjectFromSet(image)
                        group.leave()
                    })
                }
            }
            
            group.wait(timeout: DispatchTime.distantFuture)
            
            DispatchOnMainQueue {
                if images.count > 0 {
                    
                    let text = "\n\((images as NSArray).componentsJoined(by: "\n\n  "))\n"
                    
                    let replacementRange: NSRange
                    let textLength: Int
                    
                    
                    textLength = (self.string as NSString).length
                    
                    if let dragDropRange = self.dragDropRange , (dragDropRange.location) <= textLength {
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
    
    fileprivate func addObjectToSet(_ obj: AnyObject) {
        self.fileUploadSetAccessQueue.sync(execute: {
            self.fileUploadsSet.add(obj)
            DispatchQueue.main.async(execute: {
                if let onFileUploadChange = self.onFileUploadChange {
                    onFileUploadChange()
                }
            })
        })
    }
    
    fileprivate func removeObjectFromSet(_ obj: AnyObject) {
        self.fileUploadSetAccessQueue.sync(execute: {
            self.fileUploadsSet.remove(obj)
            DispatchQueue.main.async(execute: {
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
