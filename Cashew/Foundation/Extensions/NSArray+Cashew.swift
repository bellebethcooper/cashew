//
//  NSArray+Cashew.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/16/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation


extension NSArray {

    @objc
    func insertionIndexOf(_ obj: NSObject, comparator: Comparator) -> Int {
        
        let newIndex: Int = index(of: obj, inSortedRange: NSMakeRange(0, self.count), options: .insertionIndex, usingComparator: comparator)
        return newIndex
    }
    
}
