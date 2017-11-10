//
//  ThemeObserverController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/7/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRThemeMode)
enum ThemeMode: NSInteger {
    case Light
    case Dark
}

typealias ThemeBlock = (( ThemeMode) -> () )

private class ThemeObserver: NSObject {
    weak var observer: NSObject?
    let block: ThemeBlock
    
    required init(observer: NSObject, block: ThemeBlock) {
        self.observer = observer
        self.block = block
        super.init()
    }
}

@objc(SRThemeObserverController)
class ThemeObserverController: NSObject {
    
    static let sharedInstance = ThemeObserverController()
    
    private let observers = NSMapTable.weakToStrongObjectsMapTable() // [NSObject: ThemeBlock]()
    //private let accessQueue = dispatch_queue_create("co.cashewapp.ThemeObserverController.accessQueue", DISPATCH_QUEUE_SERIAL)
    deinit {
        NSUserDefaults.removeThemeObserver(self)
    }
    
    private override init() {
        super.init()
        NSUserDefaults.addThemeObserver(self)
    }
    
    func addThemeObserver(observer: NSObject, block: ThemeBlock) {

        let block = {
            let themeObserver = ThemeObserver(observer: observer, block: block)
            self.observers.setObject(themeObserver, forKey: observer)
            block(NSUserDefaults.themeMode())
        }
        
        if NSThread.isMainThread() {
            block();
        } else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
        
    }
    
    func removeThemeObserver(observer: NSObject) {

        let block = {
            self.observers.removeObjectForKey(observer)
        }
        
        if NSThread.isMainThread() {
            block();
        } else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == NSUserDefaults.ThemeConstant.themeMode {
            var objs = [ThemeObserver]()
            let block: dispatch_block_t = {
                self.observers.objectEnumerator()?.forEach({ (value) in
                    
                    guard let observer = value as? ThemeObserver where observer.observer != nil else {
                        return
                    }
                    objs.append(observer)
                })
            }
            
            if NSThread.isMainThread() {
                block();
            } else {
                dispatch_sync(dispatch_get_main_queue(), block);
            }
            
            
            let mode = NSUserDefaults.themeMode()
            
            if (NSUserDefaults.themeMode() == .Dark) {
                Analytics.logCustomEventWithName("Switching to Dark Mode", customAttributes: nil)
            } else {
                Analytics.logCustomEventWithName("Switching to Light Mode", customAttributes: nil)
            }
            
//            var windowSet = Set<NSWindow>()
            objs.forEach ({ (observerContainer) in
                
                if let _ = observerContainer.observer {
                    dispatch_async(dispatch_get_main_queue()) {
                        observerContainer.block(mode)
                    }
//                    if let view = observer as? NSView, window = view.window {
//                        windowSet.insert(window)
//                    } else if let controller = observer as? NSViewController, window = controller.view.window {
//                        windowSet.insert(window)
//                    }
                }
            })
            
//            windowSet.forEach({ (window) in
//                guard let contentView = window.contentView else {
//                    return;
//                }
//                dispatch_async(dispatch_get_main_queue()) {
//                    if mode == .Dark {
//                        window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
//                    } else {
//                        window.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
//                    }
//                    contentView.needsLayout = true
//                    contentView.needsDisplay = true
//                    contentView.layoutSubtreeIfNeeded()
//                }
//            })
            
        }
    }
}


extension NSUserDefaults {
    
    struct ThemeConstant {
        static let themeMode = "cashewThemeMode"
    }
    
    class func addThemeObserver(observer: NSObject) {
        NSUserDefaults.standardUserDefaults().addObserver(observer, forKeyPath: NSUserDefaults.ThemeConstant.themeMode, options: .New, context: nil)
    }
    
    class func removeThemeObserver(observer: NSObject) {
        NSUserDefaults.standardUserDefaults().removeObserver(observer, forKeyPath: NSUserDefaults.ThemeConstant.themeMode)
    }
    
    class func themeMode() -> ThemeMode {
        let value = NSUserDefaults.standardUserDefaults().integerForKey(NSUserDefaults.ThemeConstant.themeMode)
        return ThemeMode(rawValue: value) ?? ThemeMode.Light
    }
    
    class func setThemeMode(mode: ThemeMode) {
        NSUserDefaults.standardUserDefaults().setInteger(mode.rawValue, forKey: NSUserDefaults.ThemeConstant.themeMode)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
