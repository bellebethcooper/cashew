//
//  GiphySearchResultsTableViewAdapter.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/29/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRGiphySearchResultsTableViewAdapter)
class GiphySearchResultsTableViewAdapter: NSObject, BaseTableViewAdapter {
    
    private weak var tableView: BaseTableView?
    
    required init(tableView: BaseTableView) {
        super.init()
        self.tableView = tableView
    }
    
    func height(item: AnyObject, index: Int) -> CGFloat {
        guard let giphy = item as? GiphyImage, tableView = tableView else { return 0 }
        return (tableView.frame.width * giphy.height) / giphy.width
    }
    
    func adapt(view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView? {
        guard let giphy = item as? GiphyImage else { return nil }
        
        let rowView: GiphyImageTableRowView
        if let view = view as? GiphyImageTableRowView {
            rowView = view
        } else {
            rowView = GiphyImageTableRowView.instantiateFromNib()!
        }
            rowView.model = giphy
        
        return rowView
    }
}
