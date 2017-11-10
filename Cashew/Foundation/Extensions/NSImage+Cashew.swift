//
//  NSImage+Cashew.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/22/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

extension NSImage {
    
    var imagePNGRepresentation: NSData? {
        guard let cgRef = CGImageForProposedRect(nil, context: nil, hints: nil) else {
            return nil
        }
        
        let newRepo = NSBitmapImageRep(CGImage: cgRef)
        newRepo.size = size
        guard let data = newRepo.representationUsingType(.PNG, properties:[String: AnyObject]()) else {
            return nil
        }
        return data
    }
    
    func circularImage() -> NSImage {
        let image = self;
        let width: CGFloat = size.width
        let height: CGFloat = size.height
        let xRad = width / 2
        let yRad = height / 2
        let existing = image
        let esize = existing.size
        let newSize = NSMakeSize(esize.width, esize.height)
        let composedImage = NSImage(size: newSize)
        
        composedImage.lockFocus()
        let ctx = NSGraphicsContext.currentContext()
        ctx?.imageInterpolation = NSImageInterpolation.High
        
        let imageFrame = NSRect(x: 0, y: 0, width: width, height: height)
        let clipPath = NSBezierPath(roundedRect: imageFrame, xRadius: xRad, yRadius: yRad)
        clipPath.windingRule = NSWindingRule.EvenOddWindingRule
        clipPath.addClip()
        
        let rect = NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        image.drawAtPoint(NSZeroPoint, fromRect: rect, operation: .SourceOver, fraction: 1)
        composedImage.unlockFocus()
        
        return composedImage
    }
}
