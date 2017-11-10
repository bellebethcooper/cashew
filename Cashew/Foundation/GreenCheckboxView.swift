//
//  GreenCheckboxView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/29/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class GreenCheckboxView: BaseView {
    
    private static let checkboxCircleSize = CGSize(width: 20, height: 20)
    private static let checkboxBgColor =  NSColor(calibratedRed: 90/255.0, green: 193/255.0, blue: 44/255.0, alpha: 1)
    
    private let imageView = NSImageView()
    private let imageViewContainerView = BaseView()
    
    init() {
        super.init(frame: CGRect.zero)
        

        addSubview(imageViewContainerView)
        imageViewContainerView.addSubview(imageView)
        if let image = NSImage(named: "check")?.imageWithTintColor(NSColor.whiteColor()) {
            imageView.image = image
            imageView.wantsLayer = true
            
            imageViewContainerView.backgroundColor = GreenCheckboxView.checkboxBgColor
            imageViewContainerView.layer?.cornerRadius = GreenCheckboxView.checkboxCircleSize.height / 2.0
            imageViewContainerView.layer?.masksToBounds = true
        }
        
        

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var checked: Bool = false {
        didSet {
            imageViewContainerView.hidden = !checked
        }
    }
    
    override func layout() {
        guard let image = imageView.image else {
            super.layout()
            return
        }
        let imageSize = image.size
        let imageContainerSize = GreenCheckboxView.checkboxCircleSize
        
        let imageContainerTop = bounds.height / 2.0 - imageContainerSize.height / 2.0
        let imageContainerLeft = bounds.width / 2.0 - imageContainerSize.width / 2.0
        
        imageViewContainerView.frame = CGRectIntegralMake(x: imageContainerLeft, y: imageContainerTop, width: imageContainerSize.width, height: imageContainerSize.height)
        
        let imageLeft = imageViewContainerView.frame.width / 2.0 - imageSize.width / 2.0
        let imageTop = imageViewContainerView.frame.height / 2.0 - imageSize.height / 2.0
        imageView.frame = CGRectIntegralMake(x: imageLeft, y: imageTop, width: imageSize.width, height: imageSize.height)
        
        super.layout()
    }
    
}
