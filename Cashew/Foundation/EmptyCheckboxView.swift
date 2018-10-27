//
//  EmptyCheckboxView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//


class EmptyCheckboxView: BaseView {

    fileprivate static let checkboxCircleSize = CGSize(width: 20, height: 20)
    fileprivate static let checkboxBgColor = NSColor(calibratedRed: 33/255.0, green: 201/255.0, blue: 115/255.0, alpha: 1.0)
    
    fileprivate let circleView = BaseView()
    
    init() {
        super.init(frame: CGRect.zero)
        
        addSubview(circleView)

        circleView.layer?.cornerRadius = EmptyCheckboxView.checkboxCircleSize.height / 2.0
        circleView.layer?.masksToBounds = true
        circleView.layer?.borderColor = NSColor(calibratedWhite: 0.75, alpha: 1).cgColor
        circleView.layer?.borderWidth = 1
        circleView.backgroundColor = NSColor.clear
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        let imageContainerSize = EmptyCheckboxView.checkboxCircleSize
        
        let imageContainerTop = bounds.height / 2.0 - imageContainerSize.height / 2.0
        let imageContainerLeft = bounds.width / 2.0 - imageContainerSize.width / 2.0
        
        circleView.frame = CGRectIntegralMake(x: imageContainerLeft, y: imageContainerTop, width: imageContainerSize.width, height: imageContainerSize.height)
        
        super.layout()
    }
    
}
