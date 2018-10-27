//
//  IssueExtensionCodeEditorViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/1/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import JavaScriptCore

@objc(SRIssueExtensionCodeEditorDebugBarView)
class IssueExtensionCodeEditorDebugBarView: NSView {
    var onDrag: ( (NSPoint) -> Void )?
    var onMouseUp: ( (NSPoint) -> Void )?
    var onMouseDown: ( (NSPoint) -> Void )?
    
    override func mouseUp(with theEvent: NSEvent) {
        if let onMouseUp = onMouseUp {
            onMouseUp(theEvent.locationInWindow)
        }
        super.mouseUp(with: theEvent)
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        if let onMouseDown = onMouseDown {
            onMouseDown(theEvent.locationInWindow)
        }
        super.mouseDown(with: theEvent)
    }
    
    override func mouseDragged(with theEvent: NSEvent) {
        if let onDrag = onDrag {
            onDrag(theEvent.locationInWindow)
        }
        super.mouseDragged(with: theEvent)
    }
}

@objc(SRIssueExtensionCodeEditorViewController)
class IssueExtensionCodeEditorViewController: NSViewController {
    
    fileprivate static let buttonSize = CGSize(width: 92, height: 30)
    fileprivate static let buttonsBottomPadding: CGFloat = 12
    fileprivate static let buttonsSpacing: CGFloat = 8
    fileprivate static let saveButtonRightPadding: CGFloat = 12
    fileprivate static let consoleCollapsedHeight: CGFloat = 30
    fileprivate static let consoleExpandedMinHeight: CGFloat = 120
    
    
    @IBOutlet weak var trashButton: NSButton!
    @IBOutlet weak var toggleButton: NSButton!
    @IBOutlet weak var codeEditorView: CodeEditorView!
    @IBOutlet weak var scriptNameContainerView: BaseView!
    @IBOutlet weak var scriptNameTextView: NSTextField!
    @IBOutlet weak var debugButton: NSButton!
    @IBOutlet weak var debugBarView: IssueExtensionCodeEditorDebugBarView!
    @IBOutlet weak var debugContainerView: NSView!
    @IBOutlet var consoleTextView: NSTextView!
    @IBOutlet weak var debugBarContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var consoleSeparatorView: BaseSeparatorView!
    
    fileprivate let cancelButton = BaseButton.whiteButton()
    fileprivate let saveButton = BaseButton.greenButton()
    fileprivate let extensionCloudKitService = ExtensionCloudKitService()
    
    fileprivate var expandConsoleImage = NSImage(named: NSImage.Name(rawValue: "expand_console"))?.withTintColor(DarkModeColor.sharedInstance.foregroundColor())
    fileprivate var collapseConsoleImage = NSImage(named: NSImage.Name(rawValue: "collapse_console"))?.withTintColor(DarkModeColor.sharedInstance.foregroundColor())
    fileprivate var trashImage = NSImage(named: NSImage.Name(rawValue: "trash"))?.withTintColor(DarkModeColor.sharedInstance.foregroundColor())
    
    fileprivate var toggleButtonRecentHeight: CGFloat = IssueExtensionCodeEditorViewController.consoleExpandedMinHeight
    fileprivate var consoleLogDateFormatter: DateFormatter = {
        let consoleLogDateFormatter = DateFormatter()
        consoleLogDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return consoleLogDateFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
        setupDebugBar()
        setupConsoleTextView()
        
        scriptNameTextView.drawsBackground = false
        scriptNameContainerView.cornerRadius = 5.0
        scriptNameContainerView.disableThemeObserver = true
        consoleSeparatorView.disableThemeObserver = true
        cancelButton.disableThemeObserver = true
        saveButton.disableThemeObserver = true
        consoleSeparatorView.backgroundColor = DarkModeColor.sharedInstance.separatorColor()
        scriptNameContainerView.borderColor = NSColor.darkGray
        scriptNameContainerView.backgroundColor = NSColor.black
        cancelButton.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
        saveButton.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
        //codeEditorView.layer?.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor().CGColor
        
    }
    
    var codeExtension: SRExtension? {
        didSet {
            if let codeExtension = codeExtension {
                if codeEditorView.code != codeExtension.sourceCode  {
                    codeEditorView.code = codeExtension.sourceCode
                    scriptNameTextView.stringValue = codeExtension.name
                }
            } else {
                guard let defaultIssueExtension = Bundle.main.path(forResource: "default_issue_extension", ofType: "js") else {
                    codeEditorView.code = ""
                    scriptNameTextView.stringValue = ""
                    return;
                }
                
                do {
                    let defaultCode = try NSString(contentsOfFile: defaultIssueExtension, encoding: String.Encoding.utf8.rawValue)
                    codeEditorView.code = defaultCode as String
                    scriptNameTextView.stringValue = ""
                } catch {
                    codeEditorView.code = ""
                    scriptNameTextView.stringValue = ""
                }
            }
        }
    }
    
    var code: String {
        return codeEditorView.code ?? ""
    }
    
    fileprivate func setupConsoleTextView() {
        consoleTextView.isSelectable = true
        consoleTextView.isEditable = false
        consoleTextView.drawsBackground = true
        consoleTextView.backgroundColor = NSColor.black
        consoleTextView.textColor = NSColor.white
        consoleTextView.wantsLayer = true
        consoleTextView.isRichText = true
        consoleTextView.allowsUndo = false
        consoleTextView.usesFontPanel = false
        consoleTextView.usesFindBar = false
        consoleTextView.usesInspectorBar = false
        consoleTextView.usesRuler = false
        consoleTextView.importsGraphics = false
        consoleTextView.font = NSFont(name: "Menlo", size: 12)
        consoleTextView.typingAttributes = [NSAttributedStringKey.font: consoleTextView.font!]
    }
    
    fileprivate func setupDebugBar() {
        // var startPoint: NSPoint?
        
        debugBarView.onDrag = { [weak self] (point) in
            guard let strongSelf = self else { return }
            
            // let firstPoint = startPoint ?? point
            // NSCursor.resizeUpCursor().set()
            
            //DispatchOnMainQueue({
            let deltaY =  point.y - strongSelf.debugContainerView.frame.minY
            let height: CGFloat = deltaY > 90 ? max(IssueExtensionCodeEditorViewController.consoleExpandedMinHeight, deltaY) : IssueExtensionCodeEditorViewController.consoleCollapsedHeight
            if strongSelf.debugBarContainerHeightConstraint.constant != height {
                strongSelf.debugBarContainerHeightConstraint.constant = height
                strongSelf.debugContainerView.needsLayout = true
                strongSelf.debugContainerView.layoutSubtreeIfNeeded()
            }
            
            strongSelf.updateToggleButtonState()
            // })
            
        }
        
    }
    
    fileprivate func updateToggleButtonState() {
        if IssueExtensionCodeEditorViewController.consoleCollapsedHeight == debugBarContainerHeightConstraint.constant {
            if toggleButton.image != expandConsoleImage {
                toggleButton.image = expandConsoleImage
            }
            toggleButton.toolTip = "Expand debug console"
        } else {
            if toggleButton.image != collapseConsoleImage {
                toggleButton.image = collapseConsoleImage
            }
            toggleButton.toolTip = "Collapse debug console"
        }
    }
    
    fileprivate func setupButtons() {
        guard saveButton.superview == nil && cancelButton.superview == nil else { return }
        saveButton.text = "Save"
        cancelButton.text = "Discard"
        
        saveButton.onClick = { [weak self] in
            self?.didClickSaveButton()
        }
        
        cancelButton.onClick = { [weak self] in
            self?.didClickDiscardButton()
        }
        
        [saveButton, cancelButton].forEach { (bttn) in
            view.addSubview(bttn)
            bttn.translatesAutoresizingMaskIntoConstraints = false
            bttn.heightAnchor.constraint(equalToConstant: IssueExtensionCodeEditorViewController.buttonSize.height).isActive = true
            bttn.widthAnchor.constraint(equalToConstant: IssueExtensionCodeEditorViewController.buttonSize.width).isActive = true
            bttn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -IssueExtensionCodeEditorViewController.buttonsBottomPadding).isActive = true
        }
        
        saveButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -IssueExtensionCodeEditorViewController.saveButtonRightPadding).isActive = true
        cancelButton.rightAnchor.constraint(equalTo: saveButton.leftAnchor, constant: -IssueExtensionCodeEditorViewController.buttonsSpacing).isActive = true
        
        debugButton.image = NSImage(named: NSImage.Name(rawValue: "play"))?.withTintColor(DarkModeColor.sharedInstance.foregroundColor())
        debugButton.toolTip = "Run code in development mode"
        toggleButton.image = expandConsoleImage
        toggleButton.toolTip = "Expand debug console"
        trashButton.image = trashImage
        trashButton.toolTip = "Clear console"
    }
    
    
    fileprivate func didClickSaveButton() {
        DispatchOnMainQueue {
            
            if self.formValidation() == false {
                return;
            }
            
            let externalId = self.codeExtension?.externalId
            let keyboardShortcut = self.codeExtension?.keyboardShortcut
            DispatchOnMainQueue {
                self.extensionCloudKitService.saveCodeExtension(self.codeEditorView.code, name: (self.scriptNameTextView.stringValue as NSString).trimmedString() as String, recordNameId: externalId, keyboardShortcut: keyboardShortcut, extensionType: SRExtensionTypeIssue) {[weak self] (record, err) in
                    if let record = record as? SRExtension , err == nil {
                        DispatchOnMainQueue {
                            self?.codeExtension = record
                            self?.view.window?.close()
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func formValidation() -> Bool {
        let isScriptNameMissing = (self.scriptNameTextView.stringValue as NSString).trimmedString().length == 0
        let isSourceCodeMissing = (self.codeEditorView.code as NSString).trimmedString().length == 0
        if isScriptNameMissing || isSourceCodeMissing {
            flashErrorFor(isScriptNameMissing, isSourceCodeMissing: isSourceCodeMissing)
            return false;
        }
        
        let scriptName = (self.scriptNameTextView.stringValue as NSString).trimmedString()
        if SRExtensionStore.extension(forName: scriptName as String, extensionType: SRExtensionTypeIssue) != codeExtension {
            flashErrorFor(true, isSourceCodeMissing: false)
            return false
        }
        
        return true
    }
    
    fileprivate func flashErrorFor(_ isScriptNameMissing: Bool, isSourceCodeMissing: Bool) {
        DispatchOnMainQueue {
            let currentScriptNameBorderColor = self.scriptNameContainerView.layer?.borderColor
            
            if isScriptNameMissing {
                self.scriptNameContainerView.layer?.borderColor = NSColor.red.cgColor
            }
            
            if isSourceCodeMissing {
                self.codeEditorView.layer?.borderColor = NSColor.red.cgColor
                self.codeEditorView.layer?.borderWidth = 1
            }
            
            let delayTime = DispatchTime.now() + Double(Int64(3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
                if isScriptNameMissing {
                    self.scriptNameContainerView.layer?.borderColor = currentScriptNameBorderColor
                }
                if isSourceCodeMissing {
                    self.codeEditorView.layer?.borderColor = nil
                    self.codeEditorView.layer?.borderWidth = 0
                }
            })
        }
    }
    
    
    @IBAction func didClickTrashButton(_ sender: AnyObject) {
        self.consoleTextView.string = ""
    }
    
    fileprivate func didClickDiscardButton() {
        NSAlert.showWarningMessage("Are you sure you want to discard your changes?", onConfirmation: { [weak self] in
            DispatchOnMainQueue {
                self?.view.window?.close()
            }
            })
    }
    
    @IBAction func didClickToggleButton(_ sender: AnyObject) {
        if IssueExtensionCodeEditorViewController.consoleCollapsedHeight == debugBarContainerHeightConstraint.constant {
            expandDebugConsole()
            
        } else {
            
            if debugBarContainerHeightConstraint.constant > IssueExtensionCodeEditorViewController.consoleExpandedMinHeight {
                toggleButtonRecentHeight = debugBarContainerHeightConstraint.constant
            }
            
            debugBarContainerHeightConstraint.constant = IssueExtensionCodeEditorViewController.consoleCollapsedHeight
        }
        
        updateToggleButtonState()
    }
    
    fileprivate func expandDebugConsole() {
        if toggleButtonRecentHeight < IssueExtensionCodeEditorViewController.consoleExpandedMinHeight {
            toggleButtonRecentHeight = IssueExtensionCodeEditorViewController.consoleExpandedMinHeight
        }
        
        debugBarContainerHeightConstraint.constant = toggleButtonRecentHeight
        updateToggleButtonState()
    }
    
    @IBAction func didClickDebugButton(_ sender: AnyObject) {
        let currentAccount = QContext.shared().currentAccount
        let repositories = QRepositoryStore.repositories(forAccountId: currentAccount?.identifier)
        let filter = QIssueFilter()
        guard let firstRepository = repositories?.first else { return }
        
        filter.repositories = NSOrderedSet(object: firstRepository.fullName);
        filter.filterType = SRFilterType_Search
        filter.account = currentAccount
        let pagination = QPagination(pageOffset: 0, pageSize: 10)
        self.consoleTextView.string = ""
        
        if IssueExtensionCodeEditorViewController.consoleCollapsedHeight == debugBarContainerHeightConstraint.constant {
            expandDebugConsole()
        }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
            let issues = QIssueStore.issues(with: filter, pagination: pagination).map({ $0.toExtensionModel() })
            IssueExtensionsJSContextRunner(environment: self).runWithIssues(issues as [NSDictionary], sourceCode: self.codeEditorView.code)
        }
    }
    
    override func keyDown(with theEvent: NSEvent) {
        super.keyDown(with: theEvent)
        if theEvent.modifierFlags.contains(NSEvent.ModifierFlags.command) && theEvent.keyCode == 1 && formValidation() {
            let externalId = self.codeExtension?.externalId
            let keyboardShortcut = self.codeExtension?.keyboardShortcut
            
            self.extensionCloudKitService.saveCodeExtension(self.codeEditorView.code, name: self.scriptNameTextView.stringValue, recordNameId: externalId, keyboardShortcut: keyboardShortcut, extensionType: SRExtensionTypeIssue) {[weak self] (record, err) in
                if let record = record as? SRExtension , err == nil {
                    self?.codeExtension = record
                }
            }
        }
    }
    
}


extension IssueExtensionCodeEditorViewController: CodeExtensionEnvironmentProtocol {
    
    func consoleLog(_ arguments: [AnyObject], logLevel: LogLevel) {
        let str = arguments.map({"\($0)"}).joined(separator: " ")
        let date = consoleLogDateFormatter.string(from: Date())
        DispatchOnMainQueue {
            self.consoleTextView.appendString("\(date) [LOG] \(str)\n", attributes: [NSAttributedStringKey.font: NSFont(name: "Menlo", size: 12)!, NSAttributedStringKey.foregroundColor: NSColor.white])
        }
    }
    
    func exceptionLog(_ line: String, column: String, stacktrace: String, exception: String) {
        let str = "Line: \(line) Column: \(column) Method: \(stacktrace) - \(exception)"
        DispatchOnMainQueue {
            self.consoleTextView.appendString("\(Date()) [EXCEPTION] \(str)\n", attributes: [NSAttributedStringKey.font: NSFont(name: "Menlo", size: 12)!, NSAttributedStringKey.foregroundColor: NSColor.red])
        }
    }
    
    
    func writeToPasteboard(_ str: String) {
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString(str, forType: .string)
    }
    
}

extension IssueExtensionCodeEditorViewController: MilestoneServiceExtensionEnvironmentProtocol {
    
    func milestonesForRepository(_ repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.shared().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.call(withArguments: [ NSNull(), "Missing repository parameter" ])
            return
        }
        let milestones = QMilestoneStore.milestones(forAccountId: account?.identifier, repositoryId: repositoryId, includeHidden: false)
        onCompletion.call(withArguments: milestones?.flatMap({ $0.toExtensionModel() }))
    }
    
}

extension IssueExtensionCodeEditorViewController: OwnerServiceExtensionEnvironmentProtocol {
    
    func usersForRepository(_ repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.shared().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.call(withArguments: [ NSNull(), "Missing repository parameter" ])
            return
        }
        let owners = QOwnerStore.owners(forAccountId: account?.identifier, repositoryId: repositoryId)
        onCompletion.call(withArguments: owners?.flatMap({ $0.toExtensionModel() }))
    }
    
}

extension IssueExtensionCodeEditorViewController: LabelServiceExtensionEnvironmentProtocol {
    
    func labelsForRepository(_ repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.shared().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.call(withArguments: [ NSNull(), "Missing repository parameter" ])
            return
        }
        let labels = QLabelStore.labels(forAccountId: account?.identifier, repositoryId: repositoryId, includeHidden: false)
        onCompletion.call(withArguments: labels?.flatMap({ $0.toExtensionModel() }))
    }
    
}

extension IssueExtensionCodeEditorViewController: IssueServiceExtensionEnvironmentProtocol {
    
    func closeIssue(_ issue: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["isOpen"] = false
        
        onCompletion.call(withArguments: [ updateIssue, NSNull() ])
    }
    
    func openIssue(_ issue: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["isOpen"] = true
        
        onCompletion.call(withArguments: [ updateIssue, NSNull() ])
    }
    
    func assignMilestoneToIssue(_ issue: NSDictionary, milestone: NSDictionary?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( milestone == nil || CodeExtensionModelValidators.validateMilestone(milestone)) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["milestone"] = milestone
        
        onCompletion.call(withArguments: [ updateIssue, NSNull() ])
    }
    
    func assignUserToIssue(_ issue: NSDictionary, user: NSDictionary?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( user == nil || CodeExtensionModelValidators.validateOwner(user))  else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["assignee"] = user
        
        onCompletion.call(withArguments: [ updateIssue, NSNull() ])
    }
    
    func assignLabelsToIssue(_ issue: NSDictionary, labels: NSArray?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( labels == nil || CodeExtensionModelValidators.validateLabels(labels))  else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["labels"] = labels
        
        onCompletion.call(withArguments: [ updateIssue, NSNull() ])
    }
    
    func createIssueComment(_ issue: NSDictionary, comment: String, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        onCompletion.call(withArguments: [ issue, NSNull() ])
    }
    
    func saveIssueTitle(_ issue: NSDictionary, title: String, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["title"] = title
        
        onCompletion.call(withArguments: [ updateIssue, NSNull() ])
    }
    
    func saveIssueBody(_ issue: NSDictionary, body: String?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["body"] = body
        
        onCompletion.call(withArguments: [ updateIssue, NSNull() ])
    }
    
}

private extension NSTextView {
    func appendString(_ string: String, attributes: [NSAttributedStringKey: Any]) {
        self.textStorage?.append(NSAttributedString(string: string, attributes: attributes))
        self.scrollToEndOfDocument(nil)
    }
}

