//
//  NumberCircleView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/30/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class NumberCircleView: BaseView {
    
    
    private static let checkboxCircleSize = CGSize(width: 20, height: 20)
    private static let checkboxBgColor = NSColor(calibratedRed: 33/255.0, green: 201/255.0, blue: 115/255.0, alpha: 1.0)
    private static let padding: CGFloat = 12
    
    private let numberLabel = BaseLabel()
    private let circleView = BaseView()
    var count: Int = 0 {
        didSet {
            numberLabel.stringValue = String(count)
            needsLayout = true
            layoutSubtreeIfNeeded()
        }
    }
    
    init(count: Int = 0) {
        numberLabel.stringValue = String(count)
        
        super.init(frame: CGRect.zero)
        
        self.count = count
        
        addSubview(circleView)
        circleView.addSubview(numberLabel)
        
        
        circleView.backgroundColor = NumberCircleView.checkboxBgColor
        circleView.cornerRadius = NumberCircleView.checkboxCircleSize.height / 2.0
        
        numberLabel.textColor = NSColor.whiteColor()
        numberLabel.alignment = .Center
        numberLabel.font = NSFont.systemFontOfSize(12, weight: NSFontWeightSemibold)
        
//        circleView.layer?.borderColor = NSColor.redColor().CGColor
//        circleView.layer?.borderWidth = 1
//        
//        numberLabel.layer?.borderColor = NSColor.purpleColor().CGColor
//        numberLabel.layer?.borderWidth = 1

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        let numberSize = numberLabel.attributedStringValue.textSize()
        
        let circleWidth = max(numberSize.width, NumberCircleView.checkboxCircleSize.width) //+ NumberCircleView.padding
        
        circleView.frame = CGRectIntegralMake(x: bounds.width / 2.0 - circleWidth / 2.0, y: bounds.height / 2.0 - NumberCircleView.checkboxCircleSize.height / 2.0, width: circleWidth, height: NumberCircleView.checkboxCircleSize.height)
        
        numberLabel.frame = CGRectIntegralMake(x: circleView.frame.width / 2.0 - circleView.frame.width / 2.0, y: 2 + circleView.frame.height / 2.0 - circleView.frame.height / 2.0, width: circleView.frame.width, height: circleView.frame.height)
        
        super.layout()
    }
    
    
}
