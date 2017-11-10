//
//  NSArray+Cashew.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/16/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation


extension NSArray {
    
    func insertionIndexOf(obj: NSObject, comparator: NSComparator) -> Int {
        
        let newIndex: Int = indexOfObject(obj, inSortedRange: NSMakeRange(0, self.count), options: .InsertionIndex, usingComparator: comparator)
        return newIndex
    }
    
}