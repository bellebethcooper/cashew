//
//  BaseImageLabelButton.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

@objc(SRBaseImageLabelButtonType)
enum BaseImageLabelButtonType: NSInteger {
    case leftImage;
    case rightImage;
}

@objc(SRBaseImageLabelButtonViewModel)
class BaseImageLabelButtonViewModel: NSObject {
    var onLabelChange: (()->())?
    let image: NSImage
    var label: String {
        didSet {
            if let onLabelChange = onLabelChange {
                onLabelChange()
            }
        }
    }
    let buttonType: BaseImageLabelButtonType
    
    init(image: NSImage, label: String, buttonType: BaseImageLabelButtonType) {
        self.image = image
        self.label = label
        self.buttonType = buttonType;
        super.init()
    }
}

@objc(SRBaseImageLabelButton)
class BaseImageLabelButton: BaseView {
    
    fileprivate static let padding: CGFloat = 6.0
    
    @objc
    static let foregroundColor: NSColor = NSColor(calibratedWhite: 130/255.0, alpha: 0.85)
    
    @objc
    static let foregroundFont: NSFont = NSFont.systemFont(ofSize: 10, weight: NSFont.Weight.semibold)
    
    fileprivate let imageView = NSImageView()
    fileprivate let label = BaseLabel()
    
    
    
    
    var viewModel: BaseImageLabelButtonViewModel {
        didSet {
            didSetViewModel()
        }
    }
    
    required init(viewModel: BaseImageLabelButtonViewModel) {
        self.viewModel = viewModel
        super.init(frame: CGRect.zero)
        didSetViewModel()
        
        addSubview(imageView)
        setupLabel()
        
        //        self.layer?.borderColor = NSColor.blueColor().CGColor
        //        self.layer?.borderWidth = 1
        //
        //        imageView.layer?.borderColor = NSColor.brownColor().CGColor
        //        imageView.layer?.borderWidth = 1
        //
        //        label.layer?.borderColor = NSColor.orangeColor().CGColor
        //        label.layer?.borderWidth = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    fileprivate func didSetViewModel() {
        imageView.image = viewModel.image
        label.stringValue = viewModel.label
        viewModel.onLabelChange = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.label.stringValue = strongSelf.viewModel.label
            strongSelf.needsLayout = true
            strongSelf.layoutSubtreeIfNeeded()
        }
    }
    
    fileprivate func setupLabel() {
        guard label.superview == nil else { return }
        
        addSubview(label)
        label.font = BaseImageLabelButton.foregroundFont
        label.textColor = BaseImageLabelButton.foregroundColor
    }
    
    // MARK: layout
    
    override func layout() {
        
        let image = viewModel.image
        
        switch viewModel.buttonType {
        case .leftImage:
            let imageViewHeight = image.size.height
            let imageViewWidth = image.size.width
            imageView.frame = CGRectIntegralMake(x: 0, y: (bounds.height / 2.0 - imageViewHeight / 2.0), width: imageViewWidth, height: imageViewHeight)
            
            //let labelSize = (viewModel.label as NSString).textSizeForWithAttributes([NSFontAttributeName : BaseImageLabelButton.foregroundFont])
            let labelSize = calculateLabelSize()
            let labelTop = bounds.height  / 2.0 - labelSize.height / 2.0
            
            label.frame = CGRectIntegralMake(x: BaseImageLabelButton.padding + imageView.frame.maxX, y: labelTop, width: labelSize.width, height: labelSize.height)
        case .rightImage:
            
            //let labelSize = (viewModel.label as NSString).textSizeForWithAttributes([NSFontAttributeName : BaseImageLabelButton.foregroundFont])
            let labelSize = calculateLabelSize()
            let labelTop = bounds.height  / 2.0 - labelSize.height / 2.0
            
            label.frame = CGRectIntegralMake(x: 0, y: labelTop, width: labelSize.width, height: labelSize.height)
            
            let imageViewHeight = image.size.height
            let imageViewWidth = image.size.width
            imageView.frame = CGRectIntegralMake(x: label.frame.maxX, y: (bounds.height / 2.0 - imageViewHeight / 2.0), width: imageViewWidth, height: imageViewHeight)
        }
        
        super.layout()
    }
    
    func suggestedSize() -> CGSize {
        //  let labelSize = (viewModel.label as NSString).textSizeForWithAttributes([NSFontAttributeName : BaseImageLabelButton.foregroundFont])
        
        
        
        let labelSize = calculateLabelSize()
        let width = labelSize.width + BaseImageLabelButton.padding + viewModel.image.size.width + 6
        let height = max(labelSize.height, viewModel.image.size.height);
        return CGSize(width: width, height: height)
    }
    
    
    fileprivate func calculateLabelSize() -> CGSize {
        let textStorage = NSTextStorage(attributedString: NSAttributedString(string: viewModel.label, attributes: [NSAttributedString.Key.font : BaseImageLabelButton.foregroundFont]))
        let textContainer = NSTextContainer(containerSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude) )
        let layoutManager = NSLayoutManager()
        //        let attributes = [ NSFontAttributeName: font ] as [String : AnyObject]?
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        //        textStorage.addAttributes(attributes!, range: NSMakeRange(0, (stringVal as NSString).length))
        
        layoutManager.glyphRange(for: textContainer)
        let labelSize = layoutManager.usedRect(for: textContainer).size
        return labelSize
    }
}
