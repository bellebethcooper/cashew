//
//  DarkModeColor.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

//Tomorrow Night
//
//#1d1f21 Background
//#282a2e Current Line
//#373b41 Selection
//#c5c8c6 Foreground
//#969896 Comment
//#cc6666 Red
//#de935f Orange
//#f0c674 Yellow
//#b5bd68 Green
//#8abeb7 Aqua
//#81a2be Blue
//#b294bb Purple

@objc(SRDarkModeColor)
class DarkModeColor: NSObject, ThemeColor {
    
    fileprivate static let bgColor = NSColor(calibratedRed: 29/255.0, green: 31/255.0, blue: 33/255.0, alpha: 1.0)
    fileprivate static let currentLineBgColor = NSColor(calibratedRed: 40/255.0, green: 42/255.0, blue: 46/255.0, alpha: 1.0) //(40,42,46)
    fileprivate static let fgColor = NSColor(calibratedRed: 197/255.0, green: 200/255.0, blue: 198/255.0, alpha: 1.0) // (197,200,198)
    fileprivate static let fgSecondaryColor = NSColor(calibratedRed: 150/255.0, green: 152/255.0, blue: 150/255.0, alpha: 1.0)
    fileprivate static let fgTertiaryColor = NSColor(calibratedWhite: 93/255.0, alpha: 1.0)
    fileprivate static let separatorLineColor =  NSColor(calibratedWhite: 50/255.0, alpha: 1)
    fileprivate static let popoverBgColor = NSColor(calibratedRed: 60/255.0, green: 62/255.0, blue: 65/255.0, alpha: 1.0)
    fileprivate static let aYellowColor = NSColor(calibratedRed: 255/255.0, green: 204/255.0, blue: 102/255.0, alpha: 1)
    
    @objc static let sharedInstance = DarkModeColor()
    
    func backgroundColor() -> NSColor {
        return DarkModeColor.bgColor
    }
    
    func currentLineBackgroundColor() -> NSColor {
        return DarkModeColor.currentLineBgColor
    }
    
    func foregroundColor() -> NSColor {
        return DarkModeColor.fgColor
    }
    
    func foregroundSecondaryColor() -> NSColor {
        return DarkModeColor.fgSecondaryColor
    }
    
    func foregroundTertiaryColor() -> NSColor {
        return DarkModeColor.fgTertiaryColor
    }

    func separatorColor() -> NSColor {
        return DarkModeColor.separatorLineColor
    }
    
    func popoverBackgroundColor() -> NSColor {
        return DarkModeColor.popoverBgColor
    }
    
    func yellowColor() -> NSColor {
        return DarkModeColor.aYellowColor
    }
    
    func sidebarBackgroundColor() -> NSColor {
        return DarkModeColor.bgColor
    }
    
    func selectedBackgroundColor() -> NSColor {
        return DarkModeColor.bgColor
    }
}
