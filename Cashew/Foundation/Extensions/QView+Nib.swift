//
//  QView+Nib.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/23/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


public extension QView {
    
    public class func instantiateFromNib<T: QView>(viewType: T.Type) -> T? {
        var viewArray: NSArray?
        let className = NSStringFromClass(viewType).componentsSeparatedByString(".").last! as String

        //DDLogDebug(" viewType = %@", className)
        assert(NSThread.isMainThread())
        NSBundle.mainBundle().loadNibNamed(className, owner: nil, topLevelObjects: &viewArray)
        
        for view in viewArray as! [NSObject] {
            if object_getClass(view) == viewType {
                return view as? T
            }
        }
        
        return nil //viewArray!.objectAtIndex(1) as! T
    }
    
    public class func instantiateFromNib() -> Self? {
        return instantiateFromNib(self)
    }
    
}