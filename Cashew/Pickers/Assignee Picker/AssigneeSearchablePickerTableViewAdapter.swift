//
//  AssigneeSearchablePickerTableViewAdapter.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/2/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRAssigneeSearchablePickerTableViewAdapter)
class AssigneeSearchablePickerTableViewAdapter: NSObject, SearchablePickerTableAdapter {
    
    var dataSource: AssigneeSearchablePickerDataSource
    var height: CGFloat {
        return 55.0
    }
    
    required init(dataSource: AssigneeSearchablePickerDataSource) {
        self.dataSource = dataSource
    }
    
    func adapt(view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView? {
        guard let assignee = item as? QOwner else { return nil }
        
        let handler = { [weak self] (rowView: AssigneeSearchResultTableRowView) in
            guard let strongSelf = self else { return }
            if strongSelf.dataSource.isPartialSelection(assignee) {
                rowView.accessoryView = GreenDottedView()
                rowView.checked = true
            } else {
                rowView.accessoryView = GreenCheckboxView()
                rowView.checked = strongSelf.dataSource.isSelectedItem(assignee)
            }
            rowView.accessoryView?.disableThemeObserver = true
            rowView.accessoryView?.backgroundColor = NSColor.clearColor()
        }
        
        if let view = view as? AssigneeSearchResultTableRowView {
            view.owner = assignee
            handler(view)
            return view
        } else {
            let rowView = AssigneeSearchResultTableRowView(owner: assignee)
            handler(rowView)
            
            return rowView
        }
    }
}
