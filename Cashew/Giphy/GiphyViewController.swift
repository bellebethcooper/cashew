//
//  GiphyViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/29/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRGiphyViewControllerView)
class SRGiphyViewControllerView: BaseView {
    
    
    
    //    override var backgroundColor: NSColor! {
    //        didSet {
    //            needsDisplay = true
    //        }
    //    }
    //
//    override func drawRect(dirtyRect: NSRect) {
//        NSColor.whiteColor().set()
//        NSRectFill(NSMakeRect(0, 0, bounds.width, bounds.height + 50))
//    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.disableThemeObserver = true
        self.backgroundColor = NSColor.blackColor()
    }
}

@objc(SRGiphyViewController)
class GiphyViewController: NSViewController {
    
    @IBOutlet weak var tableView: BaseTableView!
    @IBOutlet weak var searchField: BaseTextField!
    @IBOutlet var controllerView: SRGiphyViewControllerView!
    @IBOutlet weak var searchFieldContainerView: BaseView!
    
    
    private let dataSource = GiphySearchDataSource()
    
    
    var onGifSelection: ( (GiphyImage) -> Void )?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        controllerView.disableThemeObserver = true
        tableView.disableThemeObserver = true
        
        controllerView.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
        tableView.backgroundColor = DarkModeColor.sharedInstance.backgroundColor()
        searchFieldContainerView.disableThemeObserver = true
        searchFieldContainerView.backgroundColor = NSColor.clearColor()
        searchField.drawsBackground = true
        searchField.backgroundColor = NSColor.whiteColor()
        searchField.textColor = NSColor.blackColor()
        searchField.appearance = NSAppearance(named: NSAppearanceNameAqua)
        searchField.delegate = self
        
        let adapter = GiphySearchResultsTableViewAdapter(tableView: tableView)
        tableView.registerAdapter(adapter, forClass: GiphyImage.self)
        
    }
    
}

extension GiphyViewController: NSTextFieldDelegate {
    override func controlTextDidChange(obj: NSNotification) {
        self.dataSource.search(self.searchField.stringValue) { [weak self] in
            DispatchOnMainQueue({
                self?.tableView.scrollPoint(NSPoint.zero)
                self?.tableView.reloadData()
            })
        }
    }
}

extension GiphyViewController: NSTableViewDataSource {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return dataSource.numberOfRows
    }
    
}

extension GiphyViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil;
    }
    
    func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        if row > dataSource.numberOfRows - 1 {
            return nil
        }
        
        let item = dataSource.itemAtIndex(row)
        return self.tableView.adaptForItem(item, row: row, owner: self)
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let item = dataSource.itemAtIndex(row)
        return self.tableView.heightForItem(item, row: row)
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        let selectedIndex = tableView.selectedRow
        let item = dataSource.itemAtIndex(selectedIndex)
        if let onGifSelection = onGifSelection {
            onGifSelection(item)
        }
    }
    
}
