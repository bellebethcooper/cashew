//
//  SearchBuilderCriteriaViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/25/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class SearchBuilderValueComboBox: NSComboBox {
    var representedObject: AnyObject?
}

@objc(SRSearchBuilderCriteriaViewControllerDataSource)
protocol SearchBuilderCriteriaViewControllerDataSource: NSObjectProtocol, NSComboBoxDataSource {
    func criteriaFields() -> [String]
    func partsOfSpeechForCriteriaField(_ field: String) -> [String]
    func valuesForCriteriaField(_ field: String) -> [String]
    func resetCachedValues()
    func shouldHideValueForPartOfSpeech(_ pos: String) -> Bool
}

@objc(SRSearchBuilderCriteriaViewController)
class SearchBuilderCriteriaViewController: NSViewController {
    
    //   @IBOutlet weak var valueTextField: NSTextField!
    @IBOutlet weak var partOfSentenceButton: NSPopUpButton!
    @IBOutlet weak var filterTypeButton: NSPopUpButton!
    @IBOutlet weak var addNewFilterButton: NSButton!
    @IBOutlet weak var removeCurrentFilterButton: NSButton!
    @IBOutlet weak var valueComboBox: SearchBuilderValueComboBox!
    
    var dataSource: SearchBuilderCriteriaViewControllerDataSource? {
        didSet {
            reloadData()
            //            let menu = SRMenu()
            //            if let dataSource = dataSource {
            //                dataSource.criteriaFields().forEach({ [weak self] (criteria) in
            //                    if let menuItem = menu.addItemWithTitle(criteria, action: #selector(SearchBuilderCriteriaViewController.didSelectCriteriaType(_:)), keyEquivalent: "") {
            //                        menuItem.target = self
            //                    }
            //                })
            //                valueComboBox.usesDataSource = true
            //                valueComboBox.dataSource = dataSource
            //            } else {
            //                valueComboBox.usesDataSource = false
            //                valueComboBox.dataSource = nil
            //            }
            //            filterTypeButton.menu = menu
            //            if let firstMenuItem = menu.itemArray.first {
            //                didSelectCriteriaType(firstMenuItem)
            //            }
        }
    }
    
    func reloadData() {
        valueComboBox.stringValue = ""
        
        let menu = SRMenu()
        if let dataSource = dataSource {
            dataSource.criteriaFields().forEach{ [weak self] (criteria) in
                let menuItem = menu.addItem(withTitle: criteria, action: #selector(SearchBuilderCriteriaViewController.didSelectCriteriaType(_:)), keyEquivalent: "")
                menuItem.target = self
            }
            valueComboBox.usesDataSource = true
            valueComboBox.dataSource = dataSource
        } else {
            valueComboBox.usesDataSource = false
            valueComboBox.dataSource = nil
        }
        filterTypeButton.menu = menu
        if let firstMenuItem = menu.items.first {
            didSelectCriteriaType(firstMenuItem)
        }
    }
    
    var removeButtonEnabled: Bool {
        get {
            return removeCurrentFilterButton.isEnabled
        }
        set {
            removeCurrentFilterButton.isEnabled = newValue
        }
    }
    
    var clickedRemoveCurrentFilter: ( (SearchBuilderCriteriaViewController) -> Void )?
    var clickedCreateNewFilter: ( () -> Void )?
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        
        if let view = view as? BaseView {
            view.disableThemeObserver = true
        }
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { (mode) in
            guard let view = self.view as? BaseView else { return }
            if mode == .dark {
                view.backgroundColor = NSColor(calibratedWhite: 100/255.0, alpha: 1)
            } else {
                //view.backgroundColor = NSColor.whiteColor()
                view.backgroundColor = CashewColor.currentLineBackgroundColor()
            }
        }
        
    }
    
    @objc
    fileprivate func didSelectCriteriaType(_ sender: NSMenuItem) {
        guard let dataSource = dataSource else { return }
        let menu = SRMenu()
        
        let partsOfSpeech = dataSource.partsOfSpeechForCriteriaField(sender.title)
        partsOfSpeech.forEach { [weak self] (pos) in
            let menuItem = menu.addItem(withTitle: pos, action: #selector(SearchBuilderCriteriaViewController.didSelectPartOfSpeech(_:)), keyEquivalent: "")
            menuItem.target = self
        }
        
        partOfSentenceButton.isHidden = partsOfSpeech.count == 0
        partOfSentenceButton.menu = menu
        
        valueComboBox.isHidden = !partOfSentenceButton.isHidden && dataSource.shouldHideValueForPartOfSpeech(partOfSentenceButton.title)
        valueComboBox.stringValue = ""
        valueComboBox.representedObject = sender.title as AnyObject?
        valueComboBox.reloadData()
    }
    
    @objc
    fileprivate func didSelectPartOfSpeech(_ sender: NSMenuItem) {
        guard let dataSource = dataSource else { return }
        valueComboBox.isHidden = !partOfSentenceButton.isHidden && dataSource.shouldHideValueForPartOfSpeech(partOfSentenceButton.title)
    }
    
}

// MARK: Actions

extension SearchBuilderCriteriaViewController {
    
    @IBAction func didClickRemoveCurrentFilterButton(_ sender: AnyObject) {
        if let block = clickedRemoveCurrentFilter {
            block(self)
        }
    }
    @IBAction func didClickCreateNewFilterButton(_ sender: AnyObject) {
        if let block = clickedCreateNewFilter {
            block()
        }
    }
}
