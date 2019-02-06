//
//  SearchBuilderViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/25/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class SearchBuilderLabel: NSTextField {
    override var allowsVibrancy: Bool {
        return false
    }
}

class SearchBuilderButton: NSButton {
    override var allowsVibrancy: Bool {
        return false
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
    }
}

@objc(SRSearchBuilderViewControllerDataSource)
protocol SearchBuilderViewControllerDataSource: NSObjectProtocol {
    var criteriaViewControllerDataSource: SearchBuilderCriteriaViewControllerDataSource { get }
    
    func resetCache()
    
    func onSave(_ results: [SearchBuilderResult], searchName: String)
    
    func onSearch(_ results: [SearchBuilderResult])
}

@objc(SRSearchBuilderViewController)
class SearchBuilderViewController: NSViewController {
    
    var searchButton = BaseButton.greenButton()
    var saveButton = BaseButton.whiteButton()
    var cancelButton = BaseButton.whiteButton()
    
    @IBOutlet weak var searchNameTextField: SearchBuilderLabel!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var verticalScroller: BaseScroller!
    @IBOutlet weak var horizontalScroller: BaseScroller!
    
    var dataSource: SearchBuilderViewControllerDataSource?
    weak var popover: NSPopover?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let baseView = view as? BaseView {
            baseView.popoverBackgroundColorFixEnabed = true
            baseView.shouldAllowVibrancy = false
        }
        
        verticalScroller.shouldAllowVibrancy = false
        horizontalScroller.shouldAllowVibrancy = false
        
        saveButton.enabled = false
        
        searchNameTextField.delegate = self
        
        stackView.wantsLayer = true
//        stackView.layer?.borderWidth = 1
//        stackView.layer?.borderColor = NSColor.greenColor().CGColor
        
        // add first child controller
        addCriteriaViewController()?.removeButtonEnabled = false
        
        setupButtons()
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            if let view = self?.view as? BaseView {
                view.shouldAllowVibrancy = false
                
                if mode == .dark {
                    view.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
                } else {
                    view.backgroundColor = CashewColor.backgroundColor()
                }
            }
        }
    }
    
    fileprivate func setupButtons() {
        view.addSubview(saveButton)
        view.addSubview(searchButton)
        view.addSubview(cancelButton)
        
        [saveButton, searchButton, cancelButton].forEach { (btn) in
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 26).isActive = true
            btn.widthAnchor.constraint(equalToConstant: 100).isActive = true
        }
        
        searchButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        saveButton.rightAnchor.constraint(equalTo: searchButton.leftAnchor, constant: -20).isActive = true
        cancelButton.rightAnchor.constraint(equalTo: saveButton.leftAnchor, constant: -10).isActive = true
        //cancelButton.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: 20).active = true
        
        saveButton.text = "Save"
        searchButton.text = "Search"
        cancelButton.text = "Cancel"
        
        saveButton.onClick = { [weak self] in
            self?.didClickSaveButton()
        }
        
        searchButton.onClick = { [weak self] in
            self?.didClickSearchButton()
        }
        
        cancelButton.onClick = { [weak self] in
            self?.didClickCancelButton()
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if (searchNameTextField.stringValue as NSString).trimmedString().length == 0 {
            saveButton.enabled = false
        } else {
            saveButton.enabled = true
        }
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
    }
    
    
    fileprivate func addCriteriaViewController() -> SearchBuilderCriteriaViewController? {
        let controller = SearchBuilderCriteriaViewController(nibName: "SearchBuilderCriteriaViewController", bundle: nil)
        
        
        if let lastController = children.first as? SearchBuilderCriteriaViewController , children.count == 1 {
            lastController.removeButtonEnabled = true
        }
        
        addChild(controller)
        stackView.addView(controller.view, in: .bottom)
        controller.view.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        controller.clickedCreateNewFilter = { [weak self] in
            self?.addCriteriaViewController()
        }
        
        controller.clickedRemoveCurrentFilter = { [weak self] (removeControler) in
            self?.removeCriteriaViewController(removeControler)
        }
        
        if let docView = scrollView.documentView {
            scrollView.contentView.scroll(to: NSMakePoint(0, -docView.frame.height))
        }
 
        if let dataSource = dataSource {
            controller.dataSource = dataSource.criteriaViewControllerDataSource
        }
        
        return controller
    }
    
    fileprivate func removeCriteriaViewController(_ controller: SearchBuilderCriteriaViewController) {
        
        if let index = children.index(of: controller) {
            removeChild(at: index)
            controller.view.removeFromSuperview()
        }
        
        if let lastController = children.first as? SearchBuilderCriteriaViewController , children.count == 1 {
            lastController.removeButtonEnabled = false
        }
    }
}


// MARK: Actions

extension SearchBuilderViewController {
    
    func didClickCancelButton() {
        
        while children.count > 1 {
            guard let childController = children.last as? SearchBuilderCriteriaViewController else { return }
            removeCriteriaViewController(childController)
        }
        
        if let childViewController = children.first as? SearchBuilderCriteriaViewController {
            childViewController.reloadData()
        }
        
        //dataSource?.resetCache()
        searchNameTextField.stringValue = ""
        popover?.close()
    }
    
    func didClickSearchButton() {
        
        var results = [SearchBuilderResult]()
        
        children.forEach { (child) in
            guard let controller = child as? SearchBuilderCriteriaViewController else { return }
            let result = SearchBuilderResult(criteriaType: controller.filterTypeButton.title, partOfSpeech: controller.partOfSentenceButton.title, criteriaValue: controller.valueComboBox.stringValue)
            results.append(result)
        }
        
        self.dataSource?.onSearch(results)
    }
    
    func didClickSaveButton() {
        
        var results = [SearchBuilderResult]()
        
        children.forEach { (child) in
            guard let controller = child as? SearchBuilderCriteriaViewController else { return }
            let result = SearchBuilderResult(criteriaType: controller.filterTypeButton.title, partOfSpeech: controller.partOfSentenceButton.title, criteriaValue: controller.valueComboBox.stringValue)
            results.append(result)
        }
        
        if (searchNameTextField.stringValue as NSString).trimmedString().length == 0 {
            saveButton.enabled = false
        } else {
            saveButton.enabled = true
        }
        
        self.dataSource?.onSave(results, searchName: searchNameTextField.stringValue)
        didClickCancelButton()
        
    }
}

extension SearchBuilderViewController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        
        if (searchNameTextField.stringValue as NSString).trimmedString().length == 0 {
            saveButton.enabled = false
        } else {
            saveButton.enabled = true
        }
        
    }
}
