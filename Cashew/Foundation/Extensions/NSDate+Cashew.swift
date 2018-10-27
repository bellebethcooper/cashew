//
//  NSDate+Cashew.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/25/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

extension NSDate {
    @objc func isAfterDate(_ date: Date) -> Bool {
        return self.compare(date) == .orderedDescending
    }
}

extension Date {
    
    func isCurrentYear() -> Bool {
        
        let dateComponents = (Calendar.current as NSCalendar).components([.year], from: self)
        let todayComponents = (Calendar.current as NSCalendar).components([.year], from: Date())
        return dateComponents.year == todayComponents.year
    }
    
    func isAfterDate(_ date: Date) -> Bool {
        return self.compare(date) == .orderedDescending
    }
    
    func isToday() -> Bool {
        let cal = Calendar.current
        var components = (cal as NSCalendar).components([.era, .year, .month, .day], from:Date())
        let today = cal.date(from: components)!
        
        components = (cal as NSCalendar).components([.era, .year, .month, .day], from:self)
        let otherDate = cal.date(from: components)!
        
        if(today == otherDate) {
            return true
        } else {
            return false
        }
    }
    
}
