//
//  IssueEventTableViewCell.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/27/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class IssueEventTableViewCell: BaseView {
    
    fileprivate static let verticalPadding: CGFloat = 10.0
    fileprivate static let spacingOccupiedByHorizontalPaddingAndImageView: CGFloat = 37.0
    fileprivate static let eventNameBoldedAttribute: [NSAttributedStringKey : Any] = [NSAttributedStringKey.font: NSFont.systemFont(ofSize: 13, weight: NSFont.Weight.semibold)]
    
    @IBOutlet weak var eventDetailsLabel: NSTextField!
    @IBOutlet weak var eventImageView: NSImageView!
    @IBOutlet weak var eventImageContainerView: BaseView!
    
    @objc var onHeightChanged: (()->())?
    
    @objc var issueEvent: IssueEventInfo? {
        didSet {
            didSetIssueEvent()
        }
    }
    
    fileprivate func didSetIssueEvent() {
        assert(Thread.isMainThread, "not on main thread");
        if let issueEvent = issueEvent {
            eventDetailsLabel.attributedStringValue = IssueEventTableViewCell.detailsForIssueEvent(issueEvent)
        } else {
            eventDetailsLabel.stringValue = ""
        }
        setupImageForCurrentIssueEvent()
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        eventImageContainerView.disableThemeObserver = true
        eventImageContainerView.backgroundColor = NSColor(calibratedWhite: 240/255.0, alpha:1.0);
        
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(strongSelf)
                return;
            }
            
            strongSelf.eventDetailsLabel.font = NSFont.systemFont(ofSize: 13, weight: .light)
            if mode == .light {
                strongSelf.backgroundColor = LightModeColor.sharedInstance.backgroundColor()
                strongSelf.eventDetailsLabel.textColor = LightModeColor.sharedInstance.foregroundSecondaryColor()
            } else if mode == .dark {
                strongSelf.backgroundColor = DarkModeColor.sharedInstance.backgroundColor()
                strongSelf.eventDetailsLabel.textColor = DarkModeColor.sharedInstance.foregroundSecondaryColor()
            }
            
            strongSelf.didSetIssueEvent()
        }
    }
    
    fileprivate class func boldedAttribute() -> [NSAttributedStringKey : NSObject]  {
        
        let themeMode = UserDefaults.themeMode()
        
        var color = NSColor(calibratedWhite: 67/255.0, alpha: 0.85)
        if (themeMode == .light) {
            color = LightModeColor.sharedInstance.foregroundSecondaryColor()
        } else if (themeMode == .dark) {
            color = DarkModeColor.sharedInstance.foregroundSecondaryColor()
        }
        
        let attr = [NSAttributedStringKey.font.rawValue: NSFont.systemFont(ofSize: 13, weight: NSFont.Weight.semibold), NSAttributedStringKey.foregroundColor: color] as [AnyHashable : NSObject]
        return attr as! [NSAttributedStringKey : NSObject]
    }
    
    deinit {
        onHeightChanged = nil
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    fileprivate func setupImageForCurrentIssueEvent() {
        DispatchQueue.main.async { () -> Void in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if let event = self.issueEvent, let eventImageView = self.eventImageView {
                let color = NSColor.init(calibratedRed: 148/255.0, green: 148/255.0, blue: 148/255.0, alpha: 1)
                
                eventImageView.layer?.backgroundColor = NSColor.clear.cgColor
                
                switch(event.event!) {
                case "labeled", "unlabeled":
                    eventImageView.image = NSImage(named: NSImage.Name(rawValue: "tag"))!.withTintColor(color)
                case "milestoned", "demilestoned":
                    eventImageView.image = NSImage(named: NSImage.Name(rawValue: "milestone"))!.withTintColor(color)
                case "renamed":
                    eventImageView.image = NSImage(named: NSImage.Name(rawValue: "pencil"))!.withTintColor(color)
                case "assigned", "unassigned":
                    eventImageView.image = NSImage(named: NSImage.Name(rawValue: "person"))!.withTintColor(color)
                case "closed":
                    eventImageView.image = NSImage(named: NSImage.Name(rawValue: "issue-closed"))!.withTintColor(NSColor.white)
                    eventImageView.layer?.backgroundColor = NSColor.init(calibratedRed: 175/255.0, green: 25/255.0, blue: 0, alpha: 1).cgColor
                case "reopened":
                    eventImageView.image = NSImage(named: NSImage.Name(rawValue: "issue-reopened"))!.withTintColor(NSColor.white)
                    eventImageView.layer?.backgroundColor = NSColor.init(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1).cgColor
                default:
                    eventImageView.image = nil
                }
                
            } else {
                self.eventImageView.image = nil
            }
            CATransaction.commit()
        }
    }
    
    class func heightForIssueEvent(_ event: IssueEventInfo, width: CGFloat) -> CGFloat {
        let attrString = IssueEventTableViewCell.detailsForIssueEvent(event)
        let containerSize = CGSize(width: width - IssueEventTableViewCell.spacingOccupiedByHorizontalPaddingAndImageView, height: CGFloat.greatestFiniteMagnitude)
        let attrStringSize = attrString.boundingRect(with: containerSize, options: [NSString.DrawingOptions.usesFontLeading, NSString.DrawingOptions.usesLineFragmentOrigin])
        return attrStringSize.height + IssueEventTableViewCell.verticalPadding * 2
    }
    
    fileprivate class func detailsForIssueEvent(_ event: IssueEventInfo) -> NSAttributedString {
            var didUseFullDate = ObjCBool(false)
        let created = event.createdAt as NSDate
        guard let dateString = created.timeAgo(forWeekOrLessAndDidUseFullDate: &didUseFullDate) else { return NSAttributedString() }
            let onDateString = String(format: "%@", didUseFullDate.boolValue ? " on " : " ")
            switch(event.event!) {
                
            case IssueEventTypeInfo.GroupedLabel.rawValue as String, "labeled", "unlabeled":
                return IssueEventTableViewCell.formatPossibleGroupedEvent(event, singularPrefix: "label", pluralPrefix: "labels", onDateString: onDateString, dateString: dateString)
                
            case IssueEventTypeInfo.GroupedMilestone.rawValue as String, "milestoned", "demilestoned":
                return IssueEventTableViewCell.formatPossibleGroupedEvent(event, singularPrefix: "milestone", pluralPrefix: "milestones", onDateString: onDateString, dateString: dateString)
                
            case "renamed":
                if let event = event as? QIssueEvent {
                    let attrString = NSMutableAttributedString(string: event.actor.login, attributes: boldedAttribute())
                    attrString.append(NSAttributedString(string:" changed title from "))
                    let fromName = (event.renameFrom)! as String
                    let toName = (event.renameTo)! as String
                    attrString.append(NSAttributedString(string: fromName, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
                    attrString.append(NSAttributedString(string: " to "))
                    attrString.append(NSAttributedString(string: toName, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
                    attrString.append(NSAttributedString(string: onDateString))
                    attrString.append(NSAttributedString(string: dateString))
                    return attrString
                }
                
            case "assigned":
                let attrString = NSMutableAttributedString(string: event.actor.login, attributes: IssueEventTableViewCell.boldedAttribute())
                attrString.append(NSAttributedString(string: String(format: " was assigned this issue%@%@", onDateString, dateString)))
                return attrString
            case "unassigned":
                let attrString = NSMutableAttributedString(string: event.actor.login, attributes: IssueEventTableViewCell.boldedAttribute())
                attrString.append(NSAttributedString(string: String(format: " was unassigned from this issue%@%@", onDateString, dateString)))
                return attrString
            case "reopened":
                let attrString = NSMutableAttributedString(string: event.actor.login, attributes: IssueEventTableViewCell.boldedAttribute())
                attrString.append(NSAttributedString(string: String(format: " reopened %@%@", onDateString, dateString)))
                return attrString
            default:
                let attrString = NSMutableAttributedString(string: event.actor.login, attributes: IssueEventTableViewCell.boldedAttribute())
                attrString.append(NSAttributedString(string: String(format: " %@%@%@", event.event!, onDateString, dateString)))
                return attrString
            }
        
        
        assert(false,"empty issue event")
        return NSAttributedString(string: "")
    }
    
    fileprivate class func formatPossibleGroupedEvent(_ event: IssueEventInfo, singularPrefix: String, pluralPrefix: String, onDateString: String, dateString: String) -> NSAttributedString {
        let hasBothAddtionsAndRemovals = event.removals.count > 0 && event.additions.count > 0
        let hasMultipleEntries = (event.removals.count + event.additions.count) > 1
        let attrString = NSMutableAttributedString(string: event.actor.login, attributes: IssueEventTableViewCell.boldedAttribute())
        attrString.append(NSAttributedString(string: " "))
        
        // additions
        if event.additions.count > 1 || hasBothAddtionsAndRemovals {
            attrString.append(NSAttributedString(string:"added "))
            
            for (i, name) in event.additions.enumerated() {
                attrString.append(NSAttributedString(string: name as! String, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
                if event.additions.count != 1 && i < event.additions.count - 2 {
                    attrString.append(NSAttributedString(string: ", "))
                } else if event.additions.count != 1 && i == event.additions.count - 2 {
                    attrString.append(NSAttributedString(string: ", and "))
                }
            }
            
        } else if event.additions.count == 1 && !hasBothAddtionsAndRemovals {
            attrString.append(NSAttributedString(string: "added the "))
            attrString.append(NSAttributedString(string: event.additions[0] as! String, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
            attrString.append(NSAttributedString(string: " "))
            attrString.append(NSAttributedString(string: singularPrefix))
        }
        
        // connect sentence
        if hasBothAddtionsAndRemovals {
            attrString.append(NSAttributedString(string: " and "))
        }
        
        // removals
        if event.removals.count > 1 || hasBothAddtionsAndRemovals {

            attrString.append(NSAttributedString(string:"removed "))
            
            for (i, name) in event.removals.enumerated() {
                attrString.append(NSAttributedString(string: name as! String, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
                if event.removals.count != 1 && i < event.removals.count - 2 {
                    attrString.append(NSAttributedString(string: ", "))
                } else if event.removals.count != 1 && i == event.removals.count - 2 {
                    attrString.append(NSAttributedString(string: ", and "))
                }
            }
            
        } else if event.removals.count == 1 && !hasBothAddtionsAndRemovals {
            attrString.append(NSAttributedString(string: "removed the "))
            attrString.append(NSAttributedString(string: event.removals[0] as! String, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
            attrString.append(NSAttributedString(string: " "))
            attrString.append(NSAttributedString(string: singularPrefix))
        }
        
        if hasMultipleEntries {
            attrString.append(NSAttributedString(string: " "))
            
            if event.removals.count == 1 {
                attrString.append(NSAttributedString(string: singularPrefix))
            } else if event.removals.count > 1 {
                attrString.append(NSAttributedString(string: pluralPrefix))
            } else if event.additions.count == 1 {
                attrString.append(NSAttributedString(string: singularPrefix))
            } else if event.additions.count > 1 {
                attrString.append(NSAttributedString(string: pluralPrefix))
            }
        }
        
        attrString.append(NSAttributedString(string: onDateString))
        attrString.append(NSAttributedString(string: dateString))
        
        return attrString
    }
    
    
    override func layout() {
        super.layout()
        
        if let onHeightChanged = onHeightChanged {
            onHeightChanged()
        }
    }
}

