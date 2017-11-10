//
//  BaseTableRowView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

enum BaseTableRowViewSelectionType {
    case Checkbox;
    case Highlight;
    case None;
}

class BaseTableRowView: NSTableRowView {
    
    private static let titleTextColor = NSColor(calibratedWhite: 0, alpha: 0.80)
    private static let titleTextSelectedColor = NSColor(calibratedWhite: 1, alpha: 1)
    private static let subtitleTextColor = NSColor(calibratedWhite: 0, alpha: 0.60)
    private static let subtitleTextSelectedColor = NSColor(calibratedWhite: 1, alpha: 0.80)
    private static let titleTextFont = NSFont.systemFontOfSize(14, weight: NSFontWeightSemibold)
    private static let subtitleTextFont = NSFont.systemFontOfSize(13)
    private static let padding: CGFloat = 6.0
    static let selectionColor = NSColor(calibratedRed: 62/255.0, green: 96/255.0, blue: 218/255.0, alpha: 1)
    private static let checkboxPadding: CGFloat = 6
    private static let checkboxWidth: CGFloat = 30.0
    
    let titleLabel = BaseLabel()
    let subtitleLabel = BaseLabel()
    let separatorView = BaseSeparatorView()
    
    var disableThemeObserver = false {
        didSet {
            if disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(self)
            }
            titleLabel.disableThemeObserver = disableThemeObserver
            subtitleLabel.disableThemeObserver = disableThemeObserver
            separatorView.disableThemeObserver = disableThemeObserver
        }
    }
    
    var accessoryView: BaseView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let accessoryView = accessoryView {
                addSubview(accessoryView)
            }
        }
    }
    
    private(set) var contentView = BaseView()
    var selectionType: BaseTableRowViewSelectionType = .Highlight {
        didSet {
            if selectionType == .None {
                checked = false
            }
            needsDisplay = true
            needsLayout = true
            layoutSubtreeIfNeeded()
        }
    }
    
    var titleLabelColor: NSColor {
        return RepositorySearchResultTableRowView.titleTextColor
    }
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    required init() {
        super.init(frame: CGRect.zero)
        self.wantsLayer = true
        
        addSubview(separatorView)
        addSubview(contentView)
        
        defer {
            let accessoryView = GreenCheckboxView()
            accessoryView.checked = true
            accessoryView.disableThemeObserver = true
            accessoryView.backgroundColor = NSColor.clearColor()
            self.accessoryView = accessoryView
        }
        
        setupTitleLabel()
        setupSubtitleLabel()
        
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(strongSelf)
                return;
            }
            
            let selected = strongSelf.selected
            strongSelf.selected = selected
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var selected: Bool {
        didSet {
            switch selectionType {
            case .Highlight:
                accessoryView?.hidden = true
                if selected {
                    contentView.backgroundColor = BaseTableRowView.selectionColor
                } else {
                    backgroundColor = CashewColor.backgroundColor()
                    contentView.backgroundColor = CashewColor.backgroundColor()

                }
            case .Checkbox:
                fallthrough
            case .None:
                needsLayout = true
                layoutSubtreeIfNeeded()
                backgroundColor = CashewColor.backgroundColor()
                contentView.backgroundColor = backgroundColor
                break;
            }
            
            titleLabel.textColor = CashewColor.foregroundColor()
            subtitleLabel.textColor = CashewColor.foregroundSecondaryColor()
        }
    }
    
    var checked: Bool = false {
        didSet {
            accessoryView?.hidden = !checked
            needsLayout = true
            layoutSubtreeIfNeeded()
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    
    private func setup() {
        self.wantsLayer = true
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else { return }
            
            let selected = strongSelf.selected
            strongSelf.selected = selected
        }
    }
    
    override func layout() {
        separatorView.frame = CGRectIntegralMake(x: RepositorySearchResultTableRowView.padding, y: bounds.height - 1, width: bounds.width - RepositorySearchResultTableRowView.padding, height: 1)
        
        if let accessoryView = accessoryView {
            accessoryView.frame = CGRectIntegralMake(x: bounds.width - BaseTableRowView.checkboxWidth - BaseTableRowView.checkboxPadding, y: 0, width: BaseTableRowView.checkboxWidth, height: bounds.height - 1)
            contentView.frame = CGRectIntegralMake(x: 0, y: 0, width: bounds.width - (!accessoryView.hidden ? BaseTableRowView.checkboxWidth + BaseTableRowView.checkboxPadding : 0.0), height: bounds.height - 1)
        } else {
            contentView.frame = CGRectIntegralMake(x: 0, y: 0, width: bounds.width, height: bounds.height - 1)
        }
        
        let width = contentView.frame.width
        titleLabel.sizeToFit()
        let titleTextSize =  titleLabel.frame.size
        
        
        if (subtitleLabel.stringValue as NSString).trimmedString().length > 0 {
            subtitleLabel.sizeToFit()
            let subtitleTextSize = subtitleLabel.frame.size
            
            let titleTextTop = bounds.height / 2.0 - (titleTextSize.height + subtitleTextSize.height) / 2.0
            titleLabel.frame = CGRectIntegralMake(x: RepositorySearchResultTableRowView.padding, y: titleTextTop, width: width - RepositorySearchResultTableRowView.padding * 2, height: titleTextSize.height)
            subtitleLabel.frame = CGRectIntegralMake(x: RepositorySearchResultTableRowView.padding, y: titleLabel.frame.maxY, width: titleLabel.frame.width, height: subtitleTextSize.height)
            
        } else {
            let titleTextTop = bounds.height / 2.0 - titleTextSize.height / 2.0
            titleLabel.frame = CGRectIntegralMake(x: RepositorySearchResultTableRowView.padding, y: titleTextTop, width: width - RepositorySearchResultTableRowView.padding * 2, height: titleTextSize.height)
        }
        
        super.layout()
    }
    
    override func drawSelectionInRect(dirtyRect: NSRect) {
        guard selectionType == .Highlight else { return }
        
        if self.selectionHighlightStyle != .None {
            let rect = NSInsetRect(self.bounds, 0, 0)
            BaseTableRowView.selectionColor.setFill()
            let selectionPath = NSBezierPath(roundedRect: rect, xRadius: 0, yRadius: 0)
            selectionPath.fill()
        }
    }
    
    
    // MARK: Setup
    
    private func setupSubtitleLabel() {
        guard subtitleLabel.superview == nil else { return }
        contentView.addSubview(subtitleLabel)
        subtitleLabel.font = RepositorySearchResultTableRowView.subtitleTextFont
        subtitleLabel.disableThemeObserver = true
        subtitleLabel.textColor = CashewColor.foregroundSecondaryColor()
    }
    
    private func setupTitleLabel() {
        guard titleLabel.superview == nil else { return }
        contentView.addSubview(titleLabel)
        titleLabel.font = RepositorySearchResultTableRowView.titleTextFont
        titleLabel.disableThemeObserver = true
        titleLabel.textColor = CashewColor.foregroundColor()
    }
    
}
