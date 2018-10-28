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
    case light
    case dark
}

typealias ThemeBlock = (( ThemeMode) -> () )

private class ThemeObserver: NSObject {
    weak var observer: NSObject?
    let block: ThemeBlock
    
    required init(observer: NSObject, block: @escaping ThemeBlock) {
        self.observer = observer
        self.block = block
        super.init()
    }
}

@objc(SRThemeObserverController)
class ThemeObserverController: NSObject {
    
    @objc static let sharedInstance = ThemeObserverController()
    
    fileprivate let observers = NSMapTable<AnyObject, AnyObject>.weakToStrongObjects() // [NSObject: ThemeBlock]()
    //private let accessQueue = dispatch_queue_create("co.cashewapp.ThemeObserverController.accessQueue", DISPATCH_QUEUE_SERIAL)
    deinit {
        UserDefaults.removeThemeObserver(self)
    }
    
    fileprivate override init() {
        super.init()
        UserDefaults.addThemeObserver(self)
    }
    
    @objc func addThemeObserver(_ observer: NSObject, block: @escaping ThemeBlock) {

        let block = {
            let themeObserver = ThemeObserver(observer: observer, block: block)
            self.observers.setObject(themeObserver, forKey: observer)
            block(UserDefaults.themeMode())
        }
        
        if Thread.isMainThread {
            block();
        } else {
            DispatchQueue.main.sync(execute: block);
        }
        
    }
    
    @objc func removeThemeObserver(_ observer: NSObject) {

        let block = {
            self.observers.removeObject(forKey: observer)
        }
        
        if Thread.isMainThread {
            block();
        } else {
            DispatchQueue.main.sync(execute: block);
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == UserDefaults.ThemeConstant.themeMode {
            var objs = [ThemeObserver]()
            let block: ()->() = {
                self.observers.objectEnumerator()?.forEach({ (value) in
                    
                    guard let observer = value as? ThemeObserver , observer.observer != nil else {
                        return
                    }
                    objs.append(observer)
                })
            }
            
            if Thread.isMainThread {
                block();
            } else {
                DispatchQueue.main.sync(execute: block);
            }
            
            
            let mode = UserDefaults.themeMode()
            
            if (UserDefaults.themeMode() == .dark) {
                Analytics.logCustomEventWithName("Switching to Dark Mode", customAttributes: nil)
            } else {
                Analytics.logCustomEventWithName("Switching to Light Mode", customAttributes: nil)
            }
            
//            var windowSet = Set<NSWindow>()
            objs.forEach ({ (observerContainer) in
                
                if let _ = observerContainer.observer {
                    DispatchQueue.main.async {
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


extension UserDefaults {
    
    struct ThemeConstant {
        static let themeMode = "cashewThemeMode"
    }
    
    class func addThemeObserver(_ observer: NSObject) {
        UserDefaults.standard.addObserver(observer, forKeyPath: UserDefaults.ThemeConstant.themeMode, options: .new, context: nil)
    }
    
    class func removeThemeObserver(_ observer: NSObject) {
        UserDefaults.standard.removeObserver(observer, forKeyPath: UserDefaults.ThemeConstant.themeMode)
    }
    
    class func themeMode() -> ThemeMode {
        let value = UserDefaults.standard.integer(forKey: UserDefaults.ThemeConstant.themeMode)
        return ThemeMode(rawValue: value) ?? ThemeMode.light
    }
    
    class func setThemeMode(_ mode: ThemeMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: UserDefaults.ThemeConstant.themeMode)
        UserDefaults.standard.synchronize()
    }
}
