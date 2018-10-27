
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
    func willCloseBaseModalWindowController(_ baseModalWindowController: BaseModalWindowController);
}

@IBDesignable class BaseModalWindowController: NSWindowController {
    
    @IBOutlet weak var windowContentView: BaseModalWindowView!
    @IBInspectable var transparentTitleBar: Bool = false
    @IBOutlet weak fileprivate var titleLabel: NSTextField!
    
    var forceAlwaysDarkmode = false
    
    var darkModeOverrideBackgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
    
    var viewController: NSViewController?
    var windowTitle: String?
    var modalSession: NSApplication.ModalSession?
    weak var baseModalWindowControllerDelegate: BaseModalWindowControllerDelegate?
    
    var showZoomButton: Bool = false {
        didSet {
            let zoomButton = self.window?.standardWindowButton(.zoomButton)
            zoomButton?.isHidden = !showZoomButton
            if let window = window {
                if showZoomButton {
                    window.styleMask =  NSWindow.StyleMask(rawValue: window.styleMask.rawValue | NSWindow.StyleMask.resizable.rawValue)
                } else {
                    window.styleMask =  NSWindow.StyleMask(rawValue: window.styleMask.rawValue ^ NSWindow.StyleMask.resizable.rawValue)
                }
            }
        }
    }
    var showMiniaturizeButton = false {
        didSet {
            let miniaturizeButton = self.window?.standardWindowButton(.miniaturizeButton)
            miniaturizeButton?.isHidden = !showMiniaturizeButton
            if let window = window {
                if showMiniaturizeButton {
                    window.styleMask = NSWindow.StyleMask(rawValue: window.styleMask.rawValue | NSWindow.StyleMask.miniaturizable.rawValue)
                } else {
                    window.styleMask = NSWindow.StyleMask(rawValue: window.styleMask.rawValue ^ NSWindow.StyleMask.miniaturizable.rawValue)
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
            
            aViewController.view.leftAnchor.constraint(equalTo: windowContentView.leftAnchor).isActive = true
            aViewController.view.rightAnchor.constraint(equalTo: windowContentView.rightAnchor).isActive = true
            aViewController.view.topAnchor.constraint(equalTo: windowContentView.topAnchor, constant: 25).isActive = true
            aViewController.view.bottomAnchor.constraint(equalTo: windowContentView.bottomAnchor).isActive = true
            
            let zoomButton = self.window?.standardWindowButton(.zoomButton)
            let miniaturizeButton = self.window?.standardWindowButton(.miniaturizeButton)
            
            zoomButton?.isHidden = false
            miniaturizeButton?.isHidden = false
        }
        
        self.titleLabel.stringValue = windowTitle!
        self.titleLabel.drawsBackground = false
        
        if let view = self.window?.contentView as? BaseView {
            view.disableThemeObserver = true
        }
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self, let strongWindow = strongSelf.window, let strongContentView = strongWindow.contentView as? BaseView else {
                return
            }
            
            strongSelf.titleLabel.textColor = CashewColor.foregroundSecondaryColor()

            
            if (.dark == mode || strongSelf.forceAlwaysDarkmode) {
                let appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
                strongWindow.appearance = appearance
                strongContentView.appearance = appearance
                strongContentView.backgroundColor = strongSelf.darkModeOverrideBackgroundColor
            } else {
                let appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
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
            self.modalSession = NSApplication.shared.beginModalSession(for: window) //runModalForWindow(self.window!)
            window.setFrameOrigin(NSPoint(x: windowLeft, y: windowTop))
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        self.baseModalWindowControllerDelegate?.willCloseBaseModalWindowController(self)
        DispatchQueue.main.async {
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
