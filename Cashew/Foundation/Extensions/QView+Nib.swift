//
//  QView+Nib.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/23/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


public extension QView {
    
    class func instantiateFromNib<T: QView>(_ viewType: T.Type) -> T? {
        var viewArray: NSArray?
        let className = NSStringFromClass(viewType).components(separatedBy: ".").last! as String

        //DDLogDebug(" viewType = %@", className)
        assert(Thread.isMainThread)
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: className), owner: nil, topLevelObjects: &viewArray)
        
        for view in viewArray as! [NSObject] {
            if object_getClass(view) == viewType {
                return view as? T
            }
        }
        
        return nil //viewArray!.objectAtIndex(1) as! T
    }
    
    class func instantiateFromNib() -> Self? {
        return instantiateFromNib(self)
    }
    
}
