//
//  BaseTableView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/17/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

protocol BaseTableViewAdapter: NSObjectProtocol {
    func height(_ item: AnyObject, index: Int) -> CGFloat
    func adapt(_ view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView?
}

@objc(SRBaseTableView)
class BaseTableView: NSTableView {
    
    var shouldAllowVibrancy = true
    
    override var allowsVibrancy: Bool {
        return shouldAllowVibrancy
    }
    
    fileprivate var adapters = [String: BaseTableViewAdapter]()
    var disableThemeObserver = false {
        didSet {
            if disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(self)
            }
        }
    }
    
    func registerAdapter(_ adapter: BaseTableViewAdapter, forClass clazz: AnyClass) {
        adapters[NSStringFromClass(clazz)] = adapter
    }
    
    func adaptForItem(_ item: AnyObject, row: Int, owner: AnyObject?) -> NSTableRowView? {
        let reuseId = type(of: item).description()
        guard let adapter = adapters[reuseId] else { return nil }
        
        if let rowView = makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: reuseId), owner: owner) as? NSTableRowView {
            return adapter.adapt(rowView, item: item, index: row)
        } else {
            return adapter.adapt(nil, item: item, index: row)
        }
    }
    
    func heightForItem(_ item: AnyObject, row: Int) -> CGFloat {
        let reuseId = type(of: item).description()
        guard let adapter = adapters[reuseId] else { return 0 }
        
        return adapter.height(item, index: row)
    }
    
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    fileprivate func setup() {
        self.wantsLayer = true
        self.canDrawConcurrently = true
        
        if disableThemeObserver {
            return;
        }
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(strongSelf)
                return;
            }
            strongSelf.backgroundColor = CashewColor.backgroundColor()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

}
