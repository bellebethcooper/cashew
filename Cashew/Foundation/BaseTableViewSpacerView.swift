//
//  BaseTableViewSpacerView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/18/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRBaseSpacerTableRowViewItem)
class BaseSpacerTableRowViewItem: NSObject {
    let spaceHeight: CGFloat
    
    required init(spaceHeight: CGFloat) {
        self.spaceHeight = spaceHeight
        super.init()
    }
}

@objc(SRBaseSpacerTableRowView)
class BaseSpacerTableRowView: NSTableRowView {
    
}

@objc(SRBaseTableViewSpacerView)
class BaseSpacerTableViewAdapter: NSObject, BaseTableViewAdapter {

    func height(_ item: AnyObject, index: Int) -> CGFloat {
        guard let item = item as? BaseSpacerTableRowViewItem else { return 0 }
        return item.spaceHeight
    }
    
    func adapt(_ view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView? {
        guard let _ = item as? BaseSpacerTableRowViewItem else { return nil }
        
        let rowView: BaseSpacerTableRowView
        if let view = view as? BaseSpacerTableRowView {
            rowView = view
        } else {
            rowView = BaseSpacerTableRowView()
        }
        
        return rowView
    }
    
}
