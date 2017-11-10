//
//  MilestoneSearchablePickerTableViewAdapter.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/1/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRMilestoneSearchablePickerTableViewAdapter)
class MilestoneSearchablePickerTableViewAdapter: NSObject, SearchablePickerTableAdapter {
    
    var dataSource: MilestoneSearchablePickerDataSource
    var height: CGFloat {
        return 55.0
    }
    
    required init(dataSource: MilestoneSearchablePickerDataSource) {
        self.dataSource = dataSource
    }
    
    func adapt(view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView? {
        guard let milestone = item as? QMilestone else { return nil }
        
        let handler = { [weak self] (rowView: MilestoneSearchResultTableRowView) in
            guard let strongSelf = self else { return }
            if strongSelf.dataSource.isPartialSelection(milestone) {
                rowView.accessoryView = GreenDottedView()
                rowView.checked = true
            } else {
                rowView.accessoryView = GreenCheckboxView()
                rowView.checked = strongSelf.dataSource.isSelectedItem(milestone)
            }
            rowView.accessoryView?.disableThemeObserver = true
            rowView.accessoryView?.backgroundColor = NSColor.clearColor()
        }
        
        if let view = view as? MilestoneSearchResultTableRowView {
            view.milestone = milestone
            handler(view)
            return view
        } else {
            let rowView = MilestoneSearchResultTableRowView(milestone: milestone)
            handler(rowView)
            
            return rowView
        }
    }
}
