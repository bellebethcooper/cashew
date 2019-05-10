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
    fileprivate(set) lazy var newIssueViewController: NewIssueViewController = {
        return NewIssueViewController()
    }()
    
    @objc var request: CreateIssueRequest? {
        didSet {
            self.newIssueViewController.request = request
        }
    }
    
    var onWillCloseWindow: ( ()-> Void)?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // setup new issue view controller
        if let window = self.window, let windowContentView = window.contentView {
            window.titlebarAppearsTransparent = true
            windowContentView.addSubview(newIssueViewController.view);
            newIssueViewController.view.translatesAutoresizingMaskIntoConstraints = false
            
            newIssueViewController.view.leftAnchor.constraint(equalTo: windowContentView.leftAnchor).isActive = true
            newIssueViewController.view.rightAnchor.constraint(equalTo: windowContentView.rightAnchor).isActive = true
            newIssueViewController.view.topAnchor.constraint(equalTo: windowContentView.topAnchor, constant: 30).isActive = true
            newIssueViewController.view.bottomAnchor.constraint(equalTo: windowContentView.bottomAnchor).isActive = true
            newIssueViewController.onCancelClicked = { [weak self] in
                if let strongSelf = self, let currentWindow = strongSelf.window {
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
    
    
    fileprivate func setupThemeObserver() {
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self, let strongWindow = strongSelf.window, let strongContentView = strongWindow.contentView else {
                return
            }
            
            if (.dark == mode) {
                let appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
                strongWindow.appearance = appearance
                strongContentView.appearance = appearance
            } else {
                let appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
                strongWindow.appearance = appearance
                strongContentView.appearance = appearance
            }
        }
    }
    
    
    func windowWillClose(_ notification: Notification) {
        if let onWillCloseWindow = self.onWillCloseWindow {
            onWillCloseWindow()
        }
    }
    
}
