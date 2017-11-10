//
//  ThemeColor.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation

private struct ThemeColorConstant {
    // static let yellowColor = NSColor(fromHexadecimalValue: "#b58900")
    static let orangeColor = NSColor(fromHexadecimalValue: "#cb4b16")
    static let redColor = NSColor(fromHexadecimalValue: "#dc322f")
    static let magentaColor = NSColor(fromHexadecimalValue: "#d33682")
    static let violetColor = NSColor(fromHexadecimalValue: "#6c71c4")
    static let blueColor = NSColor(fromHexadecimalValue: "#268bd2")
    static let cyanColor = NSColor(fromHexadecimalValue: "#2aa198")
    static let greenColor = NSColor(fromHexadecimalValue: "#859900")
    
    static let lightForegroundColor = NSColor(fromHexadecimalValue: "#839496")
    static let lighterForegroundColor = NSColor(fromHexadecimalValue: "#93a1a1")
    static let darkForegroundColor = NSColor(calibratedWhite: 65/255.0, alpha: 1.0) //NSColor(fromHexadecimalValue: "#657b83")
    static let darkerForegroundColor =   NSColor(calibratedWhite: 60/255.0, alpha: 1.0) // NSColor(fromHexadecimalValue: "#586e75")
    
    static let notificationDotColor = NSColor(calibratedRed: 251/255.0, green: 73/255.0, blue: 71/255.0, alpha: 1)
}

@objc(SRCashewColor)
class CashewColor: NSObject {
    
    class func notificationDotColor() -> NSColor {
        return ThemeColorConstant.notificationDotColor
    }

    class func separatorColor() -> NSColor {
        let mode = NSUserDefaults.themeMode()
        if mode == .Light {
            return LightModeColor.sharedInstance.separatorColor()
        } else if mode == .Dark {
            return DarkModeColor.sharedInstance.separatorColor()
        }
        fatalError()
    }
    
    class func currentLineBackgroundColor() -> NSColor {
        let mode = NSUserDefaults.themeMode()
        if mode == .Light {
            return LightModeColor.sharedInstance.currentLineBackgroundColor()
        } else if mode == .Dark {
            return DarkModeColor.sharedInstance.currentLineBackgroundColor()
        }
        fatalError()
    }
    
    class func backgroundColor() -> NSColor {
        let mode = NSUserDefaults.themeMode()
        if mode == .Light {
            return LightModeColor.sharedInstance.backgroundColor()
        } else if mode == .Dark {
            return DarkModeColor.sharedInstance.backgroundColor()
        }
        fatalError()
    }
    
    class func foregroundColor() -> NSColor {
        let mode = NSUserDefaults.themeMode()
        if mode == .Light {
            return LightModeColor.sharedInstance.foregroundColor()
        } else if mode == .Dark {
            return DarkModeColor.sharedInstance.foregroundColor()
        }
        fatalError()
    }
    
    class func foregroundSecondaryColor() -> NSColor {
        let mode = NSUserDefaults.themeMode()
        if mode == .Light {
            return LightModeColor.sharedInstance.foregroundSecondaryColor()
        } else if mode == .Dark {
            return DarkModeColor.sharedInstance.foregroundSecondaryColor()
        }
        fatalError()
    }
    
    class func yellowColor() -> NSColor {
        let mode = NSUserDefaults.themeMode()
        if mode == .Light {
            return LightModeColor.sharedInstance.yellowColor()
        } else if mode == .Dark {
            return DarkModeColor.sharedInstance.yellowColor()
        }
        fatalError()
    }
    
    class func orangeColor() -> NSColor {
        return ThemeColorConstant.orangeColor
    }
    
    class func redColor() -> NSColor {
        return ThemeColorConstant.redColor
    }
    
    class func magentaColor() -> NSColor {
        return ThemeColorConstant.magentaColor
    }
    
    class func violetColor() -> NSColor {
        return ThemeColorConstant.violetColor
    }
    
    class func blueColor() -> NSColor {
        return ThemeColorConstant.blueColor
    }
    
    class func cyanColor() -> NSColor {
        return ThemeColorConstant.cyanColor
    }
    
    class func greenColor() -> NSColor {
        return ThemeColorConstant.greenColor
    }
    
    class func sidebarBackgroundColor() -> NSColor {
        let mode = NSUserDefaults.themeMode()
        if mode == .Light {
            return LightModeColor.sharedInstance.sidebarBackgroundColor()
        } else if mode == .Dark {
            return DarkModeColor.sharedInstance.sidebarBackgroundColor()
        }
        fatalError()
    }
    
}

@objc(SRThemeColor)
protocol ThemeColor: NSObjectProtocol {

    func backgroundColor() -> NSColor
    func currentLineBackgroundColor() -> NSColor
    func foregroundColor() -> NSColor
    func foregroundSecondaryColor() -> NSColor
    func foregroundTertiaryColor() -> NSColor
    func separatorColor() -> NSColor
    func sidebarBackgroundColor() -> NSColor
    
    func yellowColor() -> NSColor
}

//
//Tomorrow Night
//
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
//
//Tomorrow
//
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
//
//Tomorrow Night Eighties
//
//Tomorrow Night Eighties
//
//#2d2d2d Background
//#393939 Current Line
//#515151 Selection
//#cccccc Foreground
//#999999 Comment
//#f2777a Red
//#f99157 Orange
//#ffcc66 Yellow
//#99cc99 Green
//#66cccc Aqua
//#6699cc Blue
//#cc99cc Purple
//
//Tomorrow Night Blue
//
//Tomorrow Night Blue
//
//#002451 Background
//#00346e Current Line
//#003f8e Selection
//#ffffff Foreground
//#7285b7 Comment
//#ff9da4 Red
//#ffc58f Orange
//#ffeead Yellow
//#d1f1a9 Green
//#99ffff Aqua
//#bbdaff Blue
//#ebbbff Purple
//
//Tomorrow Night Bright
//
//Tomorrow Night Bright
//
//#000000 Background
//#2a2a2a Current Line
//#424242 Selection
//#eaeaea Foreground
//#969896 Comment
//#d54e53 Red
//#e78c45 Orange
//#e7c547 Yellow
//#b9ca4a Green
//#70c0b1 Aqua
//#7aa6da Blue
//#c397d8 Purple
