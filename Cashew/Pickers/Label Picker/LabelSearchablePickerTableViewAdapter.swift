//
//  LabelSearchablePickerTableViewAdapter.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/13/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRLabelSearchablePickerTableViewAdapter)
class LabelSearchablePickerTableViewAdapter: NSObject, SearchablePickerTableAdapter {
    
    var dataSource: LabelSearchablePickerDataSource
    var height: CGFloat {
        return 55.0
    }
    
    required init(dataSource: LabelSearchablePickerDataSource) {
        self.dataSource = dataSource
    }
    
    func adapt(_ view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView? {
        guard let label = item as? QLabel else { return nil }
        
        let handler = { [weak self] (rowView: LabelSearchResultTableRowView) in
            guard let strongSelf = self else { return }
            if strongSelf.dataSource.isPartialSelection(label) {
                rowView.accessoryView = GreenDottedView()
                rowView.checked = true
            } else {
                rowView.accessoryView = GreenCheckboxView()
                rowView.checked = strongSelf.dataSource.isSelectedItem(label)
            }
            rowView.accessoryView?.disableThemeObserver = true
            rowView.accessoryView?.backgroundColor = NSColor.clear
        }
        
        if let view = view as? LabelSearchResultTableRowView {
            view.label = label
            handler(view)
            return view
        } else {
            let rowView = LabelSearchResultTableRowView(label: label)
            handler(rowView)
            
            return rowView
        }
    }
}
