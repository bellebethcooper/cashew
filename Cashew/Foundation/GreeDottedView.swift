//
//  GreenDottedView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/30/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class GreenDottedView: BaseView {

    private static let checkboxCircleSize = CGSize(width: 20, height: 20)
    private static let dotCircleSize = CGSize(width: 5, height: 5)
    private static let dotBgColor = NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1)
    private static let padding: CGFloat = 12
    
    private let smallDotView = BaseView()
    private let circleView = BaseView()
    
    init() {
      
        super.init(frame: CGRect.zero)
        
        addSubview(circleView)
        circleView.addSubview(smallDotView)
        
        
        circleView.backgroundColor = GreenDottedView.dotBgColor
        circleView.cornerRadius = GreenDottedView.checkboxCircleSize.height / 2.0
        
        smallDotView.backgroundColor = NSColor.whiteColor()
        smallDotView.cornerRadius = GreenDottedView.dotCircleSize.height / 2.0
        
        //        circleView.layer?.borderColor = NSColor.redColor().CGColor
        //        circleView.layer?.borderWidth = 1
        //
        //        numberLabel.layer?.borderColor = NSColor.purpleColor().CGColor
        //        numberLabel.layer?.borderWidth = 1
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var checked: Bool = false {
        didSet {
            circleView.hidden = !checked
        }
    }
    
    override func layout() {
        let circleWidth = GreenDottedView.checkboxCircleSize.width
        
        circleView.frame = CGRectIntegralMake(x: bounds.width / 2.0 - circleWidth / 2.0, y: bounds.height / 2.0 - GreenDottedView.checkboxCircleSize.height / 2.0, width: circleWidth, height: GreenDottedView.checkboxCircleSize.height)
        
        smallDotView.frame = CGRectIntegralMake(x: circleView.frame.width / 2.0 - GreenDottedView.dotCircleSize.width / 2.0, y: circleView.frame.height / 2.0 - GreenDottedView.dotCircleSize.height / 2.0, width: GreenDottedView.dotCircleSize.width, height: GreenDottedView.dotCircleSize.height)
        
        super.layout()
    }
    
    
}
