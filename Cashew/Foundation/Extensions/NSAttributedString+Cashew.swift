//
//  NSAttributedString+Cashew.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


extension NSAttributedString {
    
    @objc
    public func textSize(containerSize aContainerSize: CGSize = CGSizeMake(CGFloat.max, CGFloat.max)) -> NSSize {
        let textStorage = NSTextStorage(attributedString: self)
        let textContainer = NSTextContainer(containerSize: aContainerSize )
        let layoutManager = NSLayoutManager()
        //        let attributes = [ NSFontAttributeName: font ] as [String : AnyObject]?
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        //        textStorage.addAttributes(attributes!, range: NSMakeRange(0, (stringVal as NSString).length))
        
        layoutManager.glyphRangeForTextContainer(textContainer)
        let size = layoutManager.usedRectForTextContainer(textContainer).size
        
        return size
        
//        let newRect = self.boundingRectWithSize(aContainerSize, options: [.UsesFontLeading, .UsesLineFragmentOrigin])
//        return NSSize(width: newRect.width, height: newRect.height)
    }
}