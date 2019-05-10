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
    
    @objc let suggestionViewController = SearchSuggestionViewController(nibName: "SearchSuggestionViewController", bundle:nil)
    
    override func windowDidLoad() {
        super.windowDidLoad()
        guard let window = self.window else { return }
        
        window.backgroundColor = NSColor.clear

        let suggestionViewController = self.suggestionViewController
        
        contentContainerView.addSubview(suggestionViewController.view)
        suggestionViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        suggestionViewController.view.leftAnchor.constraint(equalTo: contentContainerView.leftAnchor).isActive = true
        suggestionViewController.view.rightAnchor.constraint(equalTo: contentContainerView.rightAnchor).isActive = true
        suggestionViewController.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor).isActive = true
        suggestionViewController.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor).isActive = true
        
        if (.dark == UserDefaults.themeMode()) {
            let appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
            window.appearance = appearance;
        } else {
            let appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
            window.appearance = appearance;
        }
        
        window.invalidateShadow()
    }
    
}
