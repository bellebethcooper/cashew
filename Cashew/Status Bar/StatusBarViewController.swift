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
            needsToDraw(bounds)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let color = backgroundColor {
            color.set()
            self.bounds.fill();
        }
    }
}
class StatusBarView: NSView {
    
    fileprivate let bgView = StatusBarBackgroundView()
    
    var backgroundColor: NSColor? {
        didSet {
            bgView.backgroundColor = backgroundColor
        }
    }
    
    override func viewDidMoveToWindow() {
        if let aFrameView = window?.contentView?.superview {
            bgView.frame = aFrameView.bounds
            bgView.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
            aFrameView.addSubview(bgView, positioned:NSWindow.OrderingMode.below, relativeTo: aFrameView)
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
    
    fileprivate let dataSource = QIssuesViewDataSource()
    
    var didClickCreateIssueAction: (()->())?
    var didClickQuitAction: (()->())?
    var didClickPreferencesAction: (()->())?
    var didClickShowAppAction: (()->())?
    
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
        //        settingsButton.layer?.backgroundColor = NSColor.clear().CGColor
        //        settingsButton.layer?.masksToBounds = true
        
        [headerView, footerView].forEach { (view) in
            view.disableThemeObserver = true
        }
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else { return }
            
            //let appearance: NSAppearance?
            let headerBgColor: NSColor
            if mode == .dark {
                // appearance = NSAppearance(appearanceNamed: NSAppearanceNameVibrantDark, bundle: nil)
                headerBgColor = NSColor(calibratedWhite: 25/255.0, alpha: 1)
            } else {
                // appearance = NSAppearance(appearanceNamed: NSAppearanceNameAqua, bundle: nil)
                headerBgColor = CashewColor.currentLineBackgroundColor()
            }
            
            // strongSelf.tabButton.appearance = appearance
            //  strongSelf.newIssueButton.appearance = appearance
            
            [strongSelf.headerView, strongSelf.footerView].forEach { (view) in
                view?.backgroundColor = headerBgColor
                //strongSelf.settingsButton.layer?.backgroundColor = headerBgColor.CGColor
                view?.shouldAllowVibrancy = false
            }
            
            strongSelf.settingsButton.image = NSImage(named: NSImage.Name(rawValue: "gear"))?.withTintColor(CashewColor.foregroundColor())
            
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
        filter.account = QContext.shared().currentAccount
        if  self.tabButton.selectedSegment == 0 {
            filter.filterType = SRFilterType_Notifications
        } else if self.tabButton.selectedSegment == 2 {
            filter.filterType = SRFilterType_Favorites
            
        } else if self.tabButton.selectedSegment == 1 {
            filter.filterType = SRFilterType_Search
            let currentUserId = QContext.shared().currentAccount.userId
            let account = QContext.shared().currentAccount;
            let currentUser = QOwnerStore.owner(forAccountId: account?.identifier, identifier: currentUserId)
            filter.assignees = NSOrderedSet(object: currentUser?.login)
            filter.states = NSOrderedSet(object: NSNumber(value: IssueStoreIssueState_Open))
        }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async(execute: {
            self.dataSource.fetchIssuesWithFilter(filter)
            DispatchQueue.main.async {
                // self.tableView.sizeToFit()
                //self.tableView.beginUpdates()
                self.tableView.reloadData()
                //self.tableView.endUpdates()
            }
        })
    }
    
    // MARK: Actions
    
    @IBAction func didClickCreateIssueButton(_ sender: AnyObject) {
        Analytics.logCustomEventWithName("Status Bar Did Click Create Issue Button", customAttributes: nil)
        if let didClickCreateIssueAction = self.didClickCreateIssueAction {
            didClickCreateIssueAction()
        }
    }
    
    @IBAction func didClickSettingsButton(_ sender: AnyObject) {
        
        guard let event = self.view.window?.currentEvent else { return }
        let menu = SRMenu()
        
        menu.addItem(NSMenuItem(title: "Open Cashew", action: #selector(StatusBarViewController.didClickShowAppButton(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(StatusBarViewController.didClickPreferencesButton(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Cashew", action: #selector(StatusBarViewController.didClickQuitButton(_:)), keyEquivalent: ""))
        
        menu.items.forEach { (menuitem) in
            menuitem.target = self
        }
        
        let pointInWindow = settingsButton.convert(CGPoint.zero, to: nil)
        let point = NSPoint(x: pointInWindow.x + settingsButton.frame.width - menu.size.width, y: pointInWindow.y - settingsButton.frame.height)
        if let windowNumber = view.window?.windowNumber, let popupEvent = NSEvent.mouseEvent(with: .leftMouseUp, location: point, modifierFlags: event.modifierFlags, timestamp: 0, windowNumber: windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0) {
            SRMenu.popUpContextMenu(menu, with: popupEvent, for: settingsButton)
        }
        
    }
    
    @objc
    fileprivate func didClickPreferencesButton(_ sender: AnyObject) {
        if let didClickPreferencesAction = didClickPreferencesAction {
            didClickPreferencesAction()
        }
    }
    
    @objc
    fileprivate func didClickQuitButton(_ sender: AnyObject) {
        if let didClickQuitAction = didClickQuitAction {
            didClickQuitAction()
        }
    }
    
    
    @objc
    fileprivate func didClickShowAppButton(_ sender: AnyObject) {
        if let didClickShowAppAction = didClickShowAppAction {
            didClickShowAppAction()
        }
    }
    
    @IBAction
    func didClickRefreshButton(_ sender: AnyObject) {
        Analytics.logCustomEventWithName("Status Bar Did Click Refresh Button", customAttributes: nil)
        refresh()
    }
    
    @IBAction
    func didClickOpenCashewAppStatusBarButton(_ sender: AnyObject) {
        Analytics.logCustomEventWithName("Status Bar Did Click Open Cashew App", customAttributes: nil)
        if let didClickShowAppAction = didClickShowAppAction {
            didClickShowAppAction()
        }
    }
    
    
    
    @IBAction
    func didClickSegmentatedControleButton(_ sender: AnyObject) {
        Analytics.logCustomEventWithName("Status Bar Did Select Tab", customAttributes: ["tabIndex": self.tabButton.selectedSegment as AnyObject])
        refresh()
    }
    
    @objc
    fileprivate func didSelectIssue(_ sender: AnyObject) {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 && selectedRow < dataSource.numberOfIssues() {
            let issue = dataSource.issueAtIndex(selectedRow)
            NotificationCenter.default.post(name: NSNotification.Name.openNewIssueDetailsWindow, object: issue)
        }
    }
}


extension StatusBarViewController: QIssuesViewDataSourceDelegate {
    
    func dataSource(_ dataSource: QIssuesViewDataSource?, didInsertIndexSet: IndexSet, forFilter: QIssueFilter) {
        
    }
    
    func dataSource(_ dataSource: QIssuesViewDataSource?, didDeleteIndexSet: IndexSet, forFilter: QIssueFilter) {
        
    }
}


extension StatusBarViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil;
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let issue = dataSource.issueAtIndex(row)
        let isRowSelected = tableView.selectedRowIndexes.contains(row)
        let cellIdentifier = "QIssueTableViewCell"
        let rowView: QIssueTableViewCell
        
        if let aRowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? QIssueTableViewCell {
            rowView = aRowView
        } else {
            let aRowView: QIssueTableViewCell = QIssueTableViewCell.instantiateFromNib()!
            rowView = aRowView
        }
        
        rowView.issue = issue
        rowView.isSelected = isRowSelected
        rowView.identifier = NSUserInterfaceItemIdentifier(rawValue: cellIdentifier)
        rowView.shouldAllowVibrancy = false
        
        return rowView
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return QIssueTableViewCell.suggestedHeight()
    }
    
}

extension StatusBarViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataSource.numberOfIssues()
    }
}
