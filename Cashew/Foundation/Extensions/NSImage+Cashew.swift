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
        guard let cgRef = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let newRepo = NSBitmapImageRep(cgImage: cgRef)
        newRepo.size = size
        guard let data = newRepo.representation(using: .png, properties:[NSBitmapImageRep.PropertyKey: AnyObject]()) else {
            return nil
        }
        return data as NSData
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
        let ctx = NSGraphicsContext.current
        ctx?.imageInterpolation = NSImageInterpolation.high
        
        let imageFrame = NSRect(x: 0, y: 0, width: width, height: height)
        let clipPath = NSBezierPath(roundedRect: imageFrame, xRadius: xRad, yRadius: yRad)
        clipPath.windingRule = NSBezierPath.WindingRule.evenOddWindingRule
        clipPath.addClip()
        
        let rect = NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        image.draw(at: NSZeroPoint, from: rect, operation: .sourceOver, fraction: 1)
        composedImage.unlockFocus()
        
        return composedImage
    }
}
