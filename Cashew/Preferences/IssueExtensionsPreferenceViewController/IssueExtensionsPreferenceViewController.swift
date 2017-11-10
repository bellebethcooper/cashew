//
//  IssueExtensionsPreferenceViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/1/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
//import MASShortcut


class IssueExtensionsPreferenceViewController: NSViewController {
    
    @IBOutlet weak var clipView: BaseClipView!
    @IBOutlet weak var tableView: BaseTableView!
    @IBOutlet var addAccountButton: NSButton!
    @IBOutlet var removeAccountButton: NSButton!
    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var bottomBarContainerView: BaseView!
    
    private var windowControllers =  Set<BaseModalWindowController>()
    private let dataSource = IssueExtensionsDataSource()
    private let extensionCloudKitService = ExtensionCloudKitService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.disableThemeObserver = true
        tableView.backgroundColor = NSColor.whiteColor()
        
        clipView.disableThemeObserver = true
        clipView.backgroundColor = NSColor.whiteColor()
        
        bottomBarContainerView.disableThemeObserver = true
        bottomBarContainerView.backgroundColor = NSColor.whiteColor()
        
        //        bottomBarTopSeparatorView.disableThemeObserver = true
        //        bottomBarTopSeparatorView.backgroundColor = LightModeColor.sharedInstance.separatorColor()
        
        removeAccountButton.enabled = false
        
        //QAccountStore.addObserver(self)
        //tableView.registerAdapter(AccountsPreferenceTableViewAdapter(), forClass: QAccount.self)
        
        tableView.action = #selector(IssueExtensionsPreferenceViewController.didSelectRow)
        tableView.doubleAction = #selector(IssueExtensionsPreferenceViewController.didDoubleClickRow)
        tableView.target = self;
        
        
        containerView.wantsLayer = true
        containerView.layer?.borderColor = NSColor(calibratedWhite: 164/255.0, alpha: 1).CGColor
        containerView.layer?.borderWidth = 1
        
        dataSource.reloadData() { [weak self] in
            DispatchOnMainQueue({
                self?.tableView.reloadData()
            })
        }
        extensionCloudKitService.syncCodeExtensions { [weak self] (extensions, err) in
            DispatchOnMainQueue({
                self?.tableView.reloadData()
            })
        }
        
        dataSource.onRecordDeletion = {  [weak self] (record, index) in
            guard let strongSelf = self else { return }
            DispatchOnMainQueue({
                strongSelf.tableView.beginUpdates()
                strongSelf.tableView.removeRowsAtIndexes(NSIndexSet(index: index), withAnimation: .EffectNone)
                strongSelf.tableView.endUpdates()
            })
        }
        
        dataSource.onRecordInsertion = {  [weak self] (record, index) in
            guard let strongSelf = self else { return }
            DispatchOnMainQueue({
                strongSelf.tableView.beginUpdates()
                strongSelf.tableView.insertRowsAtIndexes(NSIndexSet(index: index), withAnimation: .EffectNone)
                strongSelf.tableView.endUpdates()
            })
        }
        
        dataSource.onRecordUpdate = {  [weak self] (record, index) in
            guard let strongSelf = self else { return }
            DispatchOnMainQueue({
                let columnIndexSet = NSMutableIndexSet()
                columnIndexSet.addIndex(0)
//                columnIndexSet.addIndex(1)
                strongSelf.tableView.beginUpdates()
                strongSelf.tableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes: columnIndexSet) //RowsAtIndexes(NSIndexSet(index: index), withAnimation: .EffectNone)
                strongSelf.tableView.endUpdates()
            })
        }
    }
    
    // MARK: Actions
    
    @objc
    private func didSelectRow() {
        let selectedRow = tableView.clickedRow
        if selectedRow >= 0 {
            removeAccountButton.enabled = true
        } else {
            removeAccountButton.enabled = false
        }
    }
    
    @objc
    private func didDoubleClickRow() {
        let selectedRow = tableView.clickedRow
        let selectedColumn = tableView.clickedColumn
        
        if selectedRow >= 0 && selectedColumn == 0 {
            let codeExtension = self.dataSource.itemAtIndex(selectedRow)
            openEditorWithCodeExtensionScript(codeExtension)
        } /* else if selectedRow >= 0 && selectedColumn == 1 {
            //            if let view = tableView.makeViewWithIdentifier(tableColumn.identifier, owner: self) as? NSTableCellView, textField = view.textField {
            //                let codeExtension = self.dataSource.itemAtIndex(row)
            //                textField.stringValue = codeExtension.keyboardShortcut ?? ""
            //                return view
            //            }
            
            if let view = tableView.viewAtColumn(selectedColumn, row: selectedRow, makeIfNecessary: true) as? NSTableCellView, textField = view.textField {
                //                textField.editable = true
                //                self.view.window?.makeFirstResponder(textField)
                
                
            }
            
        } */
    }
    
    @IBAction func didClickAddButton(sender: AnyObject) {
        openEditorWithCodeExtensionScript(nil)
    }
    
    @IBAction func didClickRemoveButton(sender: AnyObject) {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else { return }
        
        let codeExtension = self.dataSource.itemAtIndex(selectedRow)
        NSAlert.showWarningMessage("Are you sure you want to delete \"\(codeExtension.name)\" extension?") {
            self.extensionCloudKitService.deleteCodeExtension(codeExtension) { (result, err) in
                DDLogDebug("Delete result \(result) error \(err)")
            }
        }
    }
    
    private func openEditorWithCodeExtensionScript(codeExtension: SRExtension?) {
        var existingWindowController: BaseModalWindowController?
        
        for controller in windowControllers {
            if let viewController = controller.viewController as? IssueExtensionCodeEditorViewController where viewController.codeExtension == codeExtension {
                existingWindowController = controller
                break
            }
        }
        
        guard existingWindowController == nil else {
            existingWindowController?.window?.makeKeyAndOrderFront(nil)
            return;
        }
        
        
        guard let viewController = IssueExtensionCodeEditorViewController(nibName: "IssueExtensionCodeEditorViewController", bundle: nil) else { return }
        //guard let  else { return }
        let windowController = BaseModalWindowController(windowNibName: "BaseModalWindowController")
        windowController.forceAlwaysDarkmode = true
        windowController.windowTitle = "Issue Extension Code Editor"
        windowController.viewController = viewController
        windowController.showMiniaturizeButton = true
        windowController.showZoomButton = true
        
        //windowController.baseModalWindowControllerDelegate = self
        windowControllers.insert(windowController)
        
        let mainAppWindow = NSApp.windows[0];
        let windowSize = NSMakeSize(800, 600)
        let windowLeft = mainAppWindow.frame.minX + mainAppWindow.frame.width / 2.0 - windowSize.width / 2.0
        let windowTop = mainAppWindow.frame.minY + mainAppWindow.frame.height / 2.0 - windowSize.height / 2.0
        
        if let window = windowController.window {
            let rect = NSMakeRect(windowLeft, windowTop, windowSize.width, windowSize.height)
            window.setFrame(rect, display: true)
            window.minSize = windowSize
            window.delegate = self
        }
        
        windowController.window?.makeKeyAndOrderFront(nil)
        
        viewController.codeExtension = codeExtension
    }
}

extension IssueExtensionsPreferenceViewController: NSWindowDelegate {
    
    func windowShouldClose(sender: AnyObject) -> Bool {
        
        var aWindowController: BaseModalWindowController?
        for controller in windowControllers {
            if let sender = sender as? NSWindow where controller.window == sender {
                aWindowController = controller
                break
            }
        }
        
        guard let windowController = aWindowController, viewController = windowController.viewController as? IssueExtensionCodeEditorViewController else { return true }
        
        var shouldClose = true
        if viewController.code != viewController.codeExtension?.sourceCode {
            
            shouldClose = false
            if  NSUserDefaults.shouldShowIssueCloseWarning() {
                NSAlert.showWarningMessage("Are you sure you want to close without saving?") {
                    shouldClose = true
                }
            } else {
                shouldClose = true
            }

        }
        return shouldClose;
    }
    
    func windowWillClose(notification: NSNotification) {
        var aWindowController: BaseModalWindowController?
        for controller in windowControllers {
            if let sender = notification.object as? NSWindow where controller.window == sender {
                aWindowController = controller
                break
            }
        }
        
        guard let windowController = aWindowController else { return }
        
        self.windowControllers.remove(windowController)
        
    }
    
}

extension IssueExtensionsPreferenceViewController: NSTableViewDelegate {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return dataSource.numberOfRows
    }
    
}

extension IssueExtensionsPreferenceViewController: NSTableViewDataSource {
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let tableColumn = tableColumn else {
            return nil
        }
        
        if tableColumn.identifier == "ScriptNameId" {
            
            if let view = tableView.makeViewWithIdentifier(tableColumn.identifier, owner: self) as? NSTableCellView, textField = view.textField {
                let codeExtension = self.dataSource.itemAtIndex(row)
                textField.stringValue = codeExtension.name
                return view
            }
            
            
        } /* else if tableColumn.identifier == "KeyboardShortcutId" {
            
            if let view = tableView.makeViewWithIdentifier(tableColumn.identifier, owner: self) as? KeyboardShortcutTableCellView {
                let codeExtension = self.dataSource.itemAtIndex(row)
                view.codeExtension = codeExtension
                view.onShortcutChange = { [weak self] (ext, kb) in
                    guard let strongSelf = self else { return }
                    strongSelf.extensionCloudKitService.saveCodeExtension(ext.sourceCode, name: ext.name, recordNameId: ext.externalId, keyboardShortcut: kb, extensionType: ext.extensionType, onCompletion: { (obj, err) in
                        if err != nil {
                            DDLogDebug("Did save -> \(obj) err \(err)")
                        }
                    })
                }
                return view
            }
            
            
        } */
        
        return nil
    }
}

//
//@objc(SRKeyboardShortcutTableCellView)
//class KeyboardShortcutTableCellView: NSTableCellView {
//    
//    @IBOutlet var shortcutRecorderView: MASShortcutView!
//    private static let separator = String(UnicodeScalar(12))
//    
//    var codeExtension: SRExtension? {
//        didSet {
//            if let codeExtension = codeExtension where oldValue?.keyboardShortcut != codeExtension.keyboardShortcut {
//                let pieces = (codeExtension.keyboardShortcut ?? "").componentsSeparatedByString(KeyboardShortcutTableCellView.separator)
//                if  pieces.count == 3 {
//                    if let keyCode = UInt(pieces[1]), modifierKeys = UInt(pieces[0]) {
//                        shortcutRecorderView.shortcutValue = MASShortcut(keyCode: keyCode, modifierFlags: modifierKeys)
//                    } else {
//                        shortcutRecorderView.shortcutValue = nil
//                    }
//                } else {
//                    shortcutRecorderView.shortcutValue = nil
//                }
//            }
//        }
//    }
//    var onShortcutChange: ( (SRExtension, String) -> Void )?
//    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        
//        shortcutRecorderView.style = MASShortcutViewStyleFlat
//        shortcutRecorderView.shortcutValueChange = { [weak self] (view) in
//            guard let strongSelf = self, codeExtension = strongSelf.codeExtension, onShortcutChange = strongSelf.onShortcutChange else { return }
//            let keyboardShortcut: String
//            if let shortcutValue = view.shortcutValue {
//                keyboardShortcut = "\(shortcutValue.modifierFlags)\(KeyboardShortcutTableCellView.separator)\(shortcutValue.keyCode)\(KeyboardShortcutTableCellView.separator)\(shortcutValue.keyCodeStringForKeyEquivalent)"
//            } else {
//                keyboardShortcut = ""
//            }
//            
//            DDLogDebug("keyboardShortcut -> \(keyboardShortcut)")
//            onShortcutChange(codeExtension, keyboardShortcut)
//        }
//        
//    }
//    
//}


