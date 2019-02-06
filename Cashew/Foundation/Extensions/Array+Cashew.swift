//
//  Array+Cashew.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/12/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

extension Array {
    
    func insertionIndexOf(_ elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
    
}

extension Sequence {
    
    func uniqueMap<T>(_ transform: (Self.Iterator.Element) throws -> T) rethrows -> [T] {
        let orderedSet = NSMutableOrderedSet()
        forEach { (element) in
            do {
                let transformed = try transform(element)
                orderedSet.add(transformed)
            } catch {
                //throw e
            }
        }
        return orderedSet.compactMap { (item) -> T? in
            guard let item = item as? T else { return nil }
            return item
        }
    }
}
