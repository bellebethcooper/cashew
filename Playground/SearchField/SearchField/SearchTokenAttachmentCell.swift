//
//  SearchTokenAttachmentCell.swift
//  SearchField
//
//  Created by Hicham Bouabdallah on 4/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

enum TokenSelection {
    case FullSelection
    case NoSelection
    case KeySelection
}

class SearchTokenAttachmentCell: NSTextAttachmentCell {
    
    private let tokenView: SearchTokenView
    
    var selection: TokenSelection = .NoSelection {
        didSet {
            tokenView.selection = selection
        }
    }
    
    var keyLabelRect: NSRect {
        get {
            return tokenView.keyLabel.frame
        }
    }
    
    var pasteboardText: String {
        get {
            let keyString = tokenView.keyLabel.stringValue.lowercaseString
            let valueString = tokenView.valueLabel.stringValue
            
            return "\(keyString):\(valueString)"
        }
    }
    
    init(tokenView: SearchTokenView) {
        self.tokenView = tokenView
        super.init(textCell: "")
        
        let layouts = SearchTokenView.calculateLayoustFor(key: tokenView.keyLabel.stringValue, value: tokenView.valueLabel.stringValue)
        let tokenViewRect = NSRect(x: 0, y: 0, width: layouts.valueFrame.maxX, height: layouts.valueFrame.height) //NSUnionRect(layouts.keyFrame, layouts.valueFrame)
        
        tokenView.frame = tokenViewRect
        tokenView.needsLayout = true
        tokenView.layout()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func cellFrameForTextContainer(textContainer: NSTextContainer, proposedLineFragment lineFrag: NSRect, glyphPosition position: NSPoint, characterIndex charIndex: Int) -> NSRect {
        let rect = super.cellFrameForTextContainer(textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        let left: CGFloat = 1.0
        return NSMakeRect(left * 2, -3, rect.width + 4 * left, rect.height)
        
        // TODO: http://petehare.com/inline-nstextattachment-rendering-in-uitextview/
    }
    
    
    func takeScreenshotOfTokenView() -> NSImage? {
        return tokenView.takeScreenShot()
    }
}

class SearchTokenView: NSView {
    
    private static let tokenFont = NSFont.systemFontOfSize(12, weight:  NSFontWeightRegular)
    
    let keyLabel = NSTextField()
    let valueLabel = NSTextField()
    
    override var flipped:Bool {
        get {
            return true
        }
    }
    
    var selection: TokenSelection = .NoSelection {
        didSet {
            let selectionColor = NSColor.redColor() //NSColor(white: 142.0/255.0, alpha: 1)
            
            switch selection {
            case .NoSelection:
                keyLabel.backgroundColor = NSColor.grayColor()
                valueLabel.backgroundColor = NSColor.lightGrayColor()
            case .FullSelection:
                keyLabel.backgroundColor = selectionColor
                valueLabel.backgroundColor = selectionColor
            case .KeySelection:
                keyLabel.backgroundColor = selectionColor
                valueLabel.backgroundColor = NSColor.lightGrayColor()
            }
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    required init(key aKey: String, value: String) {
        super.init(frame: CGRect.zero)
        
        addSubview(keyLabel)
        addSubview(valueLabel)
        
        keyLabel.stringValue = aKey
        valueLabel.stringValue = value
        
        keyLabel.backgroundColor = NSColor.grayColor()
        valueLabel.backgroundColor = NSColor.lightGrayColor()
        
        keyLabel.textColor = NSColor.whiteColor()
        valueLabel.textColor = NSColor.whiteColor()
        
        keyLabel.bordered = false
        valueLabel.bordered = false
        valueLabel.editable = false
        keyLabel.editable = false
        keyLabel.font = SearchTokenView.tokenFont
        valueLabel.font = SearchTokenView.tokenFont
        
    }
    
    override func layout() {
        super.layout()
        let key = keyLabel.stringValue
        let value = valueLabel.stringValue
        
        let layouts = SearchTokenView.calculateLayoustFor(key: key, value: value)
        keyLabel.frame = layouts.keyFrame
        valueLabel.frame = layouts.valueFrame
    }
    
    
    class func calculateLayoustFor(key aKey: String, value: String) -> (keyFrame: NSRect, valueFrame: NSRect) {
        var keyFrame: NSRect = NSRect.zero
        var valueFrame: NSRect = NSRect.zero
        
        let valueTop: CGFloat = 0;//floor(SearchTokenView.tokenFont.ascender - SearchTokenView.tokenFont.capHeight) - 1
        
        // key frame
        let keyAttrText = NSMutableAttributedString(string: aKey)
        keyAttrText.addAttribute(NSFontAttributeName, value: SearchTokenView.tokenFont, range: NSMakeRange(0, keyAttrText.length))
        let keyTextRect = keyAttrText.boundingRectWithWidth(CGFloat.max)
        keyFrame = NSRect(x: 0, y: -valueTop, width: keyTextRect.width + 6, height: keyTextRect.height)
        
        // value frame
        let valueAttrText = NSMutableAttributedString(string: value)
        valueAttrText.addAttribute(NSFontAttributeName, value: SearchTokenView.tokenFont, range: NSMakeRange(0, keyAttrText.length))
        let valueTextRect = valueAttrText.boundingRectWithWidth(CGFloat.max)
        valueFrame = NSRect(x: keyFrame.maxX + 1, y: -valueTop, width: valueTextRect.width + 8, height: valueTextRect.height)
        
        return (keyFrame: keyFrame, valueFrame: valueFrame)
    }
}
