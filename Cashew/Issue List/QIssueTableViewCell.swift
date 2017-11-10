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
    
    private var roundedCornerMask: CALayer?
    
    var shouldAllowVibrancy = true
    
    override var allowsVibrancy: Bool {
        return shouldAllowVibrancy
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let bezierPath = NSBezierPath(roundedRect: bounds, xRadius: CGRectGetWidth(bounds), yRadius: CGRectGetHeight(bounds))
        let maskLayer = CAShapeLayer()
        wantsLayer = true
        maskLayer.frame = bounds
        maskLayer.fillColor = NSColor.whiteColor().CGColor
        maskLayer.path = bezierPath.toCGPath()
        maskLayer.backgroundColor = NSColor.clearColor().CGColor
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
    @IBOutlet weak private var openIssueImageView: QIssueTableViewCellCircleImageView!
    @IBOutlet weak private var closedIssueImageView: QIssueTableViewCellCircleImageView!
    @IBOutlet weak private var assigneeImageView: BaseView!
    @IBOutlet weak private var titleLabel: IssueTableViewCellTextField!
    @IBOutlet weak private var subtitleLabel: IssueTableViewCellTextField!
    @IBOutlet weak private var updatedAtLabel: IssueTableViewCellTextField!
    @IBOutlet weak private var bottomLineView: BaseSeparatorView!
    @IBOutlet weak private var labelContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak private var labelsContainerView: BaseView!
    @IBOutlet weak private var titlesContainerView: BaseView!
    
    private var viewType: LayoutPreference = NSUserDefaults.layoutModePreference() {
        didSet {
            switch viewType {
            case .NoAssigneeImage:
                transitionToCompactView()
            default:
                transitionToStandardView()
            }
        }
    }
    
    private var labelsView = QIssueLabelContainerView()
    private var mouseTrackingArea: NSTrackingArea?
    private var issueStatusTooltipTag: NSToolTipTag?
    private var assigneeTooltipTag: NSToolTipTag?
    private var assigneeLeftEdgeTooltipTag: NSToolTipTag?
    
    // NSColor(red: 245/255.0 , green: 248/255.0 , blue: 247/255.0 , alpha: 1);
    private static let separatorLineHeight: CGFloat = 1.0
    
    private static let titleLabelFont = NSFont.systemFontOfSize(13, weight: NSFontWeightBold)
    private static let subtitleFont = NSFont.systemFontOfSize(12, weight: NSFontWeightRegular)
    
    private static let subtitleRepoMilestoneFont = NSFont.systemFontOfSize(11, weight: NSFontWeightMedium)
    
    private static let selectionColor = NSColor(calibratedRed: 62/255.0, green: 96/255.0, blue: 218/255.0, alpha: 1)
    
    private static let labelsViewHeight: CGFloat = 17.0
    
    private static let textContainerLeftPaddingWithImage: CGFloat = 80
    private static let textContainerLeftPaddingWithoutImage: CGFloat = 35
    
    private static let textContainerTopPaddingCompactMode: CGFloat = 12
    private static let textContainerTopPaddingStandardMode: CGFloat = 55
    
    private static let closedImageViewTopPaddingStandardMode: CGFloat = 55
    
    private static let closedImageViewLeftPaddingCompactMode: CGFloat = 12
    private static let closedImageViewLeftPaddingStandardMode: CGFloat = 48
    
    
    var shouldAllowVibrancy: Bool = true {
        didSet {
            [bottomLineView, labelsView, titlesContainerView, labelsView, readCircleView, assigneeImageView, labelsContainerView].forEach { (view) in
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
        QIssueStore.removeObserver(self)
        QIssueNotificationStore.removeObserver(self)
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: NSUserDefaults.PreferenceConstant.layoutMode) //, options: .New, context: nil)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder:coder)
        self.setup()
    }
    
    private func transitionToStandardView() {
        if let closedImageViewCenterYConstraint = closedImageViewCenterYConstraint {
            closedImageViewCenterYConstraint.active = false
        }
        
        textContainerLeftConstraint.constant = QIssueTableViewCell.textContainerLeftPaddingWithImage
        closedImageViewTopConstraint.active = true
        closedImageViewLeftConstraint.constant = QIssueTableViewCell.closedImageViewLeftPaddingStandardMode
        
        updateAssigneViews()
    }
    
    private func transitionToCompactView() {
        textContainerLeftConstraint.constant = QIssueTableViewCell.textContainerLeftPaddingWithoutImage
        //closedImageViewTopConstraint.constant = QIssueTableViewCell.closedImageViewTopPaddingCompactMode
        closedImageViewLeftConstraint.constant = QIssueTableViewCell.closedImageViewLeftPaddingCompactMode
        
        closedImageViewTopConstraint.active = false
        closedImageViewCenterYConstraint = closedIssueImageView.centerYAnchor.constraintEqualToAnchor(centerYAnchor)
        
        if let closedImageViewCenterYConstraint = closedImageViewCenterYConstraint {
            closedImageViewCenterYConstraint.active = true
        }
        
        updateAssigneViews()
    }
    
    private func setup() {
        QIssueStore.addObserver(self)
        QIssueNotificationStore.addObserver(self)
        
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: NSUserDefaults.PreferenceConstant.layoutMode, options: .New, context: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == NSUserDefaults.PreferenceConstant.layoutMode {
            viewType = NSUserDefaults.layoutModePreference()
        }
    }
    
    override func drawSelectionInRect(dirtyRect: NSRect) {
        if self.selectionHighlightStyle != .None {
            let rect = NSInsetRect(self.bounds, 0, 0)
            QIssueTableViewCell.selectionColor.setFill()
            let selectionPath = NSBezierPath(roundedRect: rect, xRadius: 0, yRadius: 0)
            selectionPath.fill()
        }
    }
    
    var titleLabelColor: NSColor {
        get {
            let themeMode = NSUserDefaults.themeMode()
            if themeMode == .Light {
                return LightModeColor.sharedInstance.foregroundColor()
            } else if themeMode == .Dark {
                return DarkModeColor.sharedInstance.foregroundColor()
            }
            return NSColor(calibratedWhite: 0, alpha: 0.80)
        }
    }
    
    var subtitleLabelColor: NSColor {
        get {
            let themeMode = NSUserDefaults.themeMode()
            if themeMode == .Light {
                return LightModeColor.sharedInstance.foregroundSecondaryColor()
            } else if themeMode == .Dark {
                return DarkModeColor.sharedInstance.foregroundSecondaryColor()
            }
            
            return NSColor(calibratedWhite: 0, alpha: 0.60)
        }
    }
    
    var titleLabelSelectedColor = NSColor(calibratedWhite: 1, alpha: 1) //NSColor(calibratedWhite: 255/255.0, alpha: 1.0)
    var subtitleLabelSelectedColor = NSColor(calibratedWhite: 1, alpha: 0.80) // NSColor(calibratedWhite: 255.0/255.0, alpha: 0.80)
    
    var subtitleRepoMilestoneColor: NSColor {
        get {
            let themeMode = NSUserDefaults.themeMode()
            if themeMode == .Light {
                return LightModeColor.sharedInstance.foregroundTertiaryColor()
            } else if themeMode == .Dark {
                return DarkModeColor.sharedInstance.foregroundTertiaryColor()
            }
            
            return NSColor(calibratedWhite: 0, alpha: 0.40)
        }
    }
    
    private static let repoMilestoneSelectedDarkColor = NSColor(calibratedWhite: 200/255.0, alpha: 1.0)
    private static let repoMilestoneSelectedLightColor = NSColor(calibratedWhite: 220/255.0, alpha: 1.0)
    
    var subtitleRepoMilestoneSelectedColor: NSColor {
        get {
            let themeMode = NSUserDefaults.themeMode()
            if themeMode == .Light {
                return QIssueTableViewCell.repoMilestoneSelectedLightColor
            } else if themeMode == .Dark {
                return QIssueTableViewCell.repoMilestoneSelectedDarkColor
            }
            
            return NSColor(calibratedWhite: 83/255.0, alpha: 1.0)
        }
    }
    
    
    private static let imageCache: [String: NSImage] = {
        var dict = [String: NSImage]()
        
        let repoImage = NSImage(named: "repo")!
        repoImage.size = NSSize(width: 9.0, height: 12.0)
        
        let milestoneImage = NSImage(named: "milestone")!
        milestoneImage.size = NSSize(width: 10.0, height: 12.0)
        
        dict["repo-small-light-selected"] = repoImage.imageWithTintColor(QIssueTableViewCell.repoMilestoneSelectedLightColor)
        dict["repo-small-light"] = repoImage.imageWithTintColor(LightModeColor.sharedInstance.foregroundTertiaryColor())
        
        dict["repo-small-dark-selected"] = repoImage.imageWithTintColor(QIssueTableViewCell.repoMilestoneSelectedDarkColor)
        dict["repo-small-dark"] = repoImage.imageWithTintColor(DarkModeColor.sharedInstance.foregroundTertiaryColor())
        
        dict["milestone-small-light-selected"] = milestoneImage.imageWithTintColor(QIssueTableViewCell.repoMilestoneSelectedLightColor)
        dict["milestone-small-light"] = milestoneImage.imageWithTintColor(LightModeColor.sharedInstance.foregroundTertiaryColor())
        
        dict["milestone-small-dark-selected"] = milestoneImage.imageWithTintColor(QIssueTableViewCell.repoMilestoneSelectedDarkColor)
        dict["milestone-small-dark"] = milestoneImage.imageWithTintColor(DarkModeColor.sharedInstance.foregroundTertiaryColor())
        
        return dict
    }()
    
    private var repoImage: NSImage {
        get {
            let themeMode = NSUserDefaults.themeMode()
            if themeMode == .Light {
                return QIssueTableViewCell.imageCache["repo-small-light"]!
            } else if themeMode == .Dark {
                return QIssueTableViewCell.imageCache["repo-small-dark"]!
            }
            
            return NSImage(named: "repo-small")!
        }
    }
    
    private var selectedRepoImage: NSImage {
        get {
            let themeMode = NSUserDefaults.themeMode()
            if themeMode == .Light {
                return QIssueTableViewCell.imageCache["repo-small-light-selected"]!
            } else if themeMode == .Dark {
                return QIssueTableViewCell.imageCache["repo-small-dark-selected"]!
            }
            
            return NSImage(named: "repo-small-selected")!
        }
    }
    
    private var milestoneImage: NSImage {
        get {
            let themeMode = NSUserDefaults.themeMode()
            if themeMode == .Light {
                return QIssueTableViewCell.imageCache["milestone-small-light"]!
            } else if themeMode == .Dark {
                return QIssueTableViewCell.imageCache["milestone-small-dark"]!
            }
            
            return NSImage(named: "milestone-small")!
        }
    }
    
    private var selectedMilestoneImage: NSImage {
        get {
            let themeMode = NSUserDefaults.themeMode()
            if themeMode == .Light {
                return QIssueTableViewCell.imageCache["milestone-small-light-selected"]!
            } else if themeMode == .Dark {
                return QIssueTableViewCell.imageCache["milestone-small-dark-selected"]!
            }
            
            return NSImage(named: "milestone-small-selected")!
        }
    }
    
    override var selected: Bool {
        didSet {
            if selected {
                titleLabel.textColor = titleLabelSelectedColor
                updatedAtLabel.textColor = subtitleRepoMilestoneSelectedColor
                readCircleView.backgroundColor = titleLabel.textColor
                
            } else {
                titleLabel.textColor = titleLabelColor
                updatedAtLabel.textColor = subtitleRepoMilestoneColor
                readCircleView.backgroundColor = CashewColor.notificationDotColor()
            }
            bottomLineView.selected = selected
            
            subtitleLabel.attributedStringValue = subtitleTextForCurrentIssue()
            updateLabelsModeBasedOnSelectionAndHover()
        }
    }
    
    
    // private var _issue: QIssue?
    var issue: QIssue? {
        
        didSet {
            SyncDispatchOnMainQueue { [weak self] in
                self?.didSetIssue()
            }
        }
    }
    
    private func didSetIssue() {
        
        guard let anIssue = self.issue else {
            subtitleLabel.stringValue = ""
            updatedAtLabel.stringValue = ""
            titleLabel.stringValue = ""
            assigneeImageView.setImageURL(nil)
            labelsView.labels = nil
            labelContainerHeightConstraint.constant = 0.0
            readCircleView.hidden = true
            return
        }
        
        #if DEBUG
            
        #else
  
            CLSLogv("account=[%@]",    getVaList([anIssue.account ?? "<null>"]));
            CLSLogv("repository=[%@]", getVaList([anIssue.repository ?? "<null>"]));
            CLSLogv("repository.name=[%@]", getVaList([anIssue.repository.name ?? "<null>"]));
            CLSLogv("user=[%@]", getVaList([anIssue.user ?? "<null>"]));
            CLSLogv("user.login=[%@]", getVaList([anIssue.user.login ?? "<null>"]));
            CLSLogv("assignee=[%@]", getVaList([anIssue.assignee?.login ?? "<null>"]));
            CLSLogv("milestone=[%@]", getVaList([anIssue.milestone?.title ?? "<null>"]));
            CLSLogv("labels=[%@]", getVaList([anIssue.labels  ?? "<null>"]));
            CLSLogv("title=[%@]", getVaList([anIssue.title  ?? "<null>"]));
            CLSLogv("number=[%@]", getVaList([anIssue.number  ?? "<null>"]));
            CLSLogv("identifier=[%@]", getVaList([anIssue.identifier  ?? "<null>"]));
            CLSLogv("createdAt=[%@]", getVaList([anIssue.createdAt  ?? "<null>"]));
            CLSLogv("closedAt=[%@]", getVaList([anIssue.closedAt  ?? "<null>"]));
            CLSLogv("updatedAt=[%@]", getVaList([anIssue.updatedAt  ?? "<null>"]));
            CLSLogv("body=[%@]", getVaList([anIssue.body  ?? "<null>"]));
            CLSLogv("state=[%@]", getVaList([anIssue.state  ?? "<null>"]));
            CLSLogv("notification=[%@]", getVaList([anIssue.notification  ?? "<null>"]));
            CLSLogv("htmlURL=[%@]", getVaList([anIssue.htmlURL  ?? "<null>"]));
            CLSLogv("type=[%@]", getVaList([anIssue.type  ?? "<null>"]));

        #endif
        
        
        let subtitle = subtitleTextForCurrentIssue()
        subtitleLabel.attributedStringValue = subtitle
        
        updatedAtLabel.stringValue = anIssue.updatedAt.timeAgoSimpleForWeekOrLessAndUserShortForm(true)
        titleLabel.stringValue = anIssue.title
        
        updateAssigneViews()
        
        if anIssue.state == "closed" {
            openIssueImageView.hidden = true
            closedIssueImageView.hidden = false
        } else if anIssue.state == "open" {
            openIssueImageView.hidden = false
            closedIssueImageView.hidden = true
        }
        
        labelsView.labels = anIssue.labels
        if let labels = labelsView.labels where labels.count > 0 {
            labelContainerHeightConstraint.constant = QIssueTableViewCell.labelsViewHeight
        } else {
            labelContainerHeightConstraint.constant = 0.0
        }
        
        
        if let notification = anIssue.notification {
            readCircleView.hidden = notification.read
        } else {
            readCircleView.hidden = true
        }
        
        openIssueImageView.image = anIssue.type == "pull_request" ? QView.openPullRequestImage() : QView.openIssueImage();
        closedIssueImageView.image = anIssue.type == "pull_request" ? QView.closedPullRequestImage() : QView.openIssueImage();
        
        if anIssue.type == "pull_request" {
            let openPR = QView.openPullRequestImage()
            let closedPR = QView.closedPullRequestImage()
            
            openPR.size = NSMakeSize(8, 10)
            closedPR.size = NSMakeSize(8, 10)
            openIssueImageView.image = openPR
            closedIssueImageView.image = closedPR
            openIssueImageView.imageScaling = .ScaleNone
            closedIssueImageView.imageScaling = .ScaleNone
            openIssueImageView.layer?.borderColor = NSColor(calibratedRed: 90/255.0, green: 192/255.0, blue: 44/255.0, alpha: 1).CGColor
            closedIssueImageView.layer?.borderColor = NSColor(calibratedRed: 175/255.0, green: 25/255.0, blue: 0, alpha: 1).CGColor
        } else {
            openIssueImageView.image = QView.openIssueImage();
            closedIssueImageView.image = QView.closedIssueImage();
            openIssueImageView.imageScaling = .ScaleProportionallyUpOrDown
            closedIssueImageView.imageScaling = .ScaleProportionallyUpOrDown
            openIssueImageView.layer?.borderColor = CashewColor.backgroundColor().CGColor
            closedIssueImageView.layer?.borderColor = CashewColor.backgroundColor().CGColor
        }
    }
    
    private func updateAssigneViews() {
        switch viewType {
        case .NoAssigneeImage:
            self.assigneeImageView.hidden = true
            self.unassignedImageView.hidden = true
        default:
            if let anAssignee = issue?.assignee {
                self.assigneeImageView.setImageURL(anAssignee.avatarURL)
                self.assigneeImageView.hidden = false
                self.unassignedImageView.hidden = true
            } else {
                self.assigneeImageView.setImageURL(nil)
                self.assigneeImageView.hidden = true
                self.unassignedImageView.hidden = false
            }
        }
    }
    
    private func subtitleTextForCurrentIssue() -> NSAttributedString {
        
        guard let issue = issue else { return NSAttributedString(string: "") }
        
        let subtitleTextColor = selected ? subtitleLabelSelectedColor : subtitleLabelColor
        let subtitleAttrString = NSMutableAttributedString(string: "#\(issue.number) • Opened \(issue.createdAtTimeAgo) by \(issue.authorUsername)   ")
        let subtitleRange = NSMakeRange(0, subtitleAttrString.length)
        subtitleAttrString.addAttribute(NSFontAttributeName, value: QIssueTableViewCell.subtitleFont, range: subtitleRange)
        subtitleAttrString.addAttribute(NSForegroundColorAttributeName, value: subtitleTextColor, range: subtitleRange)
        
        // repo
        let repoMilestoneTextColor = selected ? subtitleRepoMilestoneSelectedColor : subtitleRepoMilestoneColor
        let repoImageAttachment = NSTextAttachment()
        let attachmentCell = IssueTableViewCellTextAttachmentCell()
        attachmentCell.yOffset = 3
        repoImageAttachment.attachmentCell = attachmentCell
        
        let img = selected ? selectedRepoImage : repoImage
        attachmentCell.image = img
        
        let repoAttrString = NSMutableAttributedString()
        repoAttrString.appendAttributedString(NSAttributedString(attachment: repoImageAttachment))
        repoAttrString.appendAttributedString(NSAttributedString(string: " \(issue.repositoryName)"))
        
        
        let repoRange = NSMakeRange(0, repoAttrString.length)
        repoAttrString.addAttribute(NSFontAttributeName, value: QIssueTableViewCell.subtitleRepoMilestoneFont, range: repoRange)
        repoAttrString.addAttribute(NSForegroundColorAttributeName, value: repoMilestoneTextColor, range: repoRange)
        subtitleAttrString.appendAttributedString(repoAttrString)
        
        // milestone
        if let _ = issue.milestone {
            let milestoneImageAttachment = NSTextAttachment()
            let attachmentCell = IssueTableViewCellTextAttachmentCell()
            attachmentCell.yOffset = 0
            milestoneImageAttachment.attachmentCell = attachmentCell
            
            let img = selected ? selectedMilestoneImage : milestoneImage
            attachmentCell.image = img
            
            let milestoneAttrString = NSMutableAttributedString()
            milestoneAttrString.appendAttributedString(NSAttributedString(string: "  "))
            milestoneAttrString.appendAttributedString(NSAttributedString(attachment: milestoneImageAttachment))
            milestoneAttrString.appendAttributedString(NSAttributedString(string: " \(issue.milestoneTitle)"))
            
            let milestoneRange = NSMakeRange(0, milestoneAttrString.length)
            milestoneAttrString.addAttribute(NSFontAttributeName, value: QIssueTableViewCell.subtitleRepoMilestoneFont, range: milestoneRange)
            milestoneAttrString.addAttribute(NSForegroundColorAttributeName, value: repoMilestoneTextColor, range: milestoneRange)
            subtitleAttrString.appendAttributedString(milestoneAttrString)
        }
        
        let paragaphStyle = NSMutableParagraphStyle()
        paragaphStyle.lineBreakMode = .ByTruncatingTail;
        subtitleAttrString.addAttribute(NSParagraphStyleAttributeName, value: paragaphStyle, range: NSMakeRange(0, subtitleAttrString.length))
        
        return subtitleAttrString
    }
    
    
    override func awakeFromNib() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        readCircleView.disableThemeObserver = true
        readCircleView.cornerRadius = readCircleView.frame.height / 2.0
        readCircleView.hidden = true
        readCircleView.backgroundColor = NSColor.redColor()
        readCircleView.toolTip = "Unread"
        
        assigneeImageView.disableThemeObserver = true
        assigneeImageView.backgroundColor = NSColor.clearColor()
        self.assigneeImageView.cornerRadius = CGRectGetHeight(self.assigneeImageView.frame) / 2.0
        //self.assigneeImageView.backgroundColor = NSColor(white: 222/255.0, alpha: 1)
        
        self.openIssueImageView.wantsLayer = true
        self.openIssueImageView.layer?.borderColor = NSColor.whiteColor().CGColor
        self.openIssueImageView.layer?.borderWidth = 1
        self.openIssueImageView.layer?.backgroundColor = NSColor.whiteColor().CGColor
        self.openIssueImageView.layer?.cornerRadius = CGRectGetHeight(self.openIssueImageView.frame) / 2.0
        
        self.closedIssueImageView.wantsLayer = true
        self.closedIssueImageView.layer?.borderColor = NSColor.whiteColor().CGColor
        self.closedIssueImageView.layer?.borderWidth = 1
        self.closedIssueImageView.layer?.backgroundColor = NSColor.whiteColor().CGColor
        self.closedIssueImageView.layer?.cornerRadius = CGRectGetHeight(self.closedIssueImageView.frame) / 2.0
        
        
        self.unassignedImageView.image = QView.defaultAvatarImage()
        self.unassignedImageView.wantsLayer = true
        self.unassignedImageView.layer?.masksToBounds = true
        self.unassignedImageView.layer?.backgroundColor = NSColor(white: 222/255.0, alpha: 1).CGColor
        CATransaction.commit()
        self.unassignedImageView.layer?.cornerRadius = CGRectGetHeight(self.assigneeImageView.frame) / 2.0
        
        
        labelsView.translatesAutoresizingMaskIntoConstraints = false
        labelsContainerView.addSubview(labelsView)
        labelsView.leftAnchor.constraintEqualToAnchor(labelsContainerView.leftAnchor).active = true
        labelsView.rightAnchor.constraintEqualToAnchor(labelsContainerView.rightAnchor).active = true
        labelsView.topAnchor.constraintEqualToAnchor(labelsContainerView.topAnchor).active = true
        labelsView.bottomAnchor.constraintEqualToAnchor(labelsContainerView.bottomAnchor).active = true
        
        
        self.labelsContainerView.backgroundColor = NSColor.clearColor()
        
        
        titleLabel.font = QIssueTableViewCell.titleLabelFont
        
        titlesContainerView.disableThemeObserver = true
        titlesContainerView.backgroundColor = NSColor.clearColor()
        labelsContainerView.disableThemeObserver = true
        labelsContainerView.backgroundColor = NSColor.clearColor()
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return;
            }
            if mode == .Light {
                let color = LightModeColor.sharedInstance.backgroundColor().CGColor
                self?.openIssueImageView.layer?.borderColor = color
                self?.openIssueImageView.layer?.backgroundColor = color
                self?.closedIssueImageView.layer?.borderColor = color
                self?.closedIssueImageView.layer?.backgroundColor = color
                self?.backgroundColor = LightModeColor.sharedInstance.backgroundColor()
                
            } else if mode == .Dark {
                let color = DarkModeColor.sharedInstance.backgroundColor().CGColor
                self?.openIssueImageView.layer?.borderColor = color
                self?.openIssueImageView.layer?.backgroundColor = color
                self?.closedIssueImageView.layer?.borderColor = color
                self?.closedIssueImageView.layer?.backgroundColor = color
                self?.backgroundColor = DarkModeColor.sharedInstance.backgroundColor()
            }
            
            self?.assigneeImageView.backgroundColor = self?.backgroundColor
            let selected = strongSelf.selected
            strongSelf.selected = selected
            //strongSelf.unassignedImageView.layer?.borderColor = CashewColor.foregroundSecondaryColor().CGColor
        }
        
        if viewType == .NoAssigneeImage {
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
        
        let trackingArea = NSTrackingArea(rect: bounds, options: [NSTrackingAreaOptions.ActiveInKeyWindow, NSTrackingAreaOptions.MouseEnteredAndExited] , owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea);
        self.mouseTrackingArea = trackingArea
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        updateLabelsModeBasedOnSelectionAndHover()
        //        labelsView.mode = .ColoredBackground
        //        NSAnimationContext.runAnimationGroup({ (context) in
        //            context.duration = 0.2
        //            self.labelContainerHeightConstraint.animator().constant = 0
        //            }, completionHandler: nil)
    }
    
    override func mouseExited(theEvent: NSEvent) {
        updateLabelsModeBasedOnSelectionAndHover()
        //        NSAnimationContext.runAnimationGroup({ (context) in
        //            context.duration = 0.2
        //            self.labelContainerHeightConstraint.animator().constant = 17
        //            }, completionHandler: nil)
    }
    
    private func updateLabelsModeBasedOnSelectionAndHover() {
        
        // let isMouseOver = isMouseOverCurrentView()
        
        if selected {
            labelsView.mode = .ColoredBackground
        } else {
            labelsView.mode =  .ColoredBackground //.ColoredForeground
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
    
    class func suggestedHeight() -> CGFloat {
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
        issueStatusTooltipTag = addToolTipRect(self.closedIssueImageView.frame, owner: self, userData: nil)
        
        if viewType == .Standard {
            let rect = NSRect(x: assigneeImageView.frame.minX, y: assigneeImageView.frame.minY, width: assigneeImageView.frame.width - closedIssueImageView.frame.width, height: assigneeImageView.frame.height)
            let leftEdgeRect = NSRect(x: closedIssueImageView.frame.minX, y: assigneeImageView.frame.minY, width: closedIssueImageView.frame.width, height: assigneeImageView.frame.height - closedIssueImageView.frame.height)
            
            assigneeTooltipTag = addToolTipRect(rect, owner: self, userData: nil)
            assigneeLeftEdgeTooltipTag = addToolTipRect(leftEdgeRect, owner: self, userData: nil)
        }
    }
    
    override func view(view: NSView, stringForToolTip tag: NSToolTipTag, point: NSPoint, userData data: UnsafeMutablePointer<Void>) -> String {
        guard let issue = self.issue else { return "" }
        if  issueStatusTooltipTag == tag { //NSPointInRect(point, self.closedIssueImageView.frame) {
            switch viewType {
            case .NoAssigneeImage:
                let state = issue.state == "open" ? "Open" : "Closed"
                if let assignee = self.issue?.assignee {
                    return "\(state) issue assigned to \(assignee.login)"
                } else {
                    return "Unassigned \(state.lowercaseString) issue"
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
    
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {
        
    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        
        guard let anIssue = record as? QIssue, currentIssue = self.issue where anIssue.isEqualToIssue(currentIssue) else { return }
        
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
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {
        
    }
}

extension QIssueTableViewCell {
    class func instantiateFromNib() -> QIssueTableViewCell? {
        var viewArray: NSArray?
        let className = NSStringFromClass(QIssueTableViewCell).componentsSeparatedByString(".").last! as String
        
        //DDLogDebug(" viewType = %@", className)
        assert(NSThread.isMainThread())
        NSBundle.mainBundle().loadNibNamed(className, owner: nil, topLevelObjects: &viewArray)
        
        for view in viewArray as! [NSObject] {
            if object_getClass(view) == QIssueTableViewCell.self {
                return view as? QIssueTableViewCell
            }
        }
        
        return nil //viewArray!.objectAtIndex(1) as! T
    }
    
}
