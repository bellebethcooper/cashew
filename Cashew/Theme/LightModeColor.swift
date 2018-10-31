//
//  LightModeColor.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

//Tomorrow
//
//#ffffff Background
//#efefef Current Line
//#d6d6d6 Selection
//#4d4d4c Foreground
//#8e908c Comment
//#c82829 Red
//#f5871f Orange
//#eab700 Yellow
//#718c00 Green
//#3e999f Aqua
//#4271ae Blue
//#8959a8 Purple

@objc(SRLightModeColor)
class LightModeColor: NSObject, ThemeColor {
    
    fileprivate static let bgColor = NSColor.white
    fileprivate static let currentLineBgColor = NSColor(calibratedWhite: 220/255.0, alpha: 1.0)
    fileprivate static let fgColor = NSColor(fromHexadecimalValue: "#0f7ff6") ?? NSColor.black // slightly lighter blue I tried: #1d87f7 and lighter again: #2a89fb
    fileprivate static let fgSecondaryColor = NSColor(calibratedRed: 60/255.0, green: 60/255.0, blue: 60/255.0, alpha: 1.0)
    fileprivate static let fgTertiaryColor = NSColor(calibratedWhite: 130/255.0, alpha: 1.0)
    fileprivate static let separatorLineColor = NSColor(calibratedWhite: 220/255.0, alpha: 1.0)
    fileprivate static let aYellowColor = NSColor(calibratedRed: 234/255.0, green: 183/255.0, blue: 0, alpha: 1)
    fileprivate static let sidebarBgColor = NSColor(fromHexadecimalValue: "#f5f9fe") ?? NSColor.white
    fileprivate static let selectedBgColor = NSColor(fromHexadecimalValue: "#ecf6ff") ?? NSColor.white
    
    @objc static let sharedInstance = LightModeColor()
    
    func backgroundColor() -> NSColor {
        return LightModeColor.bgColor
    }
    
    func currentLineBackgroundColor() -> NSColor {
        return LightModeColor.currentLineBgColor
    }
    
    func foregroundColor() -> NSColor {
        return LightModeColor.fgColor
    }
    
    func foregroundSecondaryColor() -> NSColor {
        return LightModeColor.fgSecondaryColor
    }
    
    func foregroundTertiaryColor() -> NSColor {
        return LightModeColor.fgTertiaryColor
    }
    
    func separatorColor() -> NSColor {
        return LightModeColor.separatorLineColor
    }

    func yellowColor() -> NSColor {
        return LightModeColor.aYellowColor
    }
    
    func sidebarBackgroundColor() -> NSColor {
        return LightModeColor.sidebarBgColor
    }
    
    func selectedBackgroundColor() -> NSColor {
        return LightModeColor.selectedBgColor
    }
}
