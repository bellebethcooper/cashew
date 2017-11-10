//
//  StatusBarViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/11/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRStatusBarSegmentedControl)
class StatusBarSegmentedControl: NSSegmentedControl {
    override var allowsVibrancy: Bool {
        return false
    }
}

@objc(SRStatusBarButton)
class StatusBarButton: NSButton {
    override var allowsVibrancy: Bool {
        return false
    }
}

class StatusBarBackgroundView: NSView {
    
    var backgroundColor: NSColor? {
        didSet {
            needsDisplay = true
            needsToDrawRect(bounds)
        }
    }
    
    override func drawRect(dirtyRect: NSRect) {
        if let color = backgroundColor {
            color.set()
            NSRectFill(self.bounds);
        }
    }
}
class StatusBarView: NSView {
    
    private let bgView = StatusBarBackgroundView()
    
    var backgroundColor: NSColor? {
        didSet {
            bgView.backgroundColor = backgroundColor
        }
    }
    
    override func viewDidMoveToWindow() {
        if let aFrameView = window?.contentView?.superview {
            bgView.frame = aFrameView.bounds
            bgView.autoresizingMask = [NSAutoresizingMaskOptions.ViewWidthSizable, NSAutoresizingMaskOptions.ViewHeightSizable]
            aFrameView.addSubview(bgView, positioned:NSWindowOrderingMode.Below, relativeTo: aFrameView)
        }
        
    }
}

@objc(SRStatusBarViewController)
class StatusBarViewController: NSViewController {
    
    @IBOutlet weak var tableView: BaseTableView!
    @IBOutlet weak var headerView: BaseView!
    @IBOutlet weak var footerView: BaseView!
    @IBOutlet weak var tabButton: StatusBarSegmentedControl!
    @IBOutlet weak var newIssueButton: StatusBarButton!
    @IBOutlet weak var settingsButton: StatusBarButton!
    @IBOutlet weak var openCashewAppButton: StatusBarButton!
    @IBOutlet weak var refreshButton: StatusBarButton!
    @IBOutlet weak var headerSeparatorView: BaseSeparatorView!
    @IBOutlet weak var footerSeparatorView: BaseSeparatorView!
    
    private let dataSource = QIssuesViewDataSource()
    
    var didClickCreateIssueAction: dispatch_block_t?
    var didClickQuitAction: dispatch_block_t?
    var didClickPreferencesAction: dispatch_block_t?
    var didClickShowAppAction: dispatch_block_t?
    
    deinit {
        tableView.delegate = nil
        tableView.dataSource = nil
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.action = #selector(StatusBarViewController.didSelectIssue(_:))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.shouldAllowVibrancy = false
        headerSeparatorView.shouldAllowVibrancy = false
        footerSeparatorView.shouldAllowVibrancy = false
        if let scrollView = tableView.enclosingScrollView as? BaseScrollView {
            scrollView.shouldAllowVibrancy = false
            
            if let scroller = scrollView.verticalScroller as? BaseScroller {
                scroller.shouldAllowVibrancy = false
            }
            if let scroller = scrollView.horizontalScroller as? BaseScroller {
                scroller.shouldAllowVibrancy = false
            }
        }
        
        settingsButton.toolTip = "Click to view Settings menu"
        newIssueButton.toolTip = "Click to create new issue"
        openCashewAppButton.toolTip = "Click to open main Cashew window"
        refreshButton.toolTip = "Click to refresh current list"
        
        //        settingsButton.wantsLayer = true
        //        settingsButton.layer?.backgroundColor = NSColor.clearColor().CGColor
        //        settingsButton.layer?.masksToBounds = true
        
        [headerView, footerView].forEach { (view) in
            view.disableThemeObserver = true
        }
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else { return }
            
            //let appearance: NSAppearance?
            let headerBgColor: NSColor
            if mode == .Dark {
                // appearance = NSAppearance(appearanceNamed: NSAppearanceNameVibrantDark, bundle: nil)
                headerBgColor = NSColor(calibratedWhite: 25/255.0, alpha: 1)
            } else {
                // appearance = NSAppearance(appearanceNamed: NSAppearanceNameAqua, bundle: nil)
                headerBgColor = CashewColor.currentLineBackgroundColor()
            }
            
            // strongSelf.tabButton.appearance = appearance
            //  strongSelf.newIssueButton.appearance = appearance
            
            [strongSelf.headerView, strongSelf.footerView].forEach { (view) in
                view.backgroundColor = headerBgColor
                //strongSelf.settingsButton.layer?.backgroundColor = headerBgColor.CGColor
                view.shouldAllowVibrancy = false
            }
            
            strongSelf.settingsButton.image = NSImage(named: "gear")?.imageWithTintColor(CashewColor.foregroundColor())
            
            if let view = strongSelf.view as? StatusBarView {
                view.backgroundColor = headerBgColor
            }
        }
        
        dataSource.dataSourceDelegate = self
    }
    
//    override func viewWillAppear() {
//        super.viewWillAppear()
//        if let view = view as? StatusBarView {
//            view.bgView.needsDisplay = true
//            view.bgView.needsToDrawRect(view.bgView.bounds)
//        }
//    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        Analytics.logCustomEventWithName("Status Bar View Did Appear", customAttributes: nil)
        refresh()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        Analytics.logCustomEventWithName("Status Bar View Did Disappear", customAttributes: nil)
    }
    
    func refresh() {
        let filter = QIssueFilter()
        filter.account = QContext.sharedContext().currentAccount
        if  self.tabButton.selectedSegment == 0 {
            filter.filterType = SRFilterType_Notifications
        } else if self.tabButton.selectedSegment == 2 {
            filter.filterType = SRFilterType_Favorites
            
        } else if self.tabButton.selectedSegment == 1 {
            filter.filterType = SRFilterType_Search
            let currentUserId = QContext.sharedContext().currentAccount.userId
            let account = QContext.sharedContext().currentAccount;
            let currentUser = QOwnerStore.ownerForAccountId(account.identifier, identifier: currentUserId)
            filter.assignees = NSOrderedSet(object: currentUser.login)
            filter.states = NSOrderedSet(object: NSNumber(integer: IssueStoreIssueState_Open))
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            self.dataSource.fetchIssuesWithFilter(filter)
            dispatch_async(dispatch_get_main_queue()) {
                // self.tableView.sizeToFit()
                //self.tableView.beginUpdates()
                self.tableView.reloadData()
                //self.tableView.endUpdates()
            }
        })
    }
    
    // MARK: Actions
    
    @IBAction func didClickCreateIssueButton(sender: AnyObject) {
        Analytics.logCustomEventWithName("Status Bar Did Click Create Issue Button", customAttributes: nil)
        if let didClickCreateIssueAction = self.didClickCreateIssueAction {
            didClickCreateIssueAction()
        }
    }
    
    @IBAction func didClickSettingsButton(sender: AnyObject) {
        
        guard let event = self.view.window?.currentEvent else { return }
        let menu = SRMenu()
        
        menu.addItem(NSMenuItem(title: "Open Cashew", action: #selector(StatusBarViewController.didClickShowAppButton(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(StatusBarViewController.didClickPreferencesButton(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(NSMenuItem(title: "Quit Cashew", action: #selector(StatusBarViewController.didClickQuitButton(_:)), keyEquivalent: ""))
        
        menu.itemArray.forEach { (menuitem) in
            menuitem.target = self
        }
        
        let pointInWindow = settingsButton.convertPoint(CGPoint.zero, toView: nil)
        let point = NSPoint(x: pointInWindow.x + settingsButton.frame.width - menu.size.width, y: pointInWindow.y - settingsButton.frame.height)
        if let windowNumber = view.window?.windowNumber, popupEvent = NSEvent.mouseEventWithType(.LeftMouseUp, location: point, modifierFlags: event.modifierFlags, timestamp: 0, windowNumber: windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0) {
            SRMenu.popUpContextMenu(menu, withEvent: popupEvent, forView: settingsButton)
        }
        
    }
    
    @objc
    private func didClickPreferencesButton(sender: AnyObject) {
        if let didClickPreferencesAction = didClickPreferencesAction {
            didClickPreferencesAction()
        }
    }
    
    @objc
    private func didClickQuitButton(sender: AnyObject) {
        if let didClickQuitAction = didClickQuitAction {
            didClickQuitAction()
        }
    }
    
    
    @objc
    private func didClickShowAppButton(sender: AnyObject) {
        if let didClickShowAppAction = didClickShowAppAction {
            didClickShowAppAction()
        }
    }
    
    @IBAction
    func didClickRefreshButton(sender: AnyObject) {
        Analytics.logCustomEventWithName("Status Bar Did Click Refresh Button", customAttributes: nil)
        refresh()
    }
    
    @IBAction
    func didClickOpenCashewAppStatusBarButton(sender: AnyObject) {
        Analytics.logCustomEventWithName("Status Bar Did Click Open Cashew App", customAttributes: nil)
        if let didClickShowAppAction = didClickShowAppAction {
            didClickShowAppAction()
        }
    }
    
    
    
    @IBAction
    func didClickSegmentatedControleButton(sender: AnyObject) {
        Analytics.logCustomEventWithName("Status Bar Did Select Tab", customAttributes: ["tabIndex": self.tabButton.selectedSegment])
        refresh()
    }
    
    @objc
    private func didSelectIssue(sender: AnyObject) {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 && selectedRow < dataSource.numberOfIssues() {
            let issue = dataSource.issueAtIndex(selectedRow)
            NSNotificationCenter.defaultCenter().postNotificationName(kOpenNewIssueDetailsWindowNotification, object: issue)
        }
    }
}


extension StatusBarViewController: QIssuesViewDataSourceDelegate {
    
    func dataSource(dataSource: QIssuesViewDataSource?, didInsertIndexSet: NSIndexSet, forFilter: QIssueFilter) {
        
    }
    
    func dataSource(dataSource: QIssuesViewDataSource?, didDeleteIndexSet: NSIndexSet, forFilter: QIssueFilter) {
        
    }
}


extension StatusBarViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil;
    }
    
    func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let issue = dataSource.issueAtIndex(row)
        let isRowSelected = tableView.selectedRowIndexes.containsIndex(row)
        let cellIdentifier = "QIssueTableViewCell"
        let rowView: QIssueTableViewCell
        
        if let aRowView = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil) as? QIssueTableViewCell {
            rowView = aRowView
        } else {
            let aRowView: QIssueTableViewCell = QIssueTableViewCell.instantiateFromNib()!
            rowView = aRowView
        }
        
        rowView.issue = issue
        rowView.selected = isRowSelected
        rowView.identifier = cellIdentifier
        rowView.shouldAllowVibrancy = false
        
        return rowView
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return QIssueTableViewCell.suggestedHeight()
    }
    
}

extension StatusBarViewController: NSTableViewDataSource {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return dataSource.numberOfIssues()
    }
}
