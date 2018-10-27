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
        self.backgroundColor = NSColor.black
    }
}

@objc(SRGiphyViewController)
class GiphyViewController: NSViewController {
    
    @IBOutlet weak var tableView: BaseTableView!
    @IBOutlet weak var searchField: BaseTextField!
    @IBOutlet var controllerView: SRGiphyViewControllerView!
    @IBOutlet weak var searchFieldContainerView: BaseView!
    
    
    fileprivate let dataSource = GiphySearchDataSource()
    
    
    var onGifSelection: ( (GiphyImage) -> Void )?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        controllerView.disableThemeObserver = true
        tableView.disableThemeObserver = true
        
        controllerView.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
        tableView.backgroundColor = DarkModeColor.sharedInstance.backgroundColor()
        searchFieldContainerView.disableThemeObserver = true
        searchFieldContainerView.backgroundColor = NSColor.clear
        searchField.drawsBackground = true
        searchField.backgroundColor = NSColor.white
        searchField.textColor = NSColor.black
        searchField.appearance = NSAppearance(named: NSAppearance.Name.aqua)
        searchField.delegate = self
        
        let adapter = GiphySearchResultsTableViewAdapter(tableView: tableView)
        tableView.registerAdapter(adapter, forClass: GiphyImage.self)
        
    }
    
}

extension GiphyViewController: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        self.dataSource.search(self.searchField.stringValue) { [weak self] in
            DispatchOnMainQueue({
                self?.tableView.scroll(NSPoint.zero)
                self?.tableView.reloadData()
            })
        }
    }
}

extension GiphyViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataSource.numberOfRows
    }
    
}

extension GiphyViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil;
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        if row > dataSource.numberOfRows - 1 {
            return nil
        }
        
        let item = dataSource.itemAtIndex(row)
        return self.tableView.adaptForItem(item, row: row, owner: self)
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let item = dataSource.itemAtIndex(row)
        return self.tableView.heightForItem(item, row: row)
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedIndex = tableView.selectedRow
        let item = dataSource.itemAtIndex(selectedIndex)
        if let onGifSelection = onGifSelection {
            onGifSelection(item)
        }
    }
    
}
