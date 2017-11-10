//
//  IssuesSearchTokenField.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/11/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRIssuesSearchTokenField)
class IssuesSearchTokenField: NSTokenField {
    
    var didBecomeFirstResponderBlock: dispatch_block_t?

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        let txtColor = NSColor(calibratedWhite: 174/255.0, alpha: 1)
        let txtDict = [NSForegroundColorAttributeName: txtColor, NSFontAttributeName: NSFont.systemFontOfSize(13)]
        let placeholderString = NSAttributedString(string: "Search Issues", attributes: txtDict)
        
        let isEmptyField = (stringValue == "")
        if isEmptyField || (isEmptyField && self != window?.firstResponder) {
            placeholderString.drawAtPoint(CGPoint(x: 5, y: 0))
        }
    }
    
    override var stringValue: String {
        didSet {
            self.toolTip = stringValue.componentsSeparatedByString(",").joinWithSeparator(" ")
        }
    }
    
    override var objectValue: AnyObject? {
        didSet {
            self.toolTip = stringValue.componentsSeparatedByString(",").joinWithSeparator(" ")
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        if let didBecomeFirstResponderBlock = didBecomeFirstResponderBlock {
            didBecomeFirstResponderBlock()
        }
        let isFirstResponder = super.becomeFirstResponder()
        return isFirstResponder
    }
    
}

//- (void)setStringValue:(NSString *)stringValue
//{
//    [super setStringValue:stringValue];
//    self.toolTip = [[self.stringValue componentsSeparatedByString:@","] componentsJoinedByString:@" "];
//    }
//    
//    - (void)setObjectValue:(id)objectValue
//{
//    [super setObjectValue:objectValue];
//    self.toolTip = [[self.stringValue componentsSeparatedByString:@","] componentsJoinedByString:@" "];
//    }
//    
//    - (BOOL)becomeFirstResponder
//        {
//            BOOL isFirstResponder = [super becomeFirstResponder];
//            dispatch_block_t didBecomeFirstResponderBlock = self.didBecomeFirstResponderBlock;
//            if (isFirstResponder && didBecomeFirstResponderBlock) {
//                didBecomeFirstResponderBlock();
//            }
//            return isFirstResponder;
//}
