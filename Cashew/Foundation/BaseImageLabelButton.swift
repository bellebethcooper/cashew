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
    case LeftImage;
    case RightImage;
}

@objc(SRBaseImageLabelButtonViewModel)
class BaseImageLabelButtonViewModel: NSObject {
    var onLabelChange: dispatch_block_t?
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
    
    private static let padding: CGFloat = 6.0
    
    @objc
    static let foregroundColor: NSColor = NSColor(calibratedWhite: 130/255.0, alpha: 0.85)
    
    @objc
    static let foregroundFont: NSFont = NSFont.systemFontOfSize(10, weight: NSFontWeightSemibold)
    
    private let imageView = NSImageView()
    private let label = BaseLabel()
    
    
    
    
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
    
    private func didSetViewModel() {
        imageView.image = viewModel.image
        label.stringValue = viewModel.label
        viewModel.onLabelChange = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.label.stringValue = strongSelf.viewModel.label
            strongSelf.needsLayout = true
            strongSelf.layoutSubtreeIfNeeded()
        }
    }
    
    private func setupLabel() {
        guard label.superview == nil else { return }
        
        addSubview(label)
        label.font = BaseImageLabelButton.foregroundFont
        label.textColor = BaseImageLabelButton.foregroundColor
    }
    
    // MARK: layout
    
    override func layout() {
        
        let image = viewModel.image
        
        switch viewModel.buttonType {
        case .LeftImage:
            let imageViewHeight = image.size.height
            let imageViewWidth = image.size.width
            imageView.frame = CGRectIntegralMake(x: 0, y: (bounds.height / 2.0 - imageViewHeight / 2.0), width: imageViewWidth, height: imageViewHeight)
            
            //let labelSize = (viewModel.label as NSString).textSizeForWithAttributes([NSFontAttributeName : BaseImageLabelButton.foregroundFont])
            let labelSize = calculateLabelSize()
            let labelTop = bounds.height  / 2.0 - labelSize.height / 2.0
            
            label.frame = CGRectIntegralMake(x: BaseImageLabelButton.padding + imageView.frame.maxX, y: labelTop, width: labelSize.width, height: labelSize.height)
        case .RightImage:
            
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
    
    
    private func calculateLabelSize() -> CGSize {
        let textStorage = NSTextStorage(attributedString: NSAttributedString(string: viewModel.label, attributes: [NSFontAttributeName : BaseImageLabelButton.foregroundFont]))
        let textContainer = NSTextContainer(containerSize: CGSize(width: CGFloat.max, height: CGFloat.max) )
        let layoutManager = NSLayoutManager()
        //        let attributes = [ NSFontAttributeName: font ] as [String : AnyObject]?
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        //        textStorage.addAttributes(attributes!, range: NSMakeRange(0, (stringVal as NSString).length))
        
        layoutManager.glyphRangeForTextContainer(textContainer)
        let labelSize = layoutManager.usedRectForTextContainer(textContainer).size
        return labelSize
    }
}
