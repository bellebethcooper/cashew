//
//  IssueEventTableViewCell.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/27/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class IssueEventTableViewCell: BaseView {
    
    private static let verticalPadding: CGFloat = 10.0
    private static let spacingOccupiedByHorizontalPaddingAndImageView: CGFloat = 37.0
    private static let eventNameBoldedAttribute: [String : AnyObject] = [NSFontAttributeName: NSFont.systemFontOfSize(12, weight: NSFontWeightSemibold)]
    
    @IBOutlet weak var eventDetailsLabel: NSTextField!
    @IBOutlet weak var eventImageView: NSImageView!
    @IBOutlet weak var eventImageContainerView: BaseView!
    
    var onHeightChanged: dispatch_block_t?
    
    var issueEvent: IssueEventInfo? {
        didSet {
            didSetIssueEvent()
        }
    }
    
    private func didSetIssueEvent() {
        assert(NSThread.isMainThread(), "not on main thread");
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
            
            if mode == .Light {
                strongSelf.backgroundColor = LightModeColor.sharedInstance.backgroundColor()
                strongSelf.eventDetailsLabel.textColor = LightModeColor.sharedInstance.foregroundTertiaryColor()
            } else if mode == .Dark {
                strongSelf.backgroundColor = DarkModeColor.sharedInstance.backgroundColor()
                strongSelf.eventDetailsLabel.textColor = DarkModeColor.sharedInstance.foregroundTertiaryColor()
            }
            
            strongSelf.didSetIssueEvent()
        }
    }
    
    private class func boldedAttribute() -> [String : AnyObject]  {
        
        let themeMode = NSUserDefaults.themeMode()
        
        var color = NSColor(calibratedWhite: 67/255.0, alpha: 0.85)
        if (themeMode == .Light) {
            color = LightModeColor.sharedInstance.foregroundSecondaryColor()
        } else if (themeMode == .Dark) {
            color = DarkModeColor.sharedInstance.foregroundSecondaryColor()
        }
        
        let attr = [NSFontAttributeName: NSFont.systemFontOfSize(12, weight: NSFontWeightSemibold), NSForegroundColorAttributeName: color]
        return attr
    }
    
    deinit {
        onHeightChanged = nil
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    private func setupImageForCurrentIssueEvent() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if let event = self.issueEvent, eventImageView = self.eventImageView {
                let color = NSColor.init(calibratedRed: 148/255.0, green: 148/255.0, blue: 148/255.0, alpha: 1)
                
                eventImageView.layer?.backgroundColor = NSColor.clearColor().CGColor
                
                switch(event.event!) {
                case "labeled", "unlabeled":
                    eventImageView.image = NSImage(named: "tag")!.imageWithTintColor(color)
                case "milestoned", "demilestoned":
                    eventImageView.image = NSImage(named: "milestone")!.imageWithTintColor(color)
                case "renamed":
                    eventImageView.image = NSImage(named: "pencil")!.imageWithTintColor(color)
                case "assigned", "unassigned":
                    eventImageView.image = NSImage(named: "person")!.imageWithTintColor(color)
                case "closed":
                    eventImageView.image = NSImage(named: "issue-closed")!.imageWithTintColor(NSColor.whiteColor())
                    eventImageView.layer?.backgroundColor = NSColor.init(calibratedRed: 175/255.0, green: 25/255.0, blue: 0, alpha: 1).CGColor
                case "reopened":
                    eventImageView.image = NSImage(named: "issue-reopened")!.imageWithTintColor(NSColor.whiteColor())
                    eventImageView.layer?.backgroundColor = NSColor.init(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1).CGColor
                default:
                    eventImageView.image = nil
                }
                
            } else {
                self.eventImageView.image = nil
            }
            CATransaction.commit()
        }
    }
    
    class func heightForIssueEvent(event: IssueEventInfo, width: CGFloat) -> CGFloat {
        let attrString = IssueEventTableViewCell.detailsForIssueEvent(event)
        let containerSize = CGSizeMake(width - IssueEventTableViewCell.spacingOccupiedByHorizontalPaddingAndImageView, CGFloat.max)
        let attrStringSize = attrString.boundingRectWithSize(containerSize, options: [.UsesFontLeading, .UsesLineFragmentOrigin])
        return attrStringSize.height + IssueEventTableViewCell.verticalPadding * 2
    }
    
    private class func detailsForIssueEvent(event: IssueEventInfo) -> NSAttributedString {
            var didUseFullDate = ObjCBool(false)
            let dateString = event.createdAt.timeAgoForWeekOrLessAndDidUseFullDate(&didUseFullDate);
            let onDateString = String(format: "%@", didUseFullDate.boolValue ? " on " : " ")
            switch(event.event!) {
                
            case IssueEventTypeInfo.GroupedLabel.rawValue, "labeled", "unlabeled":
                return IssueEventTableViewCell.formatPossibleGroupedEvent(event, singularPrefix: "label", pluralPrefix: "labels", onDateString: onDateString, dateString: dateString)
                
            case IssueEventTypeInfo.GroupedMilestone.rawValue, "milestoned", "demilestoned":
                return IssueEventTableViewCell.formatPossibleGroupedEvent(event, singularPrefix: "milestone", pluralPrefix: "milestones", onDateString: onDateString, dateString: dateString)
                
            case "renamed":
                if let event = event as? QIssueEvent {
                    let attrString = NSMutableAttributedString(string: event.actor.login, attributes: boldedAttribute())
                    attrString.appendAttributedString(NSAttributedString(string:" changed title from "))
                    let fromName = (event.renameFrom)! as String
                    let toName = (event.renameTo)! as String
                    attrString.appendAttributedString(NSAttributedString(string: fromName, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
                    attrString.appendAttributedString(NSAttributedString(string: " to "))
                    attrString.appendAttributedString(NSAttributedString(string: toName, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
                    attrString.appendAttributedString(NSAttributedString(string: onDateString))
                    attrString.appendAttributedString(NSAttributedString(string: dateString))
                    return attrString
                }
                
            case "assigned":
                let attrString = NSMutableAttributedString(string: event.actor.login, attributes: IssueEventTableViewCell.boldedAttribute())
                attrString.appendAttributedString(NSAttributedString(string: String(format: " was assigned this issue%@%@", onDateString, dateString)))
                return attrString
            case "unassigned":
                let attrString = NSMutableAttributedString(string: event.actor.login, attributes: IssueEventTableViewCell.boldedAttribute())
                attrString.appendAttributedString(NSAttributedString(string: String(format: " was unassigned from this issue%@%@", onDateString, dateString)))
                return attrString
            case "reopened":
                let attrString = NSMutableAttributedString(string: event.actor.login, attributes: IssueEventTableViewCell.boldedAttribute())
                attrString.appendAttributedString(NSAttributedString(string: String(format: " reopened %@%@", onDateString, dateString)))
                return attrString
            default:
                let attrString = NSMutableAttributedString(string: event.actor.login, attributes: IssueEventTableViewCell.boldedAttribute())
                attrString.appendAttributedString(NSAttributedString(string: String(format: " %@%@%@", event.event!, onDateString, dateString)))
                return attrString
            }
        
        
        assert(false,"empty issue event")
        return NSAttributedString(string: "")
    }
    
    private class func formatPossibleGroupedEvent(event: IssueEventInfo, singularPrefix: String, pluralPrefix: String, onDateString: String, dateString: String) -> NSAttributedString {
        let hasBothAddtionsAndRemovals = event.removals.count > 0 && event.additions.count > 0
        let hasMultipleEntries = (event.removals.count + event.additions.count) > 1
        let attrString = NSMutableAttributedString(string: event.actor.login, attributes: IssueEventTableViewCell.boldedAttribute())
        attrString.appendAttributedString(NSAttributedString(string: " "))
        
        // additions
        if event.additions.count > 1 || hasBothAddtionsAndRemovals {
            attrString.appendAttributedString(NSAttributedString(string:"added "))
            
            for (i, name) in event.additions.enumerate() {
                attrString.appendAttributedString(NSAttributedString(string: name as! String, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
                if event.additions.count != 1 && i < event.additions.count - 2 {
                    attrString.appendAttributedString(NSAttributedString(string: ", "))
                } else if event.additions.count != 1 && i == event.additions.count - 2 {
                    attrString.appendAttributedString(NSAttributedString(string: ", and "))
                }
            }
            
        } else if event.additions.count == 1 && !hasBothAddtionsAndRemovals {
            attrString.appendAttributedString(NSAttributedString(string: "added the "))
            attrString.appendAttributedString(NSAttributedString(string: event.additions[0] as! String, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
            attrString.appendAttributedString(NSAttributedString(string: " "))
            attrString.appendAttributedString(NSAttributedString(string: singularPrefix))
        }
        
        // connect sentence
        if hasBothAddtionsAndRemovals {
            attrString.appendAttributedString(NSAttributedString(string: " and "))
        }
        
        // removals
        if event.removals.count > 1 || hasBothAddtionsAndRemovals {

            attrString.appendAttributedString(NSAttributedString(string:"removed "))
            
            for (i, name) in event.removals.enumerate() {
                attrString.appendAttributedString(NSAttributedString(string: name as! String, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
                if event.removals.count != 1 && i < event.removals.count - 2 {
                    attrString.appendAttributedString(NSAttributedString(string: ", "))
                } else if event.removals.count != 1 && i == event.removals.count - 2 {
                    attrString.appendAttributedString(NSAttributedString(string: ", and "))
                }
            }
            
        } else if event.removals.count == 1 && !hasBothAddtionsAndRemovals {
            attrString.appendAttributedString(NSAttributedString(string: "removed the "))
            attrString.appendAttributedString(NSAttributedString(string: event.removals[0] as! String, attributes: IssueEventTableViewCell.eventNameBoldedAttribute))
            attrString.appendAttributedString(NSAttributedString(string: " "))
            attrString.appendAttributedString(NSAttributedString(string: singularPrefix))
        }
        
        if hasMultipleEntries {
            attrString.appendAttributedString(NSAttributedString(string: " "))
            
            if event.removals.count == 1 {
                attrString.appendAttributedString(NSAttributedString(string: singularPrefix))
            } else if event.removals.count > 1 {
                attrString.appendAttributedString(NSAttributedString(string: pluralPrefix))
            } else if event.additions.count == 1 {
                attrString.appendAttributedString(NSAttributedString(string: singularPrefix))
            } else if event.additions.count > 1 {
                attrString.appendAttributedString(NSAttributedString(string: pluralPrefix))
            }
        }
        
        attrString.appendAttributedString(NSAttributedString(string: onDateString))
        attrString.appendAttributedString(NSAttributedString(string: dateString))
        
        return attrString
    }
    
    
    override func layout() {
        super.layout()
        
        if let onHeightChanged = onHeightChanged {
            onHeightChanged()
        }
    }
}

