//
//  LabelSearchResultTableRowView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/30/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class LabelSearchResultTableRowView: BaseTableRowView {
    
    private static let circleSize = CGSizeMake(20, 20)
    private static let padding: CGFloat = 6.0
    
    private let colorCircleView = BaseView()
    var label: QLabel {
        didSet {
            didSetLabel()
        }
    }
    
    required init(label: QLabel) {
        self.label = label
        super.init()
        
        contentView.addSubview(colorCircleView)
        colorCircleView.cornerRadius = LabelSearchResultTableRowView.circleSize.height / 2.0
        
        selectionType = .None
        
        didSetLabel()
    
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else{ return }
            let selected = strongSelf.selected
            strongSelf.selected = selected
        }
    }
    
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    override var selected: Bool {
        didSet {
            needsLayout = true
            layoutSubtreeIfNeeded()
            if NSUserDefaults.themeMode() == .Dark {
                backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                backgroundColor = CashewColor.backgroundColor()
            }
            
            contentView.backgroundColor = backgroundColor
            titleLabel.textColor = CashewColor.foregroundColor()
            
        }
    }
    
    override func layout() {
        super.layout()
        
        let circleTop = bounds.height / 2.0 - LabelSearchResultTableRowView.circleSize.height / 2.0
        colorCircleView.frame = CGRectIntegralMake(x: LabelSearchResultTableRowView.padding, y: circleTop, width: LabelSearchResultTableRowView.circleSize.width, height: LabelSearchResultTableRowView.circleSize.height)
        
        titleLabel.frame = CGRectIntegralMake(x: colorCircleView.frame.maxX + LabelSearchResultTableRowView.padding, y: titleLabel.frame.minY, width: titleLabel.frame.width - (colorCircleView.frame.maxX + LabelSearchResultTableRowView.padding), height: titleLabel.frame.height)
        
        subtitleLabel.frame = CGRectIntegralMake(x: colorCircleView.frame.maxX + LabelSearchResultTableRowView.padding, y: subtitleLabel.frame.minY, width: subtitleLabel.frame.width - (colorCircleView.frame.maxX + LabelSearchResultTableRowView.padding), height: subtitleLabel.frame.height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    // MARK: Setup
    private func didSetLabel() {
        titleLabel.stringValue = label.name ?? ""
        subtitleLabel.stringValue = "\(label.repository!.name) • #\(label.color!.uppercaseString)"
        colorCircleView.backgroundColor = NSColor(fromHexadecimalValue: label.color)
    }
}
