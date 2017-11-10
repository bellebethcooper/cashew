//
//  SearchTokenField.swift
//  SearchField
//
//  Created by Hicham Bouabdallah on 4/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa



extension NSView {
    func takeScreenShot() -> NSImage? {
        return NSImage(data: dataWithPDFInsideRect(bounds))
    }
}

extension NSAttributedString {
    func boundingRectWithWidth(width: CGFloat) -> NSRect {
        return boundingRectWithSize(CGSizeMake(width, CGFloat.max), options: [.UsesFontLeading , .UsesLineFragmentOrigin])
    }
}

class SearchTokenField: NSTextView {
    
    private static let tokenSpacing: CGFloat = 7.0
    
    private var mouseDownCursorRange: NSRange?
    private var mouseDownTextPosition: Int?
    private var shiftPressed = false
    private var mouseIsDown = false
    
    
    
    override var flipped:Bool {
        get {
            return true
        }
    }
    
    override class func defaultMenu() -> NSMenu? {
        let aDefaultMenu = NSTextView.defaultMenu()
        
        guard let defaultMenu = aDefaultMenu else { return nil }
        
        let menu = NSMenu()
        
        defaultMenu.itemArray.forEach { (menuItem) in
            if String(menuItem.action) == "cut:" || String(menuItem.action) == "copy:" || String(menuItem.action) == "paste:" {
                aDefaultMenu?.removeItem(menuItem)
                menu.addItem(menuItem)
            }
        }
        
        return menu
    }
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        NSLog("menuItem \(menuItem.action)")
        
        if String(menuItem.action) == "_lookUpDefiniteRangeInDictionaryFromMenu:" {
            return false
        }
        
        if String(menuItem.action) == "_searchWithGoogleFromMenu:" {
            return false
        }
        
        return true
    }
    
    override func mouseDown(theEvent: NSEvent) {
        mouseIsDown = true
        if shiftPressed == false {
            let point = convertPoint(theEvent.locationInWindow, fromView: nil)
            let minXTextPosition = textPositionAtCGPoint(point, positionX: .MinX)
            let textPosition = textPositionAtCGPoint(point)
            let startRange = NSMakeRange(textPosition, 0)
            let startSelectionRange = NSMakeRange(max(minXTextPosition-1, 0), 1)
            
            self.mouseDownCursorRange = nil
            self.mouseDownTextPosition = nil
            
            guard let textStorage = textStorage else {return }
            
            var didClickToken = false
        
            textStorage.enumerateAttribute(NSAttachmentAttributeName, inRange: startSelectionRange, options: NSAttributedStringEnumerationOptions(rawValue:0)) { (attachmentObject, range, stop) in
                guard let textAttachment = attachmentObject as? NSTextAttachment, _ = textAttachment.attachmentCell as? SearchTokenAttachmentCell  else { return }
                
                let rangeRect = self.rectForRange(range)
//                clickedtokenRect = rangeRect
                let adjustedRect = NSRect(x: rangeRect.minX + 4, y: rangeRect.minY, width: rangeRect.width - 8, height: rangeRect.height)
//                    if NSPointInRect(point, adjustedRect) {
//                        
//                    }
               // NSLog("(\(point)) rangeRect=\(rangeRect) \(NSPointInRect(point, rangeRect)) vs. adjustedRect=\(adjustedRect) \(NSPointInRect(point, adjustedRect))")
                if NSPointInRect(point, adjustedRect) {
                    didClickToken = true
                }
            }
            
            if didClickToken {
                let currentSelectionRange = selectedRange()
                if currentSelectionRange.length == startSelectionRange.length && currentSelectionRange.location == startSelectionRange.location {
                    self.setSelectionIfDiffWithRange(startRange)
                    self.mouseDownCursorRange = startRange
                    
                    // for mouse up comparison
                    self.mouseDownTextPosition = minXTextPosition
                } else {
                    self.setSelectionIfDiffWithRange(startSelectionRange)
                    self.mouseDownCursorRange = startSelectionRange
                    
                    // for mouse up comparison
                    self.mouseDownTextPosition = minXTextPosition
                }
                
            } else {
                self.setSelectionIfDiffWithRange(startRange)
                self.mouseDownCursorRange = startRange
                
                // for mouse up comparison
                self.mouseDownTextPosition = minXTextPosition
            }
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        super.mouseUp(theEvent)
        mouseIsDown = false
        
        if shiftPressed == true {
            handleShiftPressedDuringMouseUpEvent(theEvent)
            
        } else { // if !didDrag {
            self.mouseDownCursorRange = nil
            self.mouseDownTextPosition = nil
        }
    }
    
    
    private func handleShiftPressedDuringMouseUpEvent(theEvent: NSEvent) {
        
        let point = convertPoint(theEvent.locationInWindow, fromView: nil)
        let textPosition = textPositionAtCGPoint(point, forcePointInRectCheck: true)
        
        guard let startRange = mouseDownCursorRange else { return }
        
        let maxPosition = max(startRange.location, startRange.location + startRange.length)
        let minPosition = min(startRange.location, startRange.location + startRange.length)
        
        if textPosition > maxPosition && textPosition > minPosition {
            setSelectionIfDiffWithRange(NSMakeRange(minPosition, textPosition - minPosition))
            
        } else if textPosition < maxPosition && textPosition < minPosition {
            setSelectionIfDiffWithRange(NSMakeRange(textPosition, maxPosition - textPosition))
            
        } else if textPosition > minPosition && textPosition < maxPosition {
            if abs(minPosition - textPosition) < abs(maxPosition - textPosition) {
                setSelectionIfDiffWithRange(NSMakeRange(textPosition, maxPosition - textPosition))
            } else {
                setSelectionIfDiffWithRange(NSMakeRange(minPosition, textPosition - minPosition))
            }
        } else {
            NSLog("maxPosition=\(maxPosition) minPosition=\(minPosition) textPosition=\(textPosition)")
        }
        
        mouseDownCursorRange = selectedRange()
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        guard let startRange = mouseDownCursorRange else { return }
        
        if shiftPressed == true {
            return
        }
        
//        let maxPosition = max(startRange.location, startRange.location + startRange.length)
//        let minPosition = min(startRange.location, startRange.location + startRange.length)
        
        let point = convertPoint(theEvent.locationInWindow, fromView: nil)
        let textPosition = textPositionAtCGPoint(point, forcePointInRectCheck: true)
        
//        if textPosition > maxPosition && textPosition > minPosition {
//            NSLog("RIGHT: NSMakeRange(minPosition=\(minPosition), textPosition=\(textPosition) - minPosition) = \(NSMakeRange(minPosition, textPosition - minPosition))\n---")
//            setSelectionIfDiffWithRange(NSMakeRange(minPosition, textPosition - minPosition))
//            
//        } else if textPosition < maxPosition && textPosition < minPosition {
//            NSLog("LEFT: NSMakeRange(textPosition=\(textPosition), maxPosition=\(maxPosition) - textPosition) = \(NSMakeRange(textPosition, maxPosition - textPosition))\n---")
//            setSelectionIfDiffWithRange(NSMakeRange(textPosition, maxPosition - textPosition))
//            
//        } else if textPosition > minPosition && textPosition < maxPosition {
//            if abs(minPosition - textPosition) < abs(maxPosition - textPosition) {
//                NSLog("INSIDE_LEFT: NSMakeRange(textPosition=\(textPosition), maxPosition=\(maxPosition) - textPosition) = \(NSMakeRange(textPosition, maxPosition - textPosition))\n---")
//                setSelectionIfDiffWithRange(NSMakeRange(textPosition, maxPosition - textPosition))
//            } else {
//                NSLog("INSIDE_RIGHT: NSMakeRange(minPosition=\(minPosition), textPosition=\(textPosition) - minPosition) = \(NSMakeRange(minPosition, textPosition - minPosition))\n---")
//                setSelectionIfDiffWithRange(NSMakeRange(minPosition, textPosition - minPosition))
//            }
//        } else {
//            if minPosition == textPosition {
//                setSelectionIfDiffWithRange(NSMakeRange(minPosition-1, 1))
//            } else if maxPosition == textPosition {
//                setSelectionIfDiffWithRange(NSMakeRange(maxPosition-1, 1))
//            }
//            NSLog("ELSE minPosition=\(minPosition) maxPosition=\(maxPosition) textPosition=\(textPosition) \n---")
//        }
        let selectionRange: NSRange
        /* if startRange.location == textPosition {
         selectionRange = NSMakeRange(textPosition - 1, startRange.location - textPosition + 1)
         } else */ if startRange.location >= textPosition {
            selectionRange = NSMakeRange(textPosition - 1, startRange.location + startRange.length - textPosition + 1)
         } else {
            selectionRange = NSMakeRange(startRange.location, textPosition - startRange.location)
        }
        //NSLog("selectionRange \(selectionRange) startRange=\(startRange) textPosition=\(textPosition)")
        if selectionRange.location >= 0 {
        setSelectionIfDiffWithRange(selectionRange)
        }
    }
    
    override func flagsChanged(theEvent: NSEvent) {
        super.flagsChanged(theEvent)
        
        if theEvent.modifierFlags.contains( NSEventModifierFlags.ShiftKeyMask) {
            mouseDownCursorRange = selectedRange()
            mouseDownTextPosition = selectedRange().location
            shiftPressed = true
        } else {
            shiftPressed = false
            if mouseIsDown == false {
                self.mouseDownCursorRange = nil
                self.mouseDownTextPosition = nil
            }
        }
        
    }
    
    func insertToken(key aKey: String, value: String) {
        guard let textStorage = textStorage else { return }
        
        let tokenView = SearchTokenView(key: aKey, value: value)
        let attachment = NSTextAttachment()
        let attachmentCell = SearchTokenAttachmentCell(tokenView: tokenView)
        
        
        attachment.attachmentCell = attachmentCell
        if let img = attachmentCell.takeScreenshotOfTokenView() {
            attachmentCell.image = img
        }
        textStorage.appendAttributedString(NSAttributedString(attachment: attachment))
    }
    
    override func awakeFromNib() {
        
        font = NSFont.systemFontOfSize(12, weight:  NSFontWeightRegular)
        
        delegate = self
        automaticQuoteSubstitutionEnabled = false
        automaticDashSubstitutionEnabled  = false
        automaticTextReplacementEnabled  = false
        horizontallyResizable = true
        verticallyResizable = false
        usesRolloverButtonForSelection = false
        textContainerInset = NSSize(width: 0, height: 6 )
        
        
        if let textContainer = textContainer {
            textContainer.containerSize = NSMakeSize(CGFloat.max, 30.0)
            
            textContainer.widthTracksTextView = false
            textContainer.heightTracksTextView = false
            textContainer.maximumNumberOfLines = 1
        }

        if let scrollView = enclosingScrollView {
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
            
//            layer?.borderColor = NSColor.redColor().CGColor
//            layer?.borderWidth = 1
//            
//            scrollView.layer?.borderColor = NSColor.greenColor().CGColor
//            scrollView.layer?.borderWidth = 1
            
        }
        

        
        insertToken(key: "FROM", value: "hishboy@gmail.com")
        insertToken(key: "TO", value: "Hicham")
        insertToken(key: "TO", value: "Deanna Ali")
    }
}


extension SearchTokenField: NSTextViewDelegate {
    func textViewDidChangeSelection(notification: NSNotification) {
        //NSLog("selection changed =\(self.selectedRange())")
        updateTokenTextAttachments()
        self.insertionPointColor = NSColor.blackColor()
    }
}

extension SearchTokenField {
    override func writeSelectionToPasteboard(pboard: NSPasteboard, type: String) -> Bool {
        guard let textStorage = textStorage else {
            return super.writeSelectionToPasteboard(pboard, type: type)
        }
        
        let attributedString: NSMutableAttributedString = textStorage.attributedSubstringFromRange(self.selectedRange()).mutableCopy() as AnyObject as! NSMutableAttributedString
        let textLength = attributedString.length
        attributedString.enumerateAttribute(NSAttachmentAttributeName, inRange: NSMakeRange(0, textLength), options: NSAttributedStringEnumerationOptions(rawValue:0)) { (attachmentObject, range, stop) in
            guard let textAttachment = attachmentObject as? NSTextAttachment, textAttachmentCell = textAttachment.attachmentCell as? SearchTokenAttachmentCell  else { return }
            
            attributedString.replaceCharactersInRange(range, withString: " \(textAttachmentCell.pasteboardText)")
        }
        let pasteboard = NSPasteboard.generalPasteboard()
        pasteboard.declareTypes([NSPasteboardTypeString], owner: nil)
        pasteboard.setString(attributedString.string, forType: NSPasteboardTypeString)
        return true
    }
    
    override func readSelectionFromPasteboard(pboard: NSPasteboard) -> Bool {
        return super.readSelectionFromPasteboard(pboard)
    }
    
}

extension SearchTokenField {
    
    enum PositionX {
        case MinX
        case MaxX
        case MidX
    }
    
    
    func setSelectionIfDiffWithRange(selectionRange: NSRange) {
        let currentRange = selectedRange()
        if currentRange.location != selectionRange.location || currentRange.length != selectionRange.length {
            setSelectedRange(selectionRange)
        }
    }
    
    func updateTokenTextAttachments() {
        let selectionRange = self.selectedRange()
        guard let textStorage = textStorage, layoutManager = layoutManager else { return }
        
        textStorage.enumerateAttribute(NSAttachmentAttributeName, inRange: NSMakeRange(0, self.textLength()), options: NSAttributedStringEnumerationOptions(rawValue:0)) { (attachmentObject, range, stop) in
            guard let textAttachment = attachmentObject as? NSTextAttachment, textAttachmentCell = textAttachment.attachmentCell as? SearchTokenAttachmentCell  else { return }
            
            if NSIntersectionRange(range, selectionRange).length > 0 {
                textAttachmentCell.selection = .FullSelection
            } else {
                textAttachmentCell.selection = .NoSelection
            }
            
            textAttachmentCell.image = textAttachmentCell.takeScreenshotOfTokenView()
            layoutManager.invalidateDisplayForGlyphRange(range)
        }
    }
    
    func textPositionAtCGPoint(point: CGPoint, forcePointInRectCheck: Bool = false) -> Int {
        let textLength = self.textLength()
        var position = point.x < 10 ? 0 : (textLength)  //-1
        
        if textLength == 0 {
            return position
        }
        
        for index in 1...textLength {
            let range = NSMakeRange(index-1, 1)
            let rect = rectForRange(range)
            
            var isTextAttachement: Bool = false
            
            if !forcePointInRectCheck {
                attributedString().enumerateAttribute(NSAttachmentAttributeName, inRange: range, options: NSAttributedStringEnumerationOptions(rawValue:0)) { (attachmentObject, range, stop) in
                    
                    guard let textAttachment = attachmentObject as? NSTextAttachment, _ = textAttachment.attachmentCell as? SearchTokenAttachmentCell else { return }
                    isTextAttachement = true
                    stop.memory = true
                }
            }
            
            if !isTextAttachement || forcePointInRectCheck {
                if NSPointInRect(point, rect)  {
                    position = index
                    break
                }
            } else {
                if point.x >= (rect.maxX - SearchTokenField.tokenSpacing * 4) && point.x <= rect.maxX {
                    position = index
                    break
                } else if point.x <= (rect.minX + SearchTokenField.tokenSpacing * 4) && point.x >= rect.minX {
                    position = max(index - 1, 0)
                    break
                } else if NSPointInRect(point, rect)  {
                    position = index
                    break
                }
                
            }
            
        }
        return position
    }
    
    func textPositionAtCGPoint(point: CGPoint, positionX: PositionX) -> Int {
        var position = 0
        let textLength = self.textLength()
        
        if textLength == 0 {
            return position
        }
        
        for index in 1...textLength {
            let range = NSMakeRange(index - 1, 1)
            let rect = rectForRange(range)
            
            let comparisionMinX: CGFloat
            switch positionX {
            case .MinX:
                comparisionMinX = rect.minX
            case .MaxX:
                comparisionMinX = rect.maxX
            case .MidX:
                comparisionMinX = rect.midX
                
            }
            if point.x > comparisionMinX  {
                position = index
            } else {
                break
            }
            
        }
        
        return position
    }
    
    func textLength() -> Int {
        guard let text = string else { return 0 }
        
        let textLength = (text as NSString).length
        return textLength
    }
    
    func rectForRange(range: NSRange) -> NSRect {
        guard let layoutManager = layoutManager, textContainer = textContainer else { return NSRect.zero }
        var rect = layoutManager.boundingRectForGlyphRange(range, inTextContainer: textContainer)
        rect = NSOffsetRect(rect, textContainerOrigin.x, textContainerOrigin.y)
        return rect
    }
}
