//
//  BaseMenuButton.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/30/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRBaseMenuButton)
class BaseMenuButton: NSPopUpButton {
    
    
    required init() {
        super.init(frame: CGRect.zero, pullsDown: false)
        //enabled = true
        autoenablesItems = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class RepositoriesMenuButton: BaseMenuButton {
    
    var currentRepository: QRepository? {
        didSet {
            if currentRepository != oldValue {
                setupCurrentRepoSelection()
            }
        }
    }
    var onRepoChange: dispatch_block_t?
    
    var repositories = [QRepository]() {
        didSet {
            if repositories != oldValue {
                setupCurrentRepoSelection()
            }
        }
    }
    
    private func setupCurrentRepoSelection() {
        let menu = SRMenu()
        
        repositories.sortInPlace({ (repo1, repo2) -> Bool in
            if repo1 == currentRepository {
                return true
            } else if repo2 == currentRepository {
                return false
            }
            return repo1.name.compare(repo2.name) == .OrderedAscending
        })
        
        repositories.forEach { (repo) in
            let menuItem = NSMenuItem(title: repo.fullName, action: #selector(RepositoriesMenuButton.didSelectMenuButton(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = repo
            menu.addItem(menuItem)
        }
        
        self.menu = menu
    }
    
    @objc
    private func didSelectMenuButton(sender: NSMenuItem) {
        //DDLogDebug("didSelect menu item = \(sender)")
        if let repo = sender.representedObject as? QRepository {
            currentRepository = repo
            
//            let menu = SRMenu()
//            //repositories = repositories.filter({$0 != repo})
//            repositories.sortInPlace({ (repo1, repo2) -> Bool in
//                return repo1.name.compare(repo2.name) == .OrderedAscending
//            })
//            repositories.insert(repo, atIndex: 0)
//        
//            repositories.forEach { (repo) in
//                let menuItem = NSMenuItem(title: repo.fullName, action: #selector(RepositoriesMenuButton.didSelectMenuButton(_:)), keyEquivalent: "")
//                menuItem.target = self
//                menuItem.representedObject = repo
//                menu.addItem(menuItem)
//            }
            
//            selectItem(sender)
            
//
            let index = repositories.indexOf(repo)
            
            if let index = index {
                selectItemAtIndex(index)
               // indexOfSelectedItem = index
//                [menu bind:@"selectedIndex" toObject:self withKeyPath:@"indexOfSelectedItem" options:nil];

            }
//            selectItemWithTitle(repo.fullName)
//            synchronizeTitleAndSelectedItem()
            
            //self.menu = menu
            
            
            if let onRepoChange = onRepoChange {
                onRepoChange()
            }
            
        }
    }
}
