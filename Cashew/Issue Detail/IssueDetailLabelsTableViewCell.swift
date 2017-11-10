//
//  IssueDetailLabelsTableViewCell.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/26/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRIssueDetailLabelsTableViewModel)
class IssueDetailLabelsTableViewModel: NSObject {
    var issue: QIssue
    
    required init(issue: QIssue) {
        self.issue = issue
        super.init()
    }
}

extension IssueDetailLabelsTableViewModel: SRIssueDetailItem {
    func sortDate() -> NSDate! {
        return self.issue.createdAt
    }
}

@objc(SRIssueDetailLabelsTableViewCell)
class IssueDetailLabelsTableViewCell: BaseView {
    
    @IBOutlet weak var issueLabelContainerView: QIssueLabelContainerView!
    @IBOutlet weak var addLabelButton: NSImageView!
    @IBOutlet weak var noLabelTextField: NSTextField!
    @IBOutlet weak var tagButton: IssueDetailsLabelTagButton!
    
    private var labelPopover: NSPopover?
    
    var enabled: Bool  = true {
        didSet {
            tagButton.enabled = enabled
        }
    }
    
    var viewModel: IssueDetailLabelsTableViewModel? {
        didSet {
            
            if let issue = viewModel?.issue {
                self.addLabelButton.hidden = !QAccount.isCurrentUserCollaboratorOfRepository(issue.repo())
            } else {
                self.addLabelButton.hidden = false
            }
            
            if let labels = viewModel?.issue.labels where labels.count > 0 {
                issueLabelContainerView.labels = viewModel?.issue.labels
                noLabelTextField.hidden = true
                issueLabelContainerView.hidden = false
            } else {
                noLabelTextField.hidden = false
                issueLabelContainerView.hidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupNoLabelTextField()
        setupAddLabelButton()
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(strongSelf)
                return;
            }
            
            if mode == .Light {
                strongSelf.backgroundColor = LightModeColor.sharedInstance.backgroundColor()
                strongSelf.noLabelTextField.textColor = LightModeColor.sharedInstance.foregroundColor()
            } else if mode == .Dark {
                strongSelf.backgroundColor = DarkModeColor.sharedInstance.backgroundColor()
                strongSelf.noLabelTextField.textColor = DarkModeColor.sharedInstance.foregroundColor()
            }
        }
    }
    
    private func setupNoLabelTextField() {
        let font = NSFontManager.sharedFontManager().convertFont(NSFont.systemFontOfSize(12, weight: NSFontWeightThin), toHaveTrait: .ItalicFontMask)
        self.noLabelTextField.font = font
    }
    
    private func setupAddLabelButton() {
        let color = NSColor(calibratedWhite: 147/255.0, alpha: 0.85)
        self.addLabelButton.wantsLayer = true
        self.addLabelButton.image = self.addLabelButton.image?.imageWithTintColor(color)
        self.addLabelButton.layer?.borderWidth = 1
        self.addLabelButton.layer?.borderColor = color.CGColor
        self.addLabelButton.layer?.cornerRadius = self.addLabelButton.bounds.height / 2.0
        
        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(IssueDetailLabelsTableViewCell.didClickAddLabel(_:)))
        clickRecognizer.numberOfClicksRequired = 1
        self.addLabelButton.addGestureRecognizer(clickRecognizer)
    }
    
    @objc
    private func didClickAddLabel(sender: AnyObject) {
        Analytics.logCustomEventWithName("Clicked Labels on Issue Details", customAttributes:nil)
        let labelSearchablePicker = LabelSearchablePickerViewController()
        labelSearchablePicker.sourceIssue = viewModel?.issue;
        
        let size = NSMakeSize(320.0, 420.0)
        
        labelSearchablePicker.view.frame = NSMakeRect(0, 0, size.width, size.height);
        
        let popover = NSPopover()
        
        
        if .Dark == NSUserDefaults.themeMode() {
            let appearance = NSAppearance(named: NSAppearanceNameAqua)
            popover.appearance = appearance;
        } else {
            let appearance = NSAppearance(named: NSAppearanceNameAqua)
            popover.appearance = appearance;
        }
        
        self.labelPopover = popover;
        self.superview?.window?.makeFirstResponder(self.superview)
        popover.delegate = self
        popover.contentSize = size
        popover.contentViewController = labelSearchablePicker
        popover.animates = true
        popover.behavior = .Transient
        popover.showRelativeToRect(addLabelButton.bounds, ofView:addLabelButton, preferredEdge:.MaxY);
        labelSearchablePicker.popover = popover;
    }
    
    class func suggestedHeight() -> CGFloat {
        return 35.0;
    }
    
    static func instanceFromNib() -> IssueDetailLabelsTableViewCell? {
        var viewArray: NSArray?
        let className = "IssueDetailLabelsTableViewCell"
        
        //DDLogDebug(" viewType = %@", className)
        assert(NSThread.isMainThread())
        NSBundle.mainBundle().loadNibNamed(className, owner: nil, topLevelObjects: &viewArray)
        
        for view in viewArray as! [NSObject] {
            if object_getClass(view) == IssueDetailLabelsTableViewCell.self {
                return view as? IssueDetailLabelsTableViewCell
            }
        }
        
       return nil
    }
}

class IssueDetailsLabelTagButton: BaseView {
    private var cursorTrackingArea: NSTrackingArea?
    
    var enabled = true

    override func updateTrackingAreas() {
        if let cursorTrackingArea = cursorTrackingArea {
            removeTrackingArea(cursorTrackingArea)
        }
        
        let trackingArea = NSTrackingArea(rect: bounds, options: [.CursorUpdate, .ActiveAlways] , owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea);
        self.cursorTrackingArea = trackingArea
    }
    
    override func cursorUpdate(event: NSEvent) {
        guard enabled else { return }
        NSCursor.pointingHandCursor().set()
    }
}

extension IssueDetailLabelsTableViewCell: NSPopoverDelegate {
    
    func popoverDidClose(notification: NSNotification) {
        self.labelPopover = nil
    }
}
