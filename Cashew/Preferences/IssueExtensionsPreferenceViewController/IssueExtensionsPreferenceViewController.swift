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
    
    fileprivate var windowControllers =  Set<BaseModalWindowController>()
    fileprivate let dataSource = IssueExtensionsDataSource()
    fileprivate let extensionCloudKitService = ExtensionCloudKitService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.disableThemeObserver = true
        tableView.backgroundColor = NSColor.white
        
        clipView.disableThemeObserver = true
        clipView.backgroundColor = NSColor.white
        
        bottomBarContainerView.disableThemeObserver = true
        bottomBarContainerView.backgroundColor = NSColor.white
        
        //        bottomBarTopSeparatorView.disableThemeObserver = true
        //        bottomBarTopSeparatorView.backgroundColor = LightModeColor.sharedInstance.separatorColor()
        
        removeAccountButton.isEnabled = false
        
        //QAccountStore.add(self)
        //tableView.registerAdapter(AccountsPreferenceTableViewAdapter(), forClass: QAccount.self)
        
        tableView.action = #selector(IssueExtensionsPreferenceViewController.didSelectRow)
        tableView.doubleAction = #selector(IssueExtensionsPreferenceViewController.didDoubleClickRow)
        tableView.target = self;
        
        
        containerView.wantsLayer = true
        containerView.layer?.borderColor = NSColor(calibratedWhite: 164/255.0, alpha: 1).cgColor
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
                strongSelf.tableView.removeRows(at: NSIndexSet(index: index) as IndexSet, withAnimation: [])
                strongSelf.tableView.endUpdates()
            })
        }
        
        dataSource.onRecordInsertion = {  [weak self] (record, index) in
            guard let strongSelf = self else { return }
            DispatchOnMainQueue({
                strongSelf.tableView.beginUpdates()
                strongSelf.tableView.insertRows(at: NSIndexSet(index: index) as IndexSet, withAnimation: [])
                strongSelf.tableView.endUpdates()
            })
        }
        
        dataSource.onRecordUpdate = {  [weak self] (record, index) in
            guard let strongSelf = self else { return }
            DispatchOnMainQueue({
                let columnIndexSet = NSMutableIndexSet()
                columnIndexSet.add(0)
//                columnIndexSet.addIndex(1)
                strongSelf.tableView.beginUpdates()
                strongSelf.tableView.reloadData(forRowIndexes: NSIndexSet(index: index) as IndexSet, columnIndexes: columnIndexSet as IndexSet) //RowsAtIndexes(NSIndexSet(index: index), withAnimation: .EffectNone)
                strongSelf.tableView.endUpdates()
            })
        }
    }
    
    // MARK: Actions
    
    @objc
    fileprivate func didSelectRow() {
        let selectedRow = tableView.clickedRow
        if selectedRow >= 0 {
            removeAccountButton.isEnabled = true
        } else {
            removeAccountButton.isEnabled = false
        }
    }
    
    @objc
    fileprivate func didDoubleClickRow() {
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
    
    @IBAction func didClickAddButton(_ sender: AnyObject) {
        openEditorWithCodeExtensionScript(nil)
    }
    
    @IBAction func didClickRemoveButton(_ sender: AnyObject) {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else { return }
        
        let codeExtension = self.dataSource.itemAtIndex(selectedRow)
        NSAlert.showWarningMessage("Are you sure you want to delete \"\(codeExtension.name)\" extension?") {
            self.extensionCloudKitService.deleteCodeExtension(codeExtension) { (result, err) in
                DDLogDebug("Delete result \(result) error \(err)")
            }
        }
    }
    
    fileprivate func openEditorWithCodeExtensionScript(_ codeExtension: SRExtension?) {
        var existingWindowController: BaseModalWindowController?
        
        for controller in windowControllers {
            if let viewController = controller.viewController as? IssueExtensionCodeEditorViewController , viewController.codeExtension == codeExtension {
                existingWindowController = controller
                break
            }
        }
        
        guard existingWindowController == nil else {
            existingWindowController?.window?.makeKeyAndOrderFront(nil)
            return;
        }
        
        
        let viewController = IssueExtensionCodeEditorViewController(nibName: "IssueExtensionCodeEditorViewController", bundle: nil)
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
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        
        var aWindowController: BaseModalWindowController?
        for controller in windowControllers {
            if let sender = sender as? NSWindow , controller.window == sender {
                aWindowController = controller
                break
            }
        }
        
        guard let windowController = aWindowController, let viewController = windowController.viewController as? IssueExtensionCodeEditorViewController else { return true }
        
        var shouldClose = true
        if viewController.code != viewController.codeExtension?.sourceCode {
            
            shouldClose = false
            if  UserDefaults.shouldShowIssueCloseWarning() {
                NSAlert.showWarningMessage("Are you sure you want to close without saving?") {
                    shouldClose = true
                }
            } else {
                shouldClose = true
            }

        }
        return shouldClose;
    }
    
    func windowWillClose(_ notification: Notification) {
        var aWindowController: BaseModalWindowController?
        for controller in windowControllers {
            if let sender = notification.object as? NSWindow , controller.window == sender {
                aWindowController = controller
                break
            }
        }
        
        guard let windowController = aWindowController else { return }
        
        self.windowControllers.remove(windowController)
        
    }
    
}

extension IssueExtensionsPreferenceViewController: NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataSource.numberOfRows
    }
    
}

extension IssueExtensionsPreferenceViewController: NSTableViewDataSource {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let tableColumn = tableColumn else {
            return nil
        }
        
        if tableColumn.identifier.rawValue == "ScriptNameId" {
            
            if let view = tableView.makeView(withIdentifier: tableColumn.identifier, owner: self) as? NSTableCellView, let textField = view.textField {
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


