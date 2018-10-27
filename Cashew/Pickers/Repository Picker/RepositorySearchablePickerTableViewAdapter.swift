//
//  RepositorySearchablePickerTableViewAdapter.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/13/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa


@objc(SRRepositorySearchablePickerTableViewAdapter)
class RepositorySearchablePickerTableViewAdapter: NSObject, SearchablePickerTableAdapter {
    
    var dataSource: RepositorySearchablePickerDataSource
    var height: CGFloat {
        return 55.0
    }
    
    @objc
    required init(dataSource: RepositorySearchablePickerDataSource) {
        self.dataSource = dataSource
    }
    
    func adapt(_ view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView? {
        if let repo = item as? QRepository {
            if let view = view as? RepositorySearchResultTableRowView {
                view.repository = repo
                view.checked = dataSource.isSelectedItem(repo)
                
                return view
            } else {
                let rowView = RepositorySearchResultTableRowView(repository: repo)
                rowView.checked = dataSource.isSelectedItem(repo)
                
                return rowView
            }
        } else if item is OrganizationPrivateRepositoryPermissionViewModel {
            if let view = view as? OrganizationPrivateRepositoryPermissionTableRowView {
                return view
            } else {
                return OrganizationPrivateRepositoryPermissionTableRowView()
            }
        }
        
        return nil
    }
}
