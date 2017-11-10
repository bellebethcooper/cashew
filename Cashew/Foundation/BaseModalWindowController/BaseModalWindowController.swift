
//
//  BaseModalWindowController.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/29/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class BaseModalWindowView: BaseView {
    
}

@objc protocol BaseModalWindowControllerDelegate: class {
    func willCloseBaseModalWindowController(baseModalWindowController: BaseModalWindowController);
}

@IBDesignable class BaseModalWindowController: NSWindowController {
    
    @IBOutlet weak var windowContentView: BaseModalWindowView!
    @IBInspectable var transparentTitleBar: Bool = false
    @IBOutlet weak private var titleLabel: NSTextField!
    
    var forceAlwaysDarkmode = false
    
    var darkModeOverrideBackgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
    
    var viewController: NSViewController?
    var windowTitle: String?
    var modalSession: NSModalSession?
    weak var baseModalWindowControllerDelegate: BaseModalWindowControllerDelegate?
    
    var showZoomButton: Bool = false {
        didSet {
            let zoomButton = self.window?.standardWindowButton(.ZoomButton)
            zoomButton?.hidden = !showZoomButton
            if let window = window {
                if showZoomButton {
                    window.styleMask =  NSWindowStyleMask(rawValue: window.styleMask.rawValue | NSWindowStyleMask.Resizable.rawValue)
                } else {
                    window.styleMask =  NSWindowStyleMask(rawValue: window.styleMask.rawValue ^ NSWindowStyleMask.Resizable.rawValue)
                }
            }
        }
    }
    var showMiniaturizeButton = false {
        didSet {
            let miniaturizeButton = self.window?.standardWindowButton(.MiniaturizeButton)
            miniaturizeButton?.hidden = !showMiniaturizeButton
            if let window = window {
                if showMiniaturizeButton {
                    window.styleMask = NSWindowStyleMask(rawValue: window.styleMask.rawValue | NSWindowStyleMask.Miniaturizable.rawValue)
                } else {
                    window.styleMask = NSWindowStyleMask(rawValue: window.styleMask.rawValue ^ NSWindowStyleMask.Miniaturizable.rawValue)
                }
            }
        }
    }
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.titlebarAppearsTransparent = self.transparentTitleBar
        
        if let aViewController = self.viewController {
            
            self.contentViewController?.addChildViewController(aViewController)

            self.windowContentView.addSubview(aViewController.view)
            aViewController.view.translatesAutoresizingMaskIntoConstraints = false
            
            aViewController.view.leftAnchor.constraintEqualToAnchor(windowContentView.leftAnchor).active = true
            aViewController.view.rightAnchor.constraintEqualToAnchor(windowContentView.rightAnchor).active = true
            aViewController.view.topAnchor.constraintEqualToAnchor(windowContentView.topAnchor, constant: 25).active = true
            aViewController.view.bottomAnchor.constraintEqualToAnchor(windowContentView.bottomAnchor).active = true
            
            let zoomButton = self.window?.standardWindowButton(.ZoomButton)
            let miniaturizeButton = self.window?.standardWindowButton(.MiniaturizeButton)
            
            zoomButton?.hidden = false
            miniaturizeButton?.hidden = false
        }
        
        self.titleLabel.stringValue = windowTitle!
        self.titleLabel.drawsBackground = false
        
        if let view = self.window?.contentView as? BaseView {
            view.disableThemeObserver = true
        }
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self, strongWindow = strongSelf.window, strongContentView = strongWindow.contentView as? BaseView else {
                return
            }
            
            strongSelf.titleLabel.textColor = CashewColor.foregroundSecondaryColor()

            
            if (.Dark == mode || strongSelf.forceAlwaysDarkmode) {
                let appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
                strongWindow.appearance = appearance
                strongContentView.appearance = appearance
                strongContentView.backgroundColor = strongSelf.darkModeOverrideBackgroundColor
            } else {
                let appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
                strongWindow.appearance = appearance
                strongContentView.appearance = appearance
                strongContentView.backgroundColor = CashewColor.backgroundColor()
            }
        }
    }
    
    func presentModalWindow() {
//        self.window!.center()
        if let window = self.window {
            let mainAppWindow = NSApp.windows[0]
            let windowLeft: CGFloat  = mainAppWindow.frame.origin.x + mainAppWindow.frame.size.width/2.0 - window.frame.size.width/2.0
            let windowTop: CGFloat  = mainAppWindow.frame.origin.y + mainAppWindow.frame.size.height/2.0 - window.frame.size.height/2.0
            self.modalSession = NSApplication.sharedApplication().beginModalSessionForWindow(window) //runModalForWindow(self.window!)
            window.setFrameOrigin(NSPoint(x: windowLeft, y: windowTop))
        }
    }
    
    func windowWillClose(notification: NSNotification) {
        self.baseModalWindowControllerDelegate?.willCloseBaseModalWindowController(self)
        dispatch_async(dispatch_get_main_queue()) {
            if let modalSession = self.modalSession {
                NSApp.endModalSession(modalSession)
            }
        }
    }
    
//    static func positionWindowAtCenter(sender: NSWindow?){
//        if let window = sender {
//            let xPos = NSWidth((window.screen?.frame)!)/2 - NSWidth(window.frame)/2
//            let yPos = NSHeight((window.screen?.frame)!)/2 - NSHeight(window.frame)/2
//            let frame = NSMakeRect(xPos, yPos, NSWidth(window.frame), NSHeight(window.frame))
//            window.setFrame(frame, display: true)
//        }
//    }
    
}
