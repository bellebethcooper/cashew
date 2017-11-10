//
//  NSDate+Cashew.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/25/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

extension NSDate {
    
    func isCurrentYear() -> Bool {
        
        let dateComponents = NSCalendar.currentCalendar().components([.Year], fromDate: self)
        let todayComponents = NSCalendar.currentCalendar().components([.Year], fromDate: NSDate())
        return dateComponents.year == todayComponents.year
    }
    
    func isAfterDate(date: NSDate) -> Bool {
        return self.compare(date) == .OrderedDescending
    }
    
    func isToday() -> Bool {
        let cal = NSCalendar.currentCalendar()
        var components = cal.components([.Era, .Year, .Month, .Day], fromDate:NSDate())
        let today = cal.dateFromComponents(components)!
        
        components = cal.components([.Era, .Year, .Month, .Day], fromDate:self)
        let otherDate = cal.dateFromComponents(components)!
        
        if(today.isEqualToDate(otherDate)) {
            return true
        } else {
            return false
        }
    }
    
}