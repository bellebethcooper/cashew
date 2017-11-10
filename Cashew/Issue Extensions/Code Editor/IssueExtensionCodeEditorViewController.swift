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
    
    override func mouseUp(theEvent: NSEvent) {
        if let onMouseUp = onMouseUp {
            onMouseUp(theEvent.locationInWindow)
        }
        super.mouseUp(theEvent)
    }
    
    override func mouseDown(theEvent: NSEvent) {
        if let onMouseDown = onMouseDown {
            onMouseDown(theEvent.locationInWindow)
        }
        super.mouseDown(theEvent)
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        if let onDrag = onDrag {
            onDrag(theEvent.locationInWindow)
        }
        super.mouseDragged(theEvent)
    }
}

@objc(SRIssueExtensionCodeEditorViewController)
class IssueExtensionCodeEditorViewController: NSViewController {
    
    private static let buttonSize = CGSize(width: 92, height: 30)
    private static let buttonsBottomPadding: CGFloat = 12
    private static let buttonsSpacing: CGFloat = 8
    private static let saveButtonRightPadding: CGFloat = 12
    private static let consoleCollapsedHeight: CGFloat = 30
    private static let consoleExpandedMinHeight: CGFloat = 120
    
    
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
    
    private let cancelButton = BaseButton.whiteButton()
    private let saveButton = BaseButton.greenButton()
    private let extensionCloudKitService = ExtensionCloudKitService()
    
    private var expandConsoleImage = NSImage(named: "expand_console")?.imageWithTintColor(DarkModeColor.sharedInstance.foregroundColor())
    private var collapseConsoleImage = NSImage(named: "collapse_console")?.imageWithTintColor(DarkModeColor.sharedInstance.foregroundColor())
    private var trashImage = NSImage(named: "trash")?.imageWithTintColor(DarkModeColor.sharedInstance.foregroundColor())
    
    private var toggleButtonRecentHeight: CGFloat = IssueExtensionCodeEditorViewController.consoleExpandedMinHeight
    private var consoleLogDateFormatter: NSDateFormatter = {
        let consoleLogDateFormatter = NSDateFormatter()
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
        scriptNameContainerView.borderColor = NSColor.darkGrayColor()
        scriptNameContainerView.backgroundColor = NSColor.blackColor()
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
                guard let defaultIssueExtension = NSBundle.mainBundle().pathForResource("default_issue_extension", ofType: "js") else {
                    codeEditorView.code = ""
                    scriptNameTextView.stringValue = ""
                    return;
                }
                
                do {
                    let defaultCode = try NSString(contentsOfFile: defaultIssueExtension, encoding: NSUTF8StringEncoding)
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
    
    private func setupConsoleTextView() {
        consoleTextView.selectable = true
        consoleTextView.editable = false
        consoleTextView.drawsBackground = true
        consoleTextView.backgroundColor = NSColor.blackColor()
        consoleTextView.textColor = NSColor.whiteColor()
        consoleTextView.wantsLayer = true
        consoleTextView.richText = true
        consoleTextView.allowsUndo = false
        consoleTextView.usesFontPanel = false
        consoleTextView.usesFindBar = false
        consoleTextView.usesInspectorBar = false
        consoleTextView.usesRuler = false
        consoleTextView.importsGraphics = false
        consoleTextView.font = NSFont(name: "Menlo", size: 12)
        consoleTextView.typingAttributes = [NSFontNameAttribute: consoleTextView.font!]
    }
    
    private func setupDebugBar() {
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
    
    private func updateToggleButtonState() {
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
    
    private func setupButtons() {
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
            bttn.heightAnchor.constraintEqualToConstant(IssueExtensionCodeEditorViewController.buttonSize.height).active = true
            bttn.widthAnchor.constraintEqualToConstant(IssueExtensionCodeEditorViewController.buttonSize.width).active = true
            bttn.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -IssueExtensionCodeEditorViewController.buttonsBottomPadding).active = true
        }
        
        saveButton.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -IssueExtensionCodeEditorViewController.saveButtonRightPadding).active = true
        cancelButton.rightAnchor.constraintEqualToAnchor(saveButton.leftAnchor, constant: -IssueExtensionCodeEditorViewController.buttonsSpacing).active = true
        
        debugButton.image = NSImage(named: "play")?.imageWithTintColor(DarkModeColor.sharedInstance.foregroundColor())
        debugButton.toolTip = "Run code in development mode"
        toggleButton.image = expandConsoleImage
        toggleButton.toolTip = "Expand debug console"
        trashButton.image = trashImage
        trashButton.toolTip = "Clear console"
    }
    
    
    private func didClickSaveButton() {
        DispatchOnMainQueue {
            
            if self.formValidation() == false {
                return;
            }
            
            let externalId = self.codeExtension?.externalId
            let keyboardShortcut = self.codeExtension?.keyboardShortcut
            DispatchOnMainQueue {
                self.extensionCloudKitService.saveCodeExtension(self.codeEditorView.code, name: (self.scriptNameTextView.stringValue as NSString).trimmedString() as String, recordNameId: externalId, keyboardShortcut: keyboardShortcut, extensionType: SRExtensionTypeIssue) {[weak self] (record, err) in
                    if let record = record as? SRExtension where err == nil {
                        DispatchOnMainQueue {
                            self?.codeExtension = record
                            self?.view.window?.close()
                        }
                    }
                }
            }
        }
    }
    
    private func formValidation() -> Bool {
        let isScriptNameMissing = (self.scriptNameTextView.stringValue as NSString).trimmedString().length == 0
        let isSourceCodeMissing = (self.codeEditorView.code as NSString).trimmedString().length == 0
        if isScriptNameMissing || isSourceCodeMissing {
            flashErrorFor(isScriptNameMissing, isSourceCodeMissing: isSourceCodeMissing)
            return false;
        }
        
        let scriptName = (self.scriptNameTextView.stringValue as NSString).trimmedString()
        if SRExtensionStore.extensionForName(scriptName as String, extensionType: SRExtensionTypeIssue) != codeExtension {
            flashErrorFor(true, isSourceCodeMissing: false)
            return false
        }
        
        return true
    }
    
    private func flashErrorFor(isScriptNameMissing: Bool, isSourceCodeMissing: Bool) {
        DispatchOnMainQueue {
            let currentScriptNameBorderColor = self.scriptNameContainerView.layer?.borderColor
            
            if isScriptNameMissing {
                self.scriptNameContainerView.layer?.borderColor = NSColor.redColor().CGColor
            }
            
            if isSourceCodeMissing {
                self.codeEditorView.layer?.borderColor = NSColor.redColor().CGColor
                self.codeEditorView.layer?.borderWidth = 1
            }
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue(), {
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
    
    
    @IBAction func didClickTrashButton(sender: AnyObject) {
        self.consoleTextView.string = ""
    }
    
    private func didClickDiscardButton() {
        NSAlert.showWarningMessage("Are you sure you want to discard your changes?", onConfirmation: { [weak self] in
            DispatchOnMainQueue {
                self?.view.window?.close()
            }
            })
    }
    
    @IBAction func didClickToggleButton(sender: AnyObject) {
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
    
    private func expandDebugConsole() {
        if toggleButtonRecentHeight < IssueExtensionCodeEditorViewController.consoleExpandedMinHeight {
            toggleButtonRecentHeight = IssueExtensionCodeEditorViewController.consoleExpandedMinHeight
        }
        
        debugBarContainerHeightConstraint.constant = toggleButtonRecentHeight
        updateToggleButtonState()
    }
    
    @IBAction func didClickDebugButton(sender: AnyObject) {
        let currentAccount = QContext.sharedContext().currentAccount
        let repositories = QRepositoryStore.repositoriesForAccountId(currentAccount.identifier)
        let filter = QIssueFilter()
        guard let firstRepository = repositories.first else { return }
        
        filter.repositories = NSOrderedSet(object: firstRepository.fullName);
        filter.filterType = SRFilterType_Search
        filter.account = currentAccount
        let pagination = QPagination(pageOffset: 0, pageSize: 10)
        self.consoleTextView.string = ""
        
        if IssueExtensionCodeEditorViewController.consoleCollapsedHeight == debugBarContainerHeightConstraint.constant {
            expandDebugConsole()
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            let issues = QIssueStore.issuesWithFilter(filter, pagination: pagination).map({ $0.toExtensionModel() })
            IssueExtensionsJSContextRunner(environment: self).runWithIssues(issues, sourceCode: self.codeEditorView.code)
        }
    }
    
    override func keyDown(theEvent: NSEvent) {
        super.keyDown(theEvent)
        if theEvent.modifierFlags.contains(NSEventModifierFlags.Command) && theEvent.keyCode == 1 && formValidation() {
            let externalId = self.codeExtension?.externalId
            let keyboardShortcut = self.codeExtension?.keyboardShortcut
            
            self.extensionCloudKitService.saveCodeExtension(self.codeEditorView.code, name: self.scriptNameTextView.stringValue, recordNameId: externalId, keyboardShortcut: keyboardShortcut, extensionType: SRExtensionTypeIssue) {[weak self] (record, err) in
                if let record = record as? SRExtension where err == nil {
                    self?.codeExtension = record
                }
            }
        }
    }
    
}


extension IssueExtensionCodeEditorViewController: CodeExtensionEnvironmentProtocol {
    
    func consoleLog(arguments: [AnyObject], logLevel: LogLevel) {
        let str = arguments.map({"\($0)"}).joinWithSeparator(" ")
        let date = consoleLogDateFormatter.stringFromDate(NSDate())
        DispatchOnMainQueue {
            self.consoleTextView.appendString("\(date) [LOG] \(str)\n", attributes: [NSFontAttributeName: NSFont(name: "Menlo", size: 12)!, NSForegroundColorAttributeName: NSColor.whiteColor()])
        }
    }
    
    func exceptionLog(line: String, column: String, stacktrace: String, exception: String) {
        let str = "Line: \(line) Column: \(column) Method: \(stacktrace) - \(exception)"
        DispatchOnMainQueue {
            self.consoleTextView.appendString("\(NSDate()) [EXCEPTION] \(str)\n", attributes: [NSFontAttributeName: NSFont(name: "Menlo", size: 12)!, NSForegroundColorAttributeName: NSColor.redColor()])
        }
    }
    
    
    func writeToPasteboard(str: String) {
        NSPasteboard.generalPasteboard().declareTypes([NSStringPboardType], owner: nil)
        NSPasteboard.generalPasteboard().setString(str, forType: NSStringPboardType)
    }
    
}

extension IssueExtensionCodeEditorViewController: MilestoneServiceExtensionEnvironmentProtocol {
    
    func milestonesForRepository(repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.sharedContext().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.callWithArguments([ NSNull(), "Missing repository parameter" ])
            return
        }
        let milestones = QMilestoneStore.milestonesForAccountId(account.identifier, repositoryId: repositoryId, includeHidden: false)
        onCompletion.callWithArguments([ milestones.flatMap({ $0.toExtensionModel() }), NSNull() ])
    }
    
}

extension IssueExtensionCodeEditorViewController: OwnerServiceExtensionEnvironmentProtocol {
    
    func usersForRepository(repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.sharedContext().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.callWithArguments([ NSNull(), "Missing repository parameter" ])
            return
        }
        let owners = QOwnerStore.ownersForAccountId(account.identifier, repositoryId: repositoryId)
        onCompletion.callWithArguments([ owners.flatMap({ $0.toExtensionModel() }), NSNull() ])
    }
    
}

extension IssueExtensionCodeEditorViewController: LabelServiceExtensionEnvironmentProtocol {
    
    func labelsForRepository(repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.sharedContext().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.callWithArguments([ NSNull(), "Missing repository parameter" ])
            return
        }
        let labels = QLabelStore.labelsForAccountId(account.identifier, repositoryId: repositoryId, includeHidden: false)
        onCompletion.callWithArguments([ labels.flatMap({ $0.toExtensionModel() }), NSNull() ])
    }
    
}

extension IssueExtensionCodeEditorViewController: IssueServiceExtensionEnvironmentProtocol {
    
    func closeIssue(issue: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["isOpen"] = false
        
        onCompletion.callWithArguments([ updateIssue, NSNull() ])
    }
    
    func openIssue(issue: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["isOpen"] = true
        
        onCompletion.callWithArguments([ updateIssue, NSNull() ])
    }
    
    func assignMilestoneToIssue(issue: NSDictionary, milestone: NSDictionary?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( milestone == nil || CodeExtensionModelValidators.validateMilestone(milestone)) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["milestone"] = milestone
        
        onCompletion.callWithArguments([ updateIssue, NSNull() ])
    }
    
    func assignUserToIssue(issue: NSDictionary, user: NSDictionary?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( user == nil || CodeExtensionModelValidators.validateOwner(user))  else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["assignee"] = user
        
        onCompletion.callWithArguments([ updateIssue, NSNull() ])
    }
    
    func assignLabelsToIssue(issue: NSDictionary, labels: NSArray?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( labels == nil || CodeExtensionModelValidators.validateLabels(labels))  else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["labels"] = labels
        
        onCompletion.callWithArguments([ updateIssue, NSNull() ])
    }
    
    func createIssueComment(issue: NSDictionary, comment: String, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        onCompletion.callWithArguments([ issue, NSNull() ])
    }
    
    func saveIssueTitle(issue: NSDictionary, title: String, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["title"] = title
        
        onCompletion.callWithArguments([ updateIssue, NSNull() ])
    }
    
    func saveIssueBody(issue: NSDictionary, body: String?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let updateIssue = issue.mutableCopy() as! NSMutableDictionary
        updateIssue["body"] = body
        
        onCompletion.callWithArguments([ updateIssue, NSNull() ])
    }
    
}

private extension NSTextView {
    func appendString(string: String, attributes: [String: AnyObject]) {
        self.textStorage?.appendAttributedString(NSAttributedString(string: string, attributes: attributes))
        self.scrollToEndOfDocument(nil)
    }
}

