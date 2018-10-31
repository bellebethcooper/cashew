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
    
    @objc required init(issue: QIssue) {
        self.issue = issue
        super.init()
    }
}

extension IssueDetailLabelsTableViewModel: SRIssueDetailItem {
    func sortDate() -> Date! {
        return self.issue.createdAt
    }
}

@objc(SRIssueDetailLabelsTableViewCell)
class IssueDetailLabelsTableViewCell: BaseView {
    
    @IBOutlet weak var issueLabelContainerView: QIssueLabelContainerView!
    @IBOutlet weak var addLabelButton: NSImageView!
    @IBOutlet weak var noLabelTextField: NSTextField!
    @IBOutlet weak var tagButton: IssueDetailsLabelTagButton!
    
    fileprivate var labelPopover: NSPopover?
    
    @objc var enabled: Bool  = true {
        didSet {
            tagButton.enabled = enabled
        }
    }
    
    @objc var viewModel: IssueDetailLabelsTableViewModel? {
        didSet {
            
            if let issue = viewModel?.issue {
                self.addLabelButton.isHidden = !QAccount.isCurrentUserCollaboratorOfRepository(issue.repo())
            } else {
                self.addLabelButton.isHidden = false
            }
            
            if let labels = viewModel?.issue.labels , labels.count > 0 {
                issueLabelContainerView.labels = viewModel?.issue.labels
                noLabelTextField.isHidden = true
                issueLabelContainerView.isHidden = false
            } else {
                noLabelTextField.isHidden = false
                issueLabelContainerView.isHidden = true
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
            
            if mode == .light {
                strongSelf.backgroundColor = NSColor.white
                strongSelf.noLabelTextField.textColor = LightModeColor.sharedInstance.foregroundSecondaryColor()
            } else if mode == .dark {
                strongSelf.backgroundColor = DarkModeColor.sharedInstance.backgroundColor()
                strongSelf.noLabelTextField.textColor = DarkModeColor.sharedInstance.foregroundSecondaryColor()
            }
        }
    }
    
    fileprivate func setupNoLabelTextField() {
        let font = NSFontManager.shared.convert(NSFont.systemFont(ofSize: 12, weight: NSFont.Weight.thin), toHaveTrait: .italicFontMask)
        self.noLabelTextField.font = font
    }
    
    fileprivate func setupAddLabelButton() {
        let color = NSColor(calibratedWhite: 147/255.0, alpha: 0.85)
        self.addLabelButton.wantsLayer = true
        self.addLabelButton.image = self.addLabelButton.image?.withTintColor(color)
        self.addLabelButton.layer?.borderWidth = 1
        self.addLabelButton.layer?.borderColor = color.cgColor
        self.addLabelButton.layer?.cornerRadius = self.addLabelButton.bounds.height / 2.0
//        self.addLabelButton.layer?.backgroundColor = CashewColor.selectedBackgroundColor().cgColor
//        self.tagButton.wantsLayer = true
//        self.tagButton.layer?.backgroundColor = CashewColor.selectedBackgroundColor().cgColor
        
        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(IssueDetailLabelsTableViewCell.didClickAddLabel(_:)))
        clickRecognizer.numberOfClicksRequired = 1
        self.addLabelButton.addGestureRecognizer(clickRecognizer)
    }
    
    @objc
    fileprivate func didClickAddLabel(_ sender: AnyObject) {
        Analytics.logCustomEventWithName("Clicked Labels on Issue Details", customAttributes:nil)
        let labelSearchablePicker = LabelSearchablePickerViewController()
        labelSearchablePicker.sourceIssue = viewModel?.issue;
        
        let size = NSMakeSize(320.0, 420.0)
        
        labelSearchablePicker.view.frame = NSMakeRect(0, 0, size.width, size.height);
        
        let popover = NSPopover()
        
        
        if .dark == UserDefaults.themeMode() {
            let appearance = NSAppearance(named: NSAppearance.Name.aqua)
            popover.appearance = appearance;
        } else {
            let appearance = NSAppearance(named: NSAppearance.Name.aqua)
            popover.appearance = appearance;
        }
        
        self.labelPopover = popover;
        self.superview?.window?.makeFirstResponder(self.superview)
        popover.delegate = self
        popover.contentSize = size
        popover.contentViewController = labelSearchablePicker
        popover.animates = true
        popover.behavior = .transient
        popover.show(relativeTo: addLabelButton.bounds, of:addLabelButton, preferredEdge:.maxY);
        labelSearchablePicker.popover = popover;
    }
    
    @objc class func suggestedHeight() -> CGFloat {
        return 35.0;
    }
    
    @objc static func instanceFromNib() -> IssueDetailLabelsTableViewCell? {
        var viewArray: NSArray?
        let className = "IssueDetailLabelsTableViewCell"
        
        //DDLogDebug(" viewType = %@", className)
        assert(Thread.isMainThread)
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: className), owner: nil, topLevelObjects: &viewArray)
        
        for view in viewArray as! [NSObject] {
            if object_getClass(view) == IssueDetailLabelsTableViewCell.self {
                return view as? IssueDetailLabelsTableViewCell
            }
        }
        
       return nil
    }
}

class IssueDetailsLabelTagButton: BaseView {
    fileprivate var cursorTrackingArea: NSTrackingArea?
    
    @objc var enabled = true

    override func updateTrackingAreas() {
        if let cursorTrackingArea = cursorTrackingArea {
            removeTrackingArea(cursorTrackingArea)
        }
        
        let trackingArea = NSTrackingArea(rect: bounds, options: [NSTrackingArea.Options.cursorUpdate, NSTrackingArea.Options.activeAlways] , owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea);
        self.cursorTrackingArea = trackingArea
    }
    
    override func cursorUpdate(with event: NSEvent) {
        guard enabled else { return }
        NSCursor.pointingHand.set()
    }
}

extension IssueDetailLabelsTableViewCell: NSPopoverDelegate {
    
    func popoverDidClose(_ notification: Notification) {
        self.labelPopover = nil
    }
}
