//
//  QIssueTableViewCell.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/22/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class IssueTableViewCellTextField: NSTextField {
    var shouldAllowVibrancy = true
    
    override var allowsVibrancy: Bool {
        return shouldAllowVibrancy
    }
}

private class IssueTableViewCellTextAttachmentCell: NSTextAttachmentCell {
    var yOffset: CGFloat = 3;
    override func cellBaselineOffset() -> NSPoint {
        var baseline = super.cellBaselineOffset()
        baseline.y = baseline.y - yOffset
        return baseline
    }
}

class QIssueTableViewCellCircleImageView: NSImageView {
    
    fileprivate var roundedCornerMask: CALayer?
    
    var shouldAllowVibrancy = true
    
    override var allowsVibrancy: Bool {
        return shouldAllowVibrancy
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let bezierPath = NSBezierPath(roundedRect: bounds, xRadius: bounds.width, yRadius: bounds.height)
        let maskLayer = CAShapeLayer()
        wantsLayer = true
        maskLayer.frame = bounds
        maskLayer.fillColor = NSColor.white.cgColor
        maskLayer.path = bezierPath.toCGPath()
        maskLayer.backgroundColor = NSColor.clear.cgColor
        roundedCornerMask = maskLayer
        self.layer?.mask = maskLayer //addSublayer(maskLayer)
        CATransaction.commit()
    }
    
    override func layout() {
        roundedCornerMask?.frame = bounds
        super.layout()
    }
    
}

class QIssueTableViewCell: NSTableRowView {
    
    @IBOutlet weak var closedImageViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet var closedImageViewTopConstraint: NSLayoutConstraint!
    var closedImageViewCenterYConstraint: NSLayoutConstraint?
    @IBOutlet weak var textContainerLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var readCircleView: BaseView!
    @IBOutlet weak var unassignedImageView: QIssueTableViewCellCircleImageView!
    @IBOutlet weak fileprivate var openIssueImageView: QIssueTableViewCellCircleImageView!
    @IBOutlet weak fileprivate var closedIssueImageView: QIssueTableViewCellCircleImageView!
    @IBOutlet weak fileprivate var assigneeImageView: BaseView!
    @IBOutlet weak fileprivate var titleLabel: IssueTableViewCellTextField!
    @IBOutlet weak fileprivate var subtitleLabel: IssueTableViewCellTextField!
    @IBOutlet weak fileprivate var updatedAtLabel: IssueTableViewCellTextField!
    @IBOutlet weak fileprivate var labelContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak fileprivate var labelsContainerView: BaseView!
    @IBOutlet weak fileprivate var titlesContainerView: BaseView!
    
    fileprivate var viewType: LayoutPreference = UserDefaults.layoutModePreference() {
        didSet {
            switch viewType {
            case .noAssigneeImage:
                transitionToCompactView()
            default:
                transitionToStandardView()
            }
        }
    }
    
    fileprivate var labelsView = QIssueLabelContainerView()
    fileprivate var mouseTrackingArea: NSTrackingArea?
    fileprivate var issueStatusTooltipTag: NSView.ToolTipTag?
    fileprivate var assigneeTooltipTag: NSView.ToolTipTag?
    fileprivate var assigneeLeftEdgeTooltipTag: NSView.ToolTipTag?
    
    // NSColor(red: 245/255.0 , green: 248/255.0 , blue: 247/255.0 , alpha: 1);
    fileprivate static let separatorLineHeight: CGFloat = 1.0
    
    fileprivate static let titleLabelFont = NSFont.systemFont(ofSize: 14, weight: .semibold)
    fileprivate static let subtitleFont = NSFont.systemFont(ofSize: 12, weight: .light)
    fileprivate static let subtitleBoldFont = NSFont.boldSystemFont(ofSize: 12)
    
    fileprivate static let subtitleRepoMilestoneFont = NSFont.systemFont(ofSize: 11, weight: .medium)
    
    fileprivate static let selectionColor = NSColor(calibratedRed: 62/255.0, green: 96/255.0, blue: 218/255.0, alpha: 1)
    
    fileprivate static let labelsViewHeight: CGFloat = 22.0
    
    fileprivate static let textContainerLeftPaddingWithImage: CGFloat = 80
    fileprivate static let textContainerLeftPaddingWithoutImage: CGFloat = 35
    
    fileprivate static let textContainerTopPaddingCompactMode: CGFloat = 12
    fileprivate static let textContainerTopPaddingStandardMode: CGFloat = 55
    
    fileprivate static let closedImageViewTopPaddingStandardMode: CGFloat = 55
    
    fileprivate static let closedImageViewLeftPaddingCompactMode: CGFloat = 12
    fileprivate static let closedImageViewLeftPaddingStandardMode: CGFloat = 48
    
    
    var shouldAllowVibrancy: Bool = true {
        didSet {
            [labelsView, titlesContainerView, labelsView, readCircleView, assigneeImageView, labelsContainerView].forEach { (view) in
                view.shouldAllowVibrancy = shouldAllowVibrancy
            }
            
            [titleLabel, subtitleLabel, updatedAtLabel].forEach { (view) in
                view.shouldAllowVibrancy = shouldAllowVibrancy
            }
            
            [unassignedImageView, openIssueImageView, closedIssueImageView].forEach { (view) in
                view.shouldAllowVibrancy = shouldAllowVibrancy
            }
            
        }
    }
    
    override var allowsVibrancy: Bool {
        get {
            return shouldAllowVibrancy
        }
    }
    
    deinit {
        QIssueStore.remove(self)
        QIssueNotificationStore.remove(self)
        UserDefaults.standard.removeObserver(self, forKeyPath: UserDefaults.PreferenceConstant.layoutMode) //, options: .New, context: nil)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder:coder)
        self.setup()
    }
    
    fileprivate func transitionToStandardView() {
        if let closedImageViewCenterYConstraint = closedImageViewCenterYConstraint {
            closedImageViewCenterYConstraint.isActive = false
        }
        
        textContainerLeftConstraint.constant = QIssueTableViewCell.textContainerLeftPaddingWithImage
        closedImageViewTopConstraint.isActive = true
        closedImageViewLeftConstraint.constant = QIssueTableViewCell.closedImageViewLeftPaddingStandardMode
        
        updateAssigneViews()
    }
    
    fileprivate func transitionToCompactView() {
        textContainerLeftConstraint.constant = QIssueTableViewCell.textContainerLeftPaddingWithoutImage
        //closedImageViewTopConstraint.constant = QIssueTableViewCell.closedImageViewTopPaddingCompactMode
        closedImageViewLeftConstraint.constant = QIssueTableViewCell.closedImageViewLeftPaddingCompactMode
        
        closedImageViewTopConstraint.isActive = false
        closedImageViewCenterYConstraint = closedIssueImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        
        if let closedImageViewCenterYConstraint = closedImageViewCenterYConstraint {
            closedImageViewCenterYConstraint.isActive = true
        }
        
        updateAssigneViews()
    }
    
    // MARK: - setup
    
    fileprivate func setup() {
        QIssueStore.add(self)
        QIssueNotificationStore.add(self)
        
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaults.PreferenceConstant.layoutMode, options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == UserDefaults.PreferenceConstant.layoutMode {
            viewType = UserDefaults.layoutModePreference()
        }
    }
    
    override func drawSelection(in dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .none {
            let rect = NSInsetRect(self.bounds, 0, 0)
            QIssueTableViewCell.selectionColor.setFill()
            let selectionPath = NSBezierPath(roundedRect: rect, xRadius: 0, yRadius: 0)
            selectionPath.fill()
        }
    }
    
    /// Override to change colour of background on selected items in table view
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if isSelected == true {
            CashewColor.selectedBackgroundColor().setFill()
            dirtyRect.fill()
        }
    }
    
    // MARK: - colours
    
    var titleLabelColor: NSColor {
        get {
            let themeMode = UserDefaults.themeMode()
            if themeMode == .light {
                return LightModeColor.sharedInstance.foregroundSecondaryColor()
            } else if themeMode == .dark {
                return DarkModeColor.sharedInstance.foregroundSecondaryColor()
            }
            return NSColor(calibratedWhite: 0, alpha: 0.80)
        }
    }
    
    var subtitleLabelColor: NSColor {
        get {
            let themeMode = UserDefaults.themeMode()
            if themeMode == .light {
                return LightModeColor.sharedInstance.foregroundTertiaryColor()
            } else if themeMode == .dark {
                return DarkModeColor.sharedInstance.foregroundTertiaryColor()
            }
            
            return NSColor(calibratedWhite: 0, alpha: 0.60)
        }
    }
    
    var titleLabelSelectedColor = CashewColor.foregroundColor()
    var subtitleLabelSelectedColor = CashewColor.foregroundColor()
    
    var subtitleRepoMilestoneColor: NSColor {
        get {
            let themeMode = UserDefaults.themeMode()
            if themeMode == .light {
                return LightModeColor.sharedInstance.foregroundTertiaryColor()
            } else if themeMode == .dark {
                return DarkModeColor.sharedInstance.foregroundTertiaryColor()
            }
            
            return NSColor(calibratedWhite: 0, alpha: 0.40)
        }
    }
    
    fileprivate static let repoMilestoneSelectedDarkColor = NSColor(calibratedWhite: 200/255.0, alpha: 1.0)
    fileprivate static let repoMilestoneSelectedLightColor = CashewColor.foregroundColor()
    
    var subtitleRepoMilestoneSelectedColor: NSColor {
        get {
            let themeMode = UserDefaults.themeMode()
            if themeMode == .light {
                return QIssueTableViewCell.repoMilestoneSelectedLightColor
            } else if themeMode == .dark {
                return QIssueTableViewCell.repoMilestoneSelectedDarkColor
            }
            
            return NSColor(calibratedWhite: 83/255.0, alpha: 1.0)
        }
    }
    
    
    fileprivate static let imageCache: [String: NSImage] = {
        var dict = [String: NSImage]()
        
        let repoImage = NSImage(named: NSImage.Name(rawValue: "repo"))!
        repoImage.size = NSSize(width: 9.0, height: 12.0)
        
        let milestoneImage = NSImage(named: NSImage.Name(rawValue: "milestone"))!
        milestoneImage.size = NSSize(width: 10.0, height: 12.0)
        
        dict["repo-small-light-selected"] = repoImage.withTintColor(QIssueTableViewCell.repoMilestoneSelectedLightColor)
        dict["repo-small-light"] = repoImage.withTintColor(LightModeColor.sharedInstance.foregroundTertiaryColor())
        
        dict["repo-small-dark-selected"] = repoImage.withTintColor(QIssueTableViewCell.repoMilestoneSelectedDarkColor)
        dict["repo-small-dark"] = repoImage.withTintColor(DarkModeColor.sharedInstance.foregroundTertiaryColor())
        
        dict["milestone-small-light-selected"] = milestoneImage.withTintColor(QIssueTableViewCell.repoMilestoneSelectedLightColor)
        dict["milestone-small-light"] = milestoneImage.withTintColor(LightModeColor.sharedInstance.foregroundTertiaryColor())
        
        dict["milestone-small-dark-selected"] = milestoneImage.withTintColor(QIssueTableViewCell.repoMilestoneSelectedDarkColor)
        dict["milestone-small-dark"] = milestoneImage.withTintColor(DarkModeColor.sharedInstance.foregroundTertiaryColor())
        
        return dict
    }()
    
    fileprivate var repoImage: NSImage {
        get {
            let themeMode = UserDefaults.themeMode()
            if themeMode == .light {
                return QIssueTableViewCell.imageCache["repo-small-light"]!
            } else if themeMode == .dark {
                return QIssueTableViewCell.imageCache["repo-small-dark"]!
            }
            
            return NSImage(named: NSImage.Name(rawValue: "repo-small"))!
        }
    }
    
    fileprivate var selectedRepoImage: NSImage {
        get {
            let themeMode = UserDefaults.themeMode()
            if themeMode == .light {
                return QIssueTableViewCell.imageCache["repo-small-light-selected"]!
            } else if themeMode == .dark {
                return QIssueTableViewCell.imageCache["repo-small-dark-selected"]!
            }
            
            return NSImage(named: NSImage.Name(rawValue: "repo-small-selected"))!
        }
    }
    
    fileprivate var milestoneImage: NSImage {
        get {
            let themeMode = UserDefaults.themeMode()
            if themeMode == .light {
                return QIssueTableViewCell.imageCache["milestone-small-light"]!
            } else if themeMode == .dark {
                return QIssueTableViewCell.imageCache["milestone-small-dark"]!
            }
            
            return NSImage(named: NSImage.Name(rawValue: "milestone-small"))!
        }
    }
    
    fileprivate var selectedMilestoneImage: NSImage {
        get {
            let themeMode = UserDefaults.themeMode()
            if themeMode == .light {
                return QIssueTableViewCell.imageCache["milestone-small-light-selected"]!
            } else if themeMode == .dark {
                return QIssueTableViewCell.imageCache["milestone-small-dark-selected"]!
            }
            
            return NSImage(named: NSImage.Name(rawValue: "milestone-small-selected"))!
        }
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                titleLabel.textColor = titleLabelSelectedColor
                self.backgroundColor = CashewColor.selectedBackgroundColor()
                updatedAtLabel.textColor = subtitleRepoMilestoneSelectedColor
                readCircleView.backgroundColor = titleLabel.textColor
                
            } else {
                titleLabel.textColor = titleLabelColor
                self.backgroundColor = NSColor.white
                updatedAtLabel.textColor = subtitleRepoMilestoneColor
                readCircleView.backgroundColor = CashewColor.notificationDotColor()
            }
            
            subtitleLabel.attributedStringValue = subtitleTextForCurrentIssue()
            updateLabelsModeBasedOnSelectionAndHover()
        }
    }
    
    
    // private var _issue: QIssue?
    @objc var issue: QIssue? {
        
        didSet {
            SyncDispatchOnMainQueue { [weak self] in
                self?.didSetIssue()
            }
        }
    }
    
    fileprivate func didSetIssue() {
        
        guard let anIssue = self.issue else {
            subtitleLabel.stringValue = ""
            updatedAtLabel.stringValue = ""
            titleLabel.stringValue = ""
            assigneeImageView.setImageURL(nil)
            labelsView.labels = nil
            labelContainerHeightConstraint.constant = 0.0
            readCircleView.isHidden = true
            return
        }
        
        let subtitle = subtitleTextForCurrentIssue()
        subtitleLabel.attributedStringValue = subtitle
        let updated = anIssue.updatedAt as NSDate
        
        updatedAtLabel.stringValue = updated.timeAgoSimple(forWeekOrLessAndUserShortForm: true)
        let numberString = "#\(anIssue.number)"
        let titleString = "\(numberString) • \(anIssue.title)"
        titleLabel.stringValue = titleString
        
        updateAssigneViews()
        
        if anIssue.state == "closed" {
            openIssueImageView.isHidden = true
            closedIssueImageView.isHidden = false
        } else if anIssue.state == "open" {
            openIssueImageView.isHidden = false
            closedIssueImageView.isHidden = true
        }
        
        labelsView.labels = anIssue.labels
        if let labels = labelsView.labels , labels.count > 0 {
            labelContainerHeightConstraint.constant = QIssueTableViewCell.labelsViewHeight
        } else {
            labelContainerHeightConstraint.constant = 0.0
        }
        
        
        if let notification = anIssue.notification {
            readCircleView.isHidden = notification.read
        } else {
            readCircleView.isHidden = true
        }
        
        openIssueImageView.image = anIssue.type == "pull_request" ? QView.openPullRequestImage() : QView.openIssueImage();
        closedIssueImageView.image = anIssue.type == "pull_request" ? QView.closedPullRequestImage() : QView.openIssueImage();
        
        if anIssue.type == "pull_request" {
            let openPR = QView.openPullRequestImage()
            let closedPR = QView.closedPullRequestImage()
            
            openPR?.size = NSMakeSize(8, 10)
            closedPR?.size = NSMakeSize(8, 10)
            openIssueImageView.image = openPR
            closedIssueImageView.image = closedPR
            openIssueImageView.imageScaling = .scaleNone
            closedIssueImageView.imageScaling = .scaleNone
            openIssueImageView.layer?.borderColor = NSColor(calibratedRed: 90/255.0, green: 192/255.0, blue: 44/255.0, alpha: 1).cgColor
            closedIssueImageView.layer?.borderColor = NSColor(calibratedRed: 175/255.0, green: 25/255.0, blue: 0, alpha: 1).cgColor
        } else {
            openIssueImageView.image = QView.openIssueImage();
            closedIssueImageView.image = QView.closedIssueImage();
            openIssueImageView.imageScaling = .scaleProportionallyUpOrDown
            closedIssueImageView.imageScaling = .scaleProportionallyUpOrDown
            openIssueImageView.layer?.borderColor = CashewColor.backgroundColor().cgColor
            closedIssueImageView.layer?.borderColor = CashewColor.backgroundColor().cgColor
        }
    }
    
    fileprivate func updateAssigneViews() {
        switch viewType {
        case .noAssigneeImage:
            self.assigneeImageView.isHidden = true
            self.unassignedImageView.isHidden = true
        default:
            if let anAssignee = issue?.assignee {
                self.assigneeImageView.setImageURL(anAssignee.avatarURL)
                self.assigneeImageView.isHidden = false
                self.unassignedImageView.isHidden = true
            } else {
                self.assigneeImageView.setImageURL(nil)
                self.assigneeImageView.isHidden = true
                self.unassignedImageView.isHidden = false
            }
        }
    }
    
    fileprivate func subtitleTextForCurrentIssue() -> NSAttributedString {
        
        guard let issue = issue else { return NSAttributedString(string: "") }
        
        let subtitleTextColor = isSelected ? subtitleLabelSelectedColor : subtitleLabelColor
        let subtitleAttrString = NSMutableAttributedString(string: "Opened \(issue.createdAtTimeAgo) by \(issue.authorUsername)   ")
        let subtitleRange = NSMakeRange(0, subtitleAttrString.length)
        subtitleAttrString.addAttribute(NSAttributedStringKey.font, value: QIssueTableViewCell.subtitleFont, range: subtitleRange)
        subtitleAttrString.addAttribute(NSAttributedStringKey.foregroundColor, value: subtitleTextColor, range: subtitleRange)
        
        // repo
        let repoMilestoneTextColor = isSelected ? subtitleRepoMilestoneSelectedColor : subtitleRepoMilestoneColor
        let repoImageAttachment = NSTextAttachment()
        let attachmentCell = IssueTableViewCellTextAttachmentCell()
        attachmentCell.yOffset = 3
        repoImageAttachment.attachmentCell = attachmentCell
        
        let img = isSelected ? selectedRepoImage : repoImage
        attachmentCell.image = img
        
        let repoAttrString = NSMutableAttributedString()
        repoAttrString.append(NSAttributedString(attachment: repoImageAttachment))
        repoAttrString.append(NSAttributedString(string: " \(issue.repositoryName)"))
        
        
        let repoRange = NSMakeRange(0, repoAttrString.length)
        repoAttrString.addAttribute(NSAttributedStringKey.font, value: QIssueTableViewCell.subtitleRepoMilestoneFont, range: repoRange)
        repoAttrString.addAttribute(NSAttributedStringKey.foregroundColor, value: repoMilestoneTextColor, range: repoRange)
        subtitleAttrString.append(repoAttrString)
        
        // milestone
        if let _ = issue.milestone {
            let milestoneImageAttachment = NSTextAttachment()
            let attachmentCell = IssueTableViewCellTextAttachmentCell()
            attachmentCell.yOffset = 0
            milestoneImageAttachment.attachmentCell = attachmentCell
            
            let img = isSelected ? selectedMilestoneImage : milestoneImage
            attachmentCell.image = img
            
            let milestoneAttrString = NSMutableAttributedString()
            milestoneAttrString.append(NSAttributedString(string: "  "))
            milestoneAttrString.append(NSAttributedString(attachment: milestoneImageAttachment))
            milestoneAttrString.append(NSAttributedString(string: " \(issue.milestoneTitle)"))
            
            let milestoneRange = NSMakeRange(0, milestoneAttrString.length)
            milestoneAttrString.addAttribute(NSAttributedStringKey.font, value: QIssueTableViewCell.subtitleRepoMilestoneFont, range: milestoneRange)
            milestoneAttrString.addAttribute(NSAttributedStringKey.foregroundColor, value: repoMilestoneTextColor, range: milestoneRange)
            subtitleAttrString.append(milestoneAttrString)
        }
        
        let paragaphStyle = NSMutableParagraphStyle()
        paragaphStyle.lineBreakMode = .byTruncatingTail;
        subtitleAttrString.addAttribute(kCTParagraphStyleAttributeName as NSAttributedStringKey, value: paragaphStyle, range: NSMakeRange(0, subtitleAttrString.length))
        
        return subtitleAttrString
    }
    
    
    override func awakeFromNib() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        readCircleView.disableThemeObserver = true
        readCircleView.cornerRadius = readCircleView.frame.height / 2.0
        readCircleView.isHidden = true
        readCircleView.backgroundColor = NSColor.red
        readCircleView.toolTip = "Unread"
        
        assigneeImageView.disableThemeObserver = true
        assigneeImageView.backgroundColor = NSColor.clear
        self.assigneeImageView.cornerRadius = self.assigneeImageView.frame.height / 2.0
        //self.assigneeImageView.backgroundColor = NSColor(white: 222/255.0, alpha: 1)
        
        self.openIssueImageView.wantsLayer = true
        self.openIssueImageView.layer?.borderColor = NSColor.white.cgColor
        self.openIssueImageView.layer?.borderWidth = 1
        self.openIssueImageView.layer?.backgroundColor = NSColor.white.cgColor
        self.openIssueImageView.layer?.cornerRadius = self.openIssueImageView.frame.height / 2.0
        
        self.closedIssueImageView.wantsLayer = true
        self.closedIssueImageView.layer?.borderColor = NSColor.white.cgColor
        self.closedIssueImageView.layer?.borderWidth = 1
        self.closedIssueImageView.layer?.backgroundColor = NSColor.white.cgColor
        self.closedIssueImageView.layer?.cornerRadius = self.closedIssueImageView.frame.height / 2.0
        
        
        self.unassignedImageView.image = QView.defaultAvatarImage()
        self.unassignedImageView.wantsLayer = true
        self.unassignedImageView.layer?.masksToBounds = true
        self.unassignedImageView.layer?.backgroundColor = NSColor(white: 222/255.0, alpha: 1).cgColor
        CATransaction.commit()
        self.unassignedImageView.layer?.cornerRadius = self.assigneeImageView.frame.height / 2.0
        
        
        labelsView.translatesAutoresizingMaskIntoConstraints = false
        labelsContainerView.addSubview(labelsView)
        labelsView.leftAnchor.constraint(equalTo: labelsContainerView.leftAnchor).isActive = true
        labelsView.rightAnchor.constraint(equalTo: labelsContainerView.rightAnchor).isActive = true
        labelsView.topAnchor.constraint(equalTo: labelsContainerView.topAnchor).isActive = true
        labelsView.bottomAnchor.constraint(equalTo: labelsContainerView.bottomAnchor).isActive = true
        
        
        self.labelsContainerView.backgroundColor = NSColor.clear
        
        
        titleLabel.font = QIssueTableViewCell.titleLabelFont
        
        titlesContainerView.disableThemeObserver = true
        titlesContainerView.backgroundColor = NSColor.clear
        labelsContainerView.disableThemeObserver = true
        labelsContainerView.backgroundColor = NSColor.clear
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return;
            }
            if mode == .light {
                let color = LightModeColor.sharedInstance.backgroundColor().cgColor
                self?.openIssueImageView.layer?.borderColor = color
                self?.openIssueImageView.layer?.backgroundColor = color
                self?.closedIssueImageView.layer?.borderColor = color
                self?.closedIssueImageView.layer?.backgroundColor = color
                self?.backgroundColor = LightModeColor.sharedInstance.backgroundColor()
                
            } else if mode == .dark {
                let color = DarkModeColor.sharedInstance.backgroundColor().cgColor
                self?.openIssueImageView.layer?.borderColor = color
                self?.openIssueImageView.layer?.backgroundColor = color
                self?.closedIssueImageView.layer?.borderColor = color
                self?.closedIssueImageView.layer?.backgroundColor = color
                self?.backgroundColor = DarkModeColor.sharedInstance.backgroundColor()
            }
            
            self?.assigneeImageView.backgroundColor = self?.backgroundColor
            let selected = strongSelf.isSelected
            strongSelf.isSelected = selected
            //strongSelf.unassignedImageView.layer?.borderColor = CashewColor.foregroundSecondaryColor().CGColor
        }
        
        if viewType == .noAssigneeImage {
            transitionToCompactView()
        } else {
            transitionToStandardView()
        }
        
        titleLabel.allowsDefaultTighteningForTruncation = false
        subtitleLabel.allowsDefaultTighteningForTruncation = false
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = mouseTrackingArea {
            removeTrackingArea(trackingArea)
        }
        
        let trackingArea = NSTrackingArea(rect: bounds, options: [NSTrackingArea.Options.activeInKeyWindow, NSTrackingArea.Options.mouseEnteredAndExited] , owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea);
        self.mouseTrackingArea = trackingArea
    }
    
    override func mouseEntered(with theEvent: NSEvent) {
        updateLabelsModeBasedOnSelectionAndHover()
        //        labelsView.mode = .ColoredBackground
        //        NSAnimationContext.runAnimationGroup({ (context) in
        //            context.duration = 0.2
        //            self.labelContainerHeightConstraint.animator().constant = 0
        //            }, completionHandler: nil)
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        updateLabelsModeBasedOnSelectionAndHover()
        //        NSAnimationContext.runAnimationGroup({ (context) in
        //            context.duration = 0.2
        //            self.labelContainerHeightConstraint.animator().constant = 17
        //            }, completionHandler: nil)
    }
    
    fileprivate func updateLabelsModeBasedOnSelectionAndHover() {
        
        // let isMouseOver = isMouseOverCurrentView()
        
        if isSelected {
            labelsView.mode = .coloredBackground
        } else {
            labelsView.mode =  .coloredBackground //.ColoredForeground
        }
        
        //        switch (selected, isMouseOver) {
        //        case (true, true):
        //            labelsView.mode = .ColoredBackground
        //        case (false, false):
        //            labelsView.mode = .ColoredForeground
        //        case (true, false):
        //            labelsView.mode = .Gray
        //        case (false, true):
        //            labelsView.mode = .ColoredBackground
        //        }
        // toggleLabelsIfNeeded()
    }
    
    // TODO: HICHAM
    // 20 % BLACK
    // + SOME NUMBER
    // 8 padding
    
    
    // MARK: Layout
    
    @objc class func suggestedHeight() -> CGFloat {
        return 81.0
    }
    
    override func layout() {
        super.layout()
        
        if let assigneeTooltipTag = assigneeTooltipTag {
            removeToolTip(assigneeTooltipTag)
        }
        
        if let issueStatusTooltipTag = issueStatusTooltipTag {
            removeToolTip(issueStatusTooltipTag)
        }
        
        if let assigneeLeftEdgeTooltipTag = assigneeLeftEdgeTooltipTag {
            removeToolTip(assigneeLeftEdgeTooltipTag)
        }
        
        // DDLogDebug("leftEdgeRect = \(leftEdgeRect) \t rect = \(rect)")
        issueStatusTooltipTag = addToolTip(self.closedIssueImageView.frame, owner: self, userData: nil)
        
        if viewType == .standard {
            let rect = NSRect(x: assigneeImageView.frame.minX, y: assigneeImageView.frame.minY, width: assigneeImageView.frame.width - closedIssueImageView.frame.width, height: assigneeImageView.frame.height)
            let leftEdgeRect = NSRect(x: closedIssueImageView.frame.minX, y: assigneeImageView.frame.minY, width: closedIssueImageView.frame.width, height: assigneeImageView.frame.height - closedIssueImageView.frame.height)
            
            assigneeTooltipTag = addToolTip(rect, owner: self, userData: nil)
            assigneeLeftEdgeTooltipTag = addToolTip(leftEdgeRect, owner: self, userData: nil)
        }
    }
    
    override func view(_ view: NSView, stringForToolTip tag: NSView.ToolTipTag, point: NSPoint, userData data: UnsafeMutableRawPointer?) -> String {
        guard let issue = self.issue else { return "" }
        if  issueStatusTooltipTag == tag { //NSPointInRect(point, self.closedIssueImageView.frame) {
            switch viewType {
            case .noAssigneeImage:
                let state = issue.state == "open" ? "Open" : "Closed"
                if let assignee = self.issue?.assignee {
                    return "\(state) issue assigned to \(assignee.login)"
                } else {
                    return "Unassigned \(state.lowercased()) issue"
                }
            default:
                return issue.state == "open" ? "Open" : "Closed"
            }
        }
        
        if assigneeTooltipTag == tag || assigneeLeftEdgeTooltipTag == tag { //NSPointInRect(point, self.assigneeImageView.frame) {
            if let assignee = self.issue?.assignee {
                return "Assigned to \(assignee.login)"
            } else {
                return "Unassigned"
            }
        }
        
        return ""
    }
}



extension QIssueTableViewCell: QStoreObserver {
    
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {
        
    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        
        guard let anIssue = record as? QIssue, let currentIssue = self.issue , anIssue.isEqual(to: currentIssue) else { return }
        
        //        let newRecordHasNotification = anIssue.notification != nil
        //        let oldRecordHasNotification = self.issue?.notification != nil
        
        //        if let aNotification = anIssue.notification, currentNotification = currentIssue.notification where anIssue.isEqualToIssue(currentIssue) {
        //
        //            if aNotification.read == currentNotification.read && aNotification.reason == currentNotification.reason && aNotification.threadId == currentNotification.threadId && aNotification.updatedAt == currentNotification.updatedAt {
        //                return
        //            }
        //
        //        } else if  {
        //            return
        //        }
        
        DispatchOnMainQueue({
            self.issue = anIssue // forces cell update
        })
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {
        
    }
}

extension QIssueTableViewCell {
    class func instantiateFromNib() -> QIssueTableViewCell? {
        var viewArray: NSArray?
        let className = NSStringFromClass(QIssueTableViewCell.self).components(separatedBy: ".").last! as String
        
        //DDLogDebug(" viewType = %@", className)
        assert(Thread.isMainThread)
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: className), owner: nil, topLevelObjects: &viewArray)
        
        for view in viewArray as! [NSObject] {
            if object_getClass(view) == QIssueTableViewCell.self {
                return view as? QIssueTableViewCell
            }
        }
        
        return nil //viewArray!.objectAtIndex(1) as! T
    }
    
}
