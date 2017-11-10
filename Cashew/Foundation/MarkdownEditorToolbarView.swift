//
//  MarkdownEditorToolbarView.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/27/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRMarkdownEditorToolbarView)
class MarkdownEditorToolbarView: BaseView {
    
    private static let iconEdge: CGFloat = 16
    private static let horizontalPadding: CGFloat = 4
    
    let tasklistButton = NSButton()
    let orderedListButton = NSButton()
    let unorderedListButton = NSButton()
    let linkButton = NSButton()
    let codeButton = NSButton()
    let quoteButton = NSButton()
    let italicButton = NSButton()
    let boldButton = NSButton()
    let textSizeButton = NSButton()
    let filePickerButton = NSButton()
    let gifButton = NSButton()
    let emojiButton = NSButton()
    let previewButton = NSButton()
    let helpButton = NSButton()
    let separatorView = BaseSeparatorView()
    
    var onTasklistButtonClick: dispatch_block_t?
    var onOrderedListButtonClick: dispatch_block_t?
    var onUnorderedListButtonClick: dispatch_block_t?
    var onLinkButtonClick: dispatch_block_t?
    var onCodeButtonClick: dispatch_block_t?
    var onQuoteButtonClick: dispatch_block_t?
    var onItalicButtonClick: dispatch_block_t?
    var onBoldButtonClick: dispatch_block_t?
    var onTextSizeButtonClick: dispatch_block_t?
    var onFilePickerButtonClick: dispatch_block_t?
    var onGifButtonClick: dispatch_block_t?
    var onEmojiButtonClick: dispatch_block_t?
    var onPreviewButtonClick: dispatch_block_t?
    var onHelpButtonClick: dispatch_block_t?
    
    private var buttonsConstraints = [NSLayoutConstraint]()
    
    required init() {
        super.init(frame: NSRect.zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func allButtons() -> [NSButton] {
        return [ textSizeButton, boldButton, italicButton, quoteButton, codeButton, linkButton, unorderedListButton, orderedListButton, tasklistButton, filePickerButton, gifButton, emojiButton, helpButton, previewButton ]
    }
    
    func disableAllButton() {
        allButtons().forEach { (btn) in
            if btn != previewButton {
                btn.enabled = false
            }
        }
    }
    
    func enableAllButton() {
        allButtons().forEach { (btn) in
            if btn != previewButton {
                btn.enabled = true
            }
        }
    }
    
    
    @objc
    private func didClickToolbarButton(sender: NSButton) {
        
        switch sender {
        case tasklistButton:
            if let onTasklistButtonClick = onTasklistButtonClick {
                onTasklistButtonClick()
            }
        case orderedListButton:
            if let onOrderedListButtonClick = onOrderedListButtonClick {
                onOrderedListButtonClick()
            }
        case unorderedListButton:
            if let onUnorderedListButtonClick = onUnorderedListButtonClick {
                onUnorderedListButtonClick()
            }
        case linkButton:
            if let onLinkButtonClick = onLinkButtonClick {
                onLinkButtonClick()
            }
        case codeButton:
            if let onCodeButtonClick = onCodeButtonClick {
                onCodeButtonClick()
            }
        case quoteButton:
            if let onQuoteButtonClick = onQuoteButtonClick {
                onQuoteButtonClick()
            }
        case italicButton:
            if let onItalicButtonClick = onItalicButtonClick {
                onItalicButtonClick()
            }
        case boldButton:
            if let onBoldButtonClick = onBoldButtonClick {
                onBoldButtonClick()
            }
        case textSizeButton:
            if let onTextSizeButtonClick = onTextSizeButtonClick {
                onTextSizeButtonClick()
            }
        case filePickerButton:
            if let onFilePickerButtonClick = onFilePickerButtonClick {
                onFilePickerButtonClick()
            }
        case gifButton:
            if let onGifButtonClick = onGifButtonClick {
                onGifButtonClick()
            }
        case emojiButton:
            if let onEmojiButtonClick = onEmojiButtonClick {
                onEmojiButtonClick()
            }
            
        case previewButton:
            if let onPreviewButtonClick = onPreviewButtonClick {
                onPreviewButtonClick()
            }
            
        case helpButton:
            if let onHelpButtonClick = onHelpButtonClick {
                onHelpButtonClick()
            }
            
        default:
            break
        }
        
    }
    
    private func setup() {
        var previousView: NSView = self
        for (i, button) in allButtons().enumerate() {
            addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            buttonsConstraints.append(button.heightAnchor.constraintEqualToConstant(MarkdownEditorToolbarView.iconEdge))
            
            buttonsConstraints.append(button.widthAnchor.constraintEqualToConstant(MarkdownEditorToolbarView.iconEdge))
            buttonsConstraints.append(button.centerYAnchor.constraintEqualToAnchor(centerYAnchor))
            
            let anchor = previousView == self ? leftAnchor : previousView.rightAnchor
            buttonsConstraints.append(button.leftAnchor.constraintEqualToAnchor(anchor, constant: i != 0 && i % 3 == 0 ? 16 : MarkdownEditorToolbarView.horizontalPadding))
            button.action = #selector(MarkdownEditorToolbarView.didClickToolbarButton(_:))
            button.target = self
            
            
            previousView = button
            button.bordered = false;
            button.wantsLayer = true
            if let buttonCell = button.cell as? NSButtonCell {
                buttonCell.imageScaling = .ScaleProportionallyDown;
            }
        }
        
//        addSubview(previewButton)
//        //previewButton.hidden = true
//        previewButton.translatesAutoresizingMaskIntoConstraints = false
//        previewButton.target = self
//        previewButton.action = #selector(MarkdownEditorToolbarView.didClickToolbarButton(_:))
//        previewButton.bordered = false
//        previewButton.wantsLayer = true
//        if let buttonCell = previewButton.cell as? NSButtonCell {
//            buttonCell.imageScaling = .ScaleProportionallyDown;
//        }
        
//        buttonsConstraints.append(previewButton.heightAnchor.constraintEqualToConstant(MarkdownEditorToolbarView.iconEdge))
//        buttonsConstraints.append(previewButton.widthAnchor.constraintEqualToConstant(MarkdownEditorToolbarView.iconEdge))
//        buttonsConstraints.append(previewButton.centerYAnchor.constraintEqualToAnchor(centerYAnchor))
//        buttonsConstraints.append(previewButton.rightAnchor.constraintEqualToAnchor(rightAnchor, constant: -MarkdownEditorToolbarView.horizontalPadding * 2))
//        buttonsConstraints.append(previewButton.leftAnchor.constraintGreaterThanOrEqualToAnchor(previousView.rightAnchor, constant: 16))
        
        let color = LightModeColor.sharedInstance.foregroundSecondaryColor()
        tasklistButton.image = NSImage(named: "tasklist")?.imageWithTintColor(color)
        tasklistButton.toolTip = "Add task list"
        orderedListButton.image = NSImage(named: "list-ordered")?.imageWithTintColor(color)
        orderedListButton.toolTip = "Add a numbered list"
        unorderedListButton.image = NSImage(named: "list-unordered")?.imageWithTintColor(color)
        unorderedListButton.toolTip = "Add a bulleted list"
        linkButton.image = NSImage(named: "link")?.imageWithTintColor(color)
        linkButton.toolTip = "Add a link <cmd+k>"
        codeButton.image = NSImage(named: "code")?.imageWithTintColor(color)
        codeButton.toolTip = "Insert code"
        quoteButton.image = NSImage(named: "quote")?.imageWithTintColor(color)
        quoteButton.toolTip = "Insert a quote"
        italicButton.image = NSImage(named: "italic")?.imageWithTintColor(color)
        italicButton.toolTip = "Add italic text <cmd+i>"
        boldButton.image = NSImage(named: "bold")?.imageWithTintColor(color)
        boldButton.toolTip = "Add bold text <cmd+b>"
        textSizeButton.image = NSImage(named: "text-size")!.imageWithTintColor(color)
        textSizeButton.toolTip = "Add header text"
        filePickerButton.image = NSImage(named: "add-file")!.imageWithTintColor(color)
        filePickerButton.toolTip = "Select file to upload"
        gifButton.image = NSImage(named: "giphy")! //.imageWithTintColor(color)
        gifButton.toolTip = "Insert GIF"
        emojiButton.image = NSImage(named: "emoji")!.imageWithTintColor(color) //.imageWithTintColor(color)
        emojiButton.toolTip = "Insert emoji"
        previewButton.image = NSImage(named: "preview")?.imageWithTintColor(color)
        previewButton.toolTip = "Preview"
        helpButton.image = NSImage(named: "help")?.imageWithTintColor(color)
        helpButton.toolTip = "Markdown tutorial"
        
        
        //        addSubview(separatorView)
        //        separatorView.translatesAutoresizingMaskIntoConstraints = false
        //        separatorView.leftAnchor.constraintEqualToAnchor(leftAnchor).active = true
        //        separatorView.rightAnchor.constraintEqualToAnchor(rightAnchor).active = true
        //        separatorView.heightAnchor.constraintEqualToConstant(1).active = true
        //        separatorView.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        //        separatorView.disableThemeObserver = true
        //        separatorView.backgroundColor = LightModeColor.sharedInstance.separatorColor()
    }
    
    var collapse: Bool = false {
        didSet {
            if collapse {
                NSLayoutConstraint.deactivateConstraints(buttonsConstraints)
            } else {
                NSLayoutConstraint.activateConstraints(buttonsConstraints)
            }
        }
    }
    
}
