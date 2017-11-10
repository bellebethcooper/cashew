//
//  NewIssueWindowController.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 2/29/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class NewIssueWindowController: NSWindowController {
    
    @objc
    private(set) lazy var newIssueViewController: NewIssueViewController = {
        return NewIssueViewController()
    }()
    
    var request: CreateIssueRequest? {
        didSet {
            self.newIssueViewController.request = request
        }
    }
    
    var onWillCloseWindow: ( ()-> Void)?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // setup new issue view controller
        if let window = self.window, windowContentView = window.contentView {
            window.titlebarAppearsTransparent = true
            windowContentView.addSubview(newIssueViewController.view);
            newIssueViewController.view.translatesAutoresizingMaskIntoConstraints = false
            
            newIssueViewController.view.leftAnchor.constraintEqualToAnchor(windowContentView.leftAnchor).active = true
            newIssueViewController.view.rightAnchor.constraintEqualToAnchor(windowContentView.rightAnchor).active = true
            newIssueViewController.view.topAnchor.constraintEqualToAnchor(windowContentView.topAnchor, constant: 30).active = true
            newIssueViewController.view.bottomAnchor.constraintEqualToAnchor(windowContentView.bottomAnchor).active = true
            newIssueViewController.onCancelClicked = { [weak self] in
                if let strongSelf = self, currentWindow = strongSelf.window {
                    currentWindow.close()
                }
            }
            
            let mainAppWindow = NSApp.windows[0]
            let windowLeft: CGFloat  = mainAppWindow.frame.origin.x + mainAppWindow.frame.size.width/2.0 - window.frame.size.width/2.0
            let windowTop: CGFloat  = mainAppWindow.frame.origin.y + mainAppWindow.frame.size.height/2.0 - window.frame.size.height/2.0
            window.setFrameOrigin(NSPoint(x: windowLeft, y: windowTop))
        }
        
        setupThemeObserver()
    }
    
    
    private func setupThemeObserver() {
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self, strongWindow = strongSelf.window, strongContentView = strongWindow.contentView else {
                return
            }
            
            if (.Dark == mode) {
                let appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
                strongWindow.appearance = appearance
                strongContentView.appearance = appearance
            } else {
                let appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
                strongWindow.appearance = appearance
                strongContentView.appearance = appearance
            }
        }
    }
    
    
    func windowWillClose(notification: NSNotification) {
        if let onWillCloseWindow = self.onWillCloseWindow {
            onWillCloseWindow()
        }
    }
    
}
