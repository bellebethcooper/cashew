//
//  SearchSuggestionWindowController.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/17/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class SearchSuggestionWindowController: NSWindowController {
    
    @IBOutlet weak var contentContainerView: BaseView!
    
    let suggestionViewController = SearchSuggestionViewController(nibName: "SearchSuggestionViewController", bundle:nil)
    
    override func windowDidLoad() {
        super.windowDidLoad()
        guard let window = self.window else { return }
        
        window.backgroundColor = NSColor.clearColor()

        guard let suggestionViewController = suggestionViewController else { return }
        
        contentContainerView.addSubview(suggestionViewController.view)
        suggestionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        suggestionViewController.view.leftAnchor.constraintEqualToAnchor(contentContainerView.leftAnchor).active = true
        suggestionViewController.view.rightAnchor.constraintEqualToAnchor(contentContainerView.rightAnchor).active = true
        suggestionViewController.view.topAnchor.constraintEqualToAnchor(contentContainerView.topAnchor).active = true
        suggestionViewController.view.bottomAnchor.constraintEqualToAnchor(contentContainerView.bottomAnchor).active = true
        
        if (.Dark == NSUserDefaults.themeMode()) {
            let appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
            window.appearance = appearance;
        } else {
            let appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
            window.appearance = appearance;
        }
        
        window.invalidateShadow()
    }
    
}
