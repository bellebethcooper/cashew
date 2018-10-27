//
//  SearchablePickerViewController.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class SearchableScrollView: BaseScrollView {
    override class var isCompatibleWithResponsiveScrolling: Bool {
        return true
    }
}

@objc(SRSearchablePickerViewController)
class SearchablePickerViewController: BaseViewController {
    
    fileprivate static let pickerSearchFieldHeight: CGFloat = 45.0
    fileprivate static let pickerToolbarViewHeight: CGFloat = 24.0
    fileprivate static let padding: CGFloat = 6.0
    fileprivate static let leftSpacing: CGFloat = 8.0
    fileprivate static let rightSpacing: CGFloat = 8.0
    fileprivate static let footerHeight: CGFloat = 35.0
    fileprivate static let doneButtonSize = CGSize(width: 80, height: 24)
    fileprivate static let buttonHorizontalPadding: CGFloat = 6.0
    fileprivate static let buttonVerticalPadding: CGFloat = 3.0
    
    let repositoryPopupButton = RepositoriesMenuButton()
    let pickerSearchField: PickerSearchField
    // private let pickerToolbarView: PickerToolbarView
    fileprivate let bottomDividerView = BaseSeparatorView()
    fileprivate let topDividerView = BaseSeparatorView()
    fileprivate let tableView = SearchablePickerTableView()
    fileprivate let doneButton = BaseButton.greenButton()
    fileprivate let cancelButton = BaseButton.whiteButton()
    fileprivate let tableViewScrollView = SearchableScrollView()
    fileprivate let selectionCountButton: BaseImageLabelButton
    fileprivate let progressIndicator = NSProgressIndicator()
    fileprivate(set) var dirtyFlag: Bool = false
    
    fileprivate let searchCoalescer = Coalescer(interval: 0.3, name: "co.cashewapp.Coalescer.accessQueue.SearchablePickerViewController.searchCoalescer")
    
    var allowMultiSelection: Bool = true
    var disableButtonIfNoSelection = true
    var onDoneButtonClick: (()->())? {
        didSet {
            if let onDoneButtonClick = onDoneButtonClick {
                doneButton.onClick = onDoneButtonClick                
            }
        }
    }
    
    var onTappedItemBlock: ((_ cell: AnyObject, _ item: AnyObject) -> ())?
    
    var showNumberOfSelections: Bool = false {
        didSet {
            view.needsLayout = true
            view.layoutSubtreeIfNeeded()
        }
    }
    
    var loading: Bool = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.loading {
                    strongSelf.progressIndicator.isHidden = false
                    strongSelf.selectionCountButton.userInteractionEnabled = false
                    strongSelf.doneButton.enabled = false
                    strongSelf.cancelButton.enabled = false
                    strongSelf.pickerSearchField.userInteractionEnabled = false
                    strongSelf.tableView.isEnabled = false
                    strongSelf.progressIndicator .startAnimation(nil)
                } else {
                    strongSelf.selectionCountButton.userInteractionEnabled = true
                    strongSelf.doneButton.enabled = true
                    strongSelf.cancelButton.enabled = true
                    strongSelf.pickerSearchField.userInteractionEnabled = true
                    strongSelf.tableView.isEnabled = true
                    strongSelf.progressIndicator .stopAnimation(nil)
                    strongSelf.progressIndicator.isHidden = true
                }
                strongSelf.view.needsLayout = true
                strongSelf.view.layoutSubtreeIfNeeded()
            }
        }
    }
    
    func reloadData() {
        loading = true
        
        let block: ()->() = { [weak self] in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
                strongSelf.updateDoneButtonState()
                strongSelf.updateSelectionCountButton()
                strongSelf.updateRepositoryList()
                strongSelf.loading = false
            }
        }
        
        searchCoalescer.executeBlock {  [weak self] in
            guard let strongSelf = self else { return }
            if (strongSelf.pickerSearchField.text as NSString).trimmedString().length > 0 {
                strongSelf.dataSource.search(strongSelf.pickerSearchField.text, onCompletion: block)
            } else {
                strongSelf.dataSource.defaults(block)
            }
        }
        
        
    }
    
    // private var selectedIndices = NSMutableIndexSet()
    fileprivate var registeredAdapters = [String: SearchablePickerTableAdapter]()
    
    let viewModel: SearchablePickerViewModel
    var dataSource: SearchablePickerDataSource
    
    
    var popoverBackgroundColorFixEnabed = true {
        didSet {
            if let view = self.view as? BaseView {
                view.popoverBackgroundColorFixEnabed = popoverBackgroundColorFixEnabed
            }
        }
    }
    
    @objc
    required init(viewModel: SearchablePickerViewModel, dataSource: SearchablePickerDataSource) {
        self.viewModel = viewModel
        self.dataSource = dataSource
        
        pickerSearchField = PickerSearchField(viewModel: viewModel.pickerSearchFieldViewModel)
        
        selectionCountButton = BaseImageLabelButton(viewModel: BaseImageLabelButtonViewModel(image: NSImage(named:NSImage.Name(rawValue: "chevron-down"))!.withTintColor(BaseImageLabelButton.foregroundColor), label: "0 SELECTED", buttonType: .rightImage));
        
        super.init(nibName: nil, bundle: nil)
        view.addSubview(selectionCountButton)
        
        let recognizer = NSClickGestureRecognizer(target: self, action: #selector(SearchablePickerViewController.didClickSelectionCount))
        
        recognizer.numberOfClicksRequired = 1;
        selectionCountButton.addGestureRecognizer(recognizer)
        updateSelectionCountButton()
    }
    
    @objc
    fileprivate func didClickSelectionCount() {
        guard let event = NSApp.currentEvent else { return }
        let menu = SRMenu()
        
        let showSelecteMenuItem = NSMenuItem(title: "Show selection", action: #selector(SearchablePickerViewController.didClickShowSelected), keyEquivalent: "")
        menu.addItem(showSelecteMenuItem)
        
        let clearSelection = NSMenuItem(title: "Clear selection", action: #selector(SearchablePickerViewController.didClickClearSelection), keyEquivalent: "")
        menu.addItem(clearSelection)
        
        //[SRMenu popUpContextMenu:menu withEvent:[NSApp  currentEvent] forView:self.accountNamePopUpButton];
        SRMenu.popUpContextMenu(menu, with: event, for: selectionCountButton)
    }
    
    @objc
    fileprivate func didClickShowSelected() {
        dataSource.mode = .selectedItems
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc
    fileprivate func didClickClearSelection() {
        dataSource.clearSelection()
        showDefaults()
        dirtyFlag = true
        if dataSource.allowResetToOriginal {
            cancelButton.isHidden = false
            view.needsLayout = true
            view.layoutSubtreeIfNeeded()
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View Lifecycle

    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    override func viewDidLoad() {
        // NotificationCenter.default.addObserver(self, selector: #selector(SearchablePickerViewController.issueSelectionChanged(_:)), name: kQContextIssueSelectionChangeNotification, object: nil)
        super.viewDidLoad()
        
        if let view = self.view as? BaseView {
            view.popoverBackgroundColorFixEnabed = popoverBackgroundColorFixEnabed
        }
        
        setupPickerSearchField()
        setupDividerViews()
        setupTableView()
        setupDoneButton()
        setupProgressIndicator()
        setupRepositoryPopupButton()
        showDefaults()
        setupCancelButton()
        setupThemeObserver()
    }
    
    override func viewDidLayout() {
        
        if showNumberOfSelections {
            selectionCountButton.isHidden = false
            let suggestedSize = selectionCountButton.suggestedSize()
            selectionCountButton.frame = CGRectIntegralMake(x: view.bounds.width - suggestedSize.width, y: -1, width: suggestedSize.width, height: SearchablePickerViewController.pickerSearchFieldHeight)
            pickerSearchField.frame = CGRectIntegralMake(x: 0, y: 0, width: view.bounds.width - selectionCountButton.frame.width, height: SearchablePickerViewController.pickerSearchFieldHeight);
        } else {
            selectionCountButton.isHidden  = true
            pickerSearchField.frame = CGRectIntegralMake(x: 0, y: 0, width: view.bounds.width, height: SearchablePickerViewController.pickerSearchFieldHeight);
        }
        // topDividerView.frame = CGRectIntegralMake(x: 0, y: pickerSearchField.frame.maxY, width: view.bounds.width , height: 1)
        // pickerToolbarView.frame = CGRectIntegralMake(x: 0, y: topDividerView.frame.maxY, width: view.bounds.width, height: SearchablePickerViewController.pickerToolbarViewHeight);
        topDividerView.frame = CGRectIntegralMake(x: 0, y: pickerSearchField.frame.maxY, width: view.bounds.width , height: 1)
        tableViewScrollView.frame = CGRectIntegralMake(x: 0, y: topDividerView.frame.maxY, width: view.bounds.width, height: view.bounds.height - topDividerView.frame.maxY - SearchablePickerViewController.footerHeight)
        
        bottomDividerView.frame = CGRectIntegralMake(x: 0, y: tableViewScrollView.frame.maxY, width: view.bounds.width , height: 1)
        
        
        let doneButtonLeft = view.bounds.width - SearchablePickerViewController.padding - SearchablePickerViewController.doneButtonSize.width
        doneButton.frame = CGRectIntegralMake(x: doneButtonLeft, y: bottomDividerView.frame.maxY +  (SearchablePickerViewController.footerHeight / 2.0 - SearchablePickerViewController.doneButtonSize.height / 2.0), width: SearchablePickerViewController.doneButtonSize.width, height: SearchablePickerViewController.doneButtonSize.height)
        
        let cancelButtonWidth = SearchablePickerViewController.doneButtonSize.width
        let cancelButtonLeft = doneButton.frame.minX - cancelButtonWidth - SearchablePickerViewController.rightSpacing
        let cancelButtonHeight = SearchablePickerViewController.doneButtonSize.height
        cancelButton.frame = CGRectIntegralMake(x: cancelButtonLeft, y: doneButton.frame.minY , width: cancelButtonWidth, height: cancelButtonHeight)
        
        if cancelButton.isHidden {
            let progressIndicatorTop = bottomDividerView.frame.maxY +  (SearchablePickerViewController.footerHeight / 2.0 - 20 / 2.0)
            progressIndicator.frame = CGRectIntegralMake(x: doneButton.frame.minX - SearchablePickerViewController.padding - 20, y: progressIndicatorTop, width: 20, height: 20)
        } else {
            let progressIndicatorTop = bottomDividerView.frame.maxY +  (SearchablePickerViewController.footerHeight / 2.0 - 20 / 2.0)
            progressIndicator.frame = CGRectIntegralMake(x: cancelButton.frame.minX - SearchablePickerViewController.padding - 20, y: progressIndicatorTop, width: 20, height: 20)
        }
        
        
        updateRepositoryList()
        
        super.viewDidLayout()
    }
    
    // MARK: Setup
    
    fileprivate func setupThemeObserver() {
        
        if let view = self.view as? BaseView {
            view.disableThemeObserver = true
            view.shouldAllowVibrancy = false
            
            if UserDefaults.themeMode() == .dark {
                view.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                view.backgroundColor = CashewColor.backgroundColor()
            }
            
            selectionCountButton.backgroundColor = view.backgroundColor
            tableView.backgroundColor = view.backgroundColor
            tableViewScrollView.backgroundColor = view.backgroundColor
        }
        
        tableView.disableThemeObserver = true
        tableViewScrollView.disableThemeObserver = true
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self, let view = strongSelf.view as? BaseView else {
                return
            }
            
            if mode == .dark {
                view.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
                //let appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
                //strongSelf.progressIndicator.appearance = appearance
            } else {
                view.backgroundColor = CashewColor.backgroundColor()
                //let appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
                //strongSelf.progressIndicator.appearance = appearance
            }
            
            strongSelf.tableView.backgroundColor = view.backgroundColor
            strongSelf.tableViewScrollView.backgroundColor = view.backgroundColor
            strongSelf.selectionCountButton.backgroundColor = view.backgroundColor
        }
    }
    
    fileprivate func updateRepositoryList() {
        if dataSource.listOfRepositories.count > 1 {
            repositoryPopupButton.repositories = dataSource.listOfRepositories
            repositoryPopupButton.isHidden = false
            repositoryPopupButton.sizeToFit()
            repositoryPopupButton.frame = CGRectIntegralMake(x: SearchablePickerViewController.padding, y: doneButton.frame.minY, width: min(repositoryPopupButton.frame.width, cancelButton.frame.minX - 12), height: doneButton.frame.height)
        } else {
            repositoryPopupButton.isHidden = true
        }
    }
    
    fileprivate func setupPickerSearchField() {
        guard pickerSearchField.superview == nil else { return }
        view.addSubview(pickerSearchField)
        
        pickerSearchField.onTextChange = { [weak self] in
            guard let strongSelf = self else { return }
            let query = strongSelf.pickerSearchField.text
            
            guard (query as NSString).trimmedString().length > 0 else {
                strongSelf.showDefaults()
                return
            }
            
            strongSelf.loading = true
            strongSelf.searchCoalescer.executeBlock {
                strongSelf.dataSource.search(query, onCompletion: {
                    
                    DispatchOnMainQueue({
                        strongSelf.tableView.reloadData()
                        strongSelf.updateDoneButtonState()
                        strongSelf.loading = false
                    });
                })
            }
        }
    }
    
    
    fileprivate func setupDividerViews() {
        guard topDividerView.superview == nil && bottomDividerView.superview == nil else { return }
        
        [topDividerView, bottomDividerView].forEach { (dividerView) in
            view.addSubview(dividerView)
            //dividerView.backgroundColor = SearchablePickerViewController.dividerColor
        }
    }
    
    fileprivate func setupProgressIndicator() {
        progressIndicator.style = .spinning
        view.addSubview(progressIndicator)
        progressIndicator.isHidden = true
    }
    
    fileprivate func setupDoneButton() {
        guard doneButton.superview == nil else { return }
        view.addSubview(doneButton)
        
        doneButton.text = "Save"
        if let onDoneButtonClick = onDoneButtonClick {
            doneButton.onClick = onDoneButtonClick
        }
        updateDoneButtonState()
    }
    
    fileprivate func setupCancelButton() {
        guard cancelButton.superview == nil else { return }
        view.addSubview(cancelButton)
        cancelButton.isHidden = true
        cancelButton.text = "Discard"
        cancelButton.onClick = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.resetSelectionToOriginal(strongSelf.dataSource.repository)
        }
    }
    
    func resetSelectionToOriginal(_ repository: QRepository?) {
        DispatchQueue.main.async {
            
            let strongSelf = self
            let repo = repository ?? strongSelf.dataSource.repository
            
            strongSelf.cancelButton.isHidden = true
            strongSelf.dirtyFlag = false
            strongSelf.dataSource.resetToOriginal()
            strongSelf.dataSource.repository = repo
            strongSelf.dataSource.mode = .defaultResults
            strongSelf.reloadData()
            strongSelf.view.needsLayout = true
            strongSelf.view.layoutSubtreeIfNeeded()
            strongSelf.tableView.scroll(CGPoint.zero)
        }
    }
    
    fileprivate func setupRepositoryPopupButton() {
        guard repositoryPopupButton.superview == nil else { return }
        view.addSubview(repositoryPopupButton)
        
        repositoryPopupButton.onRepoChange = { [weak self] in
            assert(Thread.isMainThread)
            guard let strongSelf = self, let repo = strongSelf.repositoryPopupButton.currentRepository else { return }
            strongSelf.dataSource.repository = repo
            strongSelf.showDefaults()
            
        }
    }
    
    fileprivate func updateDoneButtonState() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            if strongSelf.disableButtonIfNoSelection {
                strongSelf.doneButton.enabled = (strongSelf.dataSource.selectionCount > 0)
            } else {
                strongSelf.doneButton.enabled = true
            }
        }
    }
    
    fileprivate func showDefaults() {
        dataSource.mode = .defaultResults
        searchCoalescer.executeBlock {  [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.dataSource.defaults {
                DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
                //strongSelf.tableView.selectRowIndexes(strongSelf.dataSource.selectedIndexes, byExtendingSelection: false)
                strongSelf.updateDoneButtonState()
                }
            }
        }
    }
    
    fileprivate func setupTableView() {
        guard tableViewScrollView.superview == nil else { return }
        view.addSubview(tableViewScrollView)
        tableViewScrollView.documentView = tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.allowsMultipleSelection = false
        
        // tableView.action = #selector(SearchablePickerViewController.didClickRow(_:))
        // tableView.target = self
        tableView.onRowClick = { [weak self] (index) in
            guard let strongSelf = self else  { return }
            if let cell = strongSelf.tableView.rowView(atRow: index, makeIfNecessary: true) as? BaseTableRowView {
                if strongSelf.dataSource.allowResetToOriginal {
                    strongSelf.cancelButton.isHidden = false
                    strongSelf.view.needsLayout = true
                    strongSelf.view.layoutSubtreeIfNeeded()
                }
                strongSelf.dirtyFlag = true
                
                
                //strongSelf.selectedIndices.addIndex(index)
                if !strongSelf.allowMultiSelection {
                    if cell.checked {
                        strongSelf.dataSource.unselectItem(strongSelf.dataSource.itemAtIndex(index))
                    } else {
                        strongSelf.dataSource.selectItem(strongSelf.dataSource.itemAtIndex(index))
                    }
                } else {
                    if cell.checked {
                        //strongSelf.selectedIndices.removeIndex(index)
                        strongSelf.dataSource.unselectItem(strongSelf.dataSource.itemAtIndex(index))
                    } else {
                        strongSelf.dataSource.selectItem(strongSelf.dataSource.itemAtIndex(index))
                    }
                }
                
                if let onTappedItemBlock = strongSelf.onTappedItemBlock {
                    onTappedItemBlock(cell, strongSelf.dataSource.itemAtIndex(index))
                    
                    if strongSelf.allowMultiSelection == false {
                        for i in 0..<strongSelf.dataSource.numberOfRows {
                            if let otherCell = strongSelf.tableView.rowView(atRow: i, makeIfNecessary: false) as? BaseTableRowView {
                                otherCell.checked = (i == index) ? strongSelf.dataSource.isSelectedItem(strongSelf.dataSource.itemAtIndex(index)) : false
                            }
                        }
                    }
                } else {
                    cell.checked = !cell.checked
                }
                
                cell.needsDisplay = true
                cell.needsLayout = true
                cell.layoutSubtreeIfNeeded()
                
                DispatchQueue.main.async(execute: {
                    strongSelf.updateSelectionCountButton()
                    strongSelf.updateDoneButtonState()
                })
            }
        }
    }
    
    fileprivate func updateSelectionCountButton() {
        selectionCountButton.viewModel.label = ""
        /*
         let selectionCount = dataSource.selectionCount
         if selectionCount == 0 {
         selectionCountButton.viewModel.label = "O SELECTED"
         } else {
         selectionCountButton.viewModel.label = "\(selectionCount) SELECTED"
         }*/
    }
    
    
    
    @objc
    func registerAdapter(_ adapter: SearchablePickerTableAdapter, clazz: AnyClass) {
        registeredAdapters[NSStringFromClass(clazz)] = adapter
    }
    
    func syncIssueEventsForIssue(_ issue: QIssue, sinceDate: Date) {
        let service = QIssuesService(for: issue.account)
        service.fetchAllIssuesEvents(for: issue.repository, issueNumber: issue.number, pageNumber: 1, since: sinceDate) { (events, context, err) in
            guard let events = events as? [QIssueEvent] , err == nil else { return }
            events.forEach({ (event) in
                QIssueEventStore.save(event)
            })
        }
    }
    
}


extension SearchablePickerViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return nil;
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        if row > dataSource.numberOfRows - 1 {
            return nil
        }
        
        let item: NSObject = dataSource.itemAtIndex(row) as! NSObject
        let reuseId = type(of: item).description()
        guard let adapter = registeredAdapters[reuseId] else { return nil }
        
        if let rowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: reuseId), owner: self) as? NSTableRowView {
            return adapter.adapt(rowView, item: item, index: row)
        } else {
            return adapter.adapt(nil, item: item, index: row)
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let item: NSObject = dataSource.itemAtIndex(row) as! NSObject
        let reuseId = type(of: item).description()
        guard let adapter = registeredAdapters[reuseId] else { return 0 }
        
        return adapter.height
    }
    
    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        //dataSource.selectedIndices = selectedIndices.copy() as! NSIndexSet
        return dataSource.selectedIndexes
    }
    
}

extension SearchablePickerViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataSource.numberOfRows
    }
}


private class SearchablePickerTableView: BaseTableView {
    
    var onRowClick: ((Int) -> ())?
    
    override func mouseDown(with theEvent: NSEvent) {
        let globalLocation: NSPoint = theEvent.locationInWindow
        let localLocation = self.convert(globalLocation, from: nil)
        let clickedRow = self.row(at: localLocation)
        
        if let onRowClick = onRowClick {
            if (clickedRow != -1) {
                onRowClick(clickedRow)
            }
        }
        
        super.mouseDown(with: theEvent)
    }
}


@objc(SRSearchablePickerViewModel)
class SearchablePickerViewModel: NSObject {
    let pickerSearchFieldViewModel: PickerSearchFieldViewModel
    //  let pickerToolbarViewModel: PickerToolbarViewModel
    
    required init(pickerSearchFieldViewModel: PickerSearchFieldViewModel) {//, pickerToolbarViewModel: PickerToolbarViewModel) {
        // self.pickerToolbarViewModel = pickerToolbarViewModel
        self.pickerSearchFieldViewModel = pickerSearchFieldViewModel
        super.init()
    }
}

@objc(SRSearchablePickerTableAdapter)
protocol SearchablePickerTableAdapter: NSObjectProtocol {
    var height: CGFloat { get }
    func adapt(_ view: NSTableRowView?, item: AnyObject, index: Int) -> NSTableRowView?
}

@objc(SRSearchablePickerDataSourceMode)
enum SearchablePickerDataSourceMode: NSInteger {
    case selectedItems;
    case searchResults;
    case defaultResults;
}

@objc(SRSearchablePickerDataSource)
protocol SearchablePickerDataSource: NSObjectProtocol {
    var sourceIssue: QIssue? { get set }
    var mode: SearchablePickerDataSourceMode { get set }
    var numberOfRows: Int { get }
    var selectedIndexes: IndexSet { get }
    var selectionCount: Int { get }
    var repository: QRepository? { get set }
    var listOfRepositories: [QRepository] { get }
    var allowResetToOriginal: Bool { get }
    
    func itemAtIndex(_ index: Int) -> AnyObject
    func search(_ string: String, onCompletion: @escaping ()->())
    func defaults(_ onCompletion: @escaping ()->())
    func selectItem(_ item: AnyObject)
    func unselectItem(_ item: AnyObject)
    func isSelectedItem(_ item: AnyObject) -> Bool
    func clearSelection()
    func resetToOriginal()
    
}

