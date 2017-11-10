//
//  QIssueLabelView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 2/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

enum QIssueLabelViewMode {
    case ColoredForeground
    case ColoredBackground
    case Gray
}

class QIssueLabelViewModel: NSObject {
    let title: String
    let color: NSColor
    
    required init(title aTitle: String, color aColor: NSColor) {
        title = aTitle
        color = aColor
        super.init()
    }
}


class QIssueLabelViewTextView: NSTextField {
    var shouldAllowVibrancy = true
    
    override var allowsVibrancy: Bool {
        return shouldAllowVibrancy
    }
}

class QIssueLabelView: BaseView {
    
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var labelTextField: QIssueLabelViewTextView!
    
    private static let labelHeight: CGFloat = 15.0
    
    var mode: QIssueLabelViewMode = QIssueLabelViewMode.ColoredForeground {
        didSet {
            updateLabelColors()
        }
    }
    
    override var shouldAllowVibrancy: Bool {
        didSet {
            labelTextField.shouldAllowVibrancy = shouldAllowVibrancy
        }
    }
    
    var viewModel: QIssueLabelViewModel? {
        didSet {
            if let viewModel = self.viewModel {
                labelTextField.stringValue = viewModel.title
            } else {
                labelTextField.stringValue = ""
            }
            updateLabelColors()
        }
    }
    
    
    private func updateLabelColors() {
        guard let viewModel = viewModel, layer = layer else {
            backgroundColor = NSColor.clearColor()
            labelTextField.backgroundColor = self.backgroundColor
            return
        }
        
        
        let otherColor: NSColor
        
        if let viewModelColor = viewModel.color.colorUsingColorSpaceName(NSCalibratedRGBColorSpace) {
            let red = viewModelColor.redComponent * 255
            let green = viewModelColor.greenComponent * 255
            let blue = viewModelColor.blueComponent * 255
            
            if (red * 0.299 + green * 0.587 + blue * 0.114) > 186 {
                otherColor = NSColor.blackColor().colorWithAlphaComponent(0.9)
            } else {
                otherColor = NSColor.whiteColor()
            }
        } else {
            otherColor = NSColor.whiteColor()
        }
        
        
        
        
        
        switch mode {
        case .ColoredBackground:
            backgroundColor = viewModel.color//NSColor(fromHexadecimalValue: label.color)
            labelTextField.textColor = otherColor // NSColor.whiteColor()
            layer.borderWidth = 0
        //    layer.borderColor = NSColor(calibratedWhite: 0.90, alpha: 1).CGColor
        case .ColoredForeground:
            backgroundColor = otherColor // NSColor.clearColor()
            labelTextField.textColor = viewModel.color //NSColor(fromHexadecimalValue: label.color)
            layer.borderWidth = 1
            layer.borderColor = NSColor(calibratedWhite: 0, alpha: 0.1).CGColor //QIssueLabelView.labelFontColor.CGColor
        case .Gray:
            backgroundColor = NSColor.clearColor()
            labelTextField.textColor = NSColor(calibratedWhite: 1, alpha: 0.6) //QIssueLabelView.labelFontColor
            layer.borderWidth = 1
            layer.borderColor = NSColor(calibratedWhite: 1, alpha: 0.1).CGColor //QIssueLabelView.labelFontColor.CGColor
        }
        
        
    }
    
    func labelSize() -> CGSize {
        //        let font = self.labelTextField.font!
        //        let attributes = [ NSFontAttributeName: font ] as [String : AnyObject]?
        //        let attributedString = NSAttributedString(string: self.labelTextField.stringValue, attributes: attributes)
        //        let newRect = attributedString.boundingRectWithSize(CGSizeMake(CGFloat.max, QIssueLabelView.labelHeight), options: [.UsesFontLeading, .UsesLineFragmentOrigin])
        //        return CGSizeMake(newRect.width + self.leftConstraint.constant + self.rightConstraint.constant + 8, QIssueLabelView.labelHeight) // need to figure out where this 7 is coming from
        
        let font = self.labelTextField.font!
        let textStorage = NSTextStorage(string: labelTextField.stringValue)
        let textContainer = NSTextContainer(containerSize: CGSizeMake(CGFloat.max, QIssueLabelView.labelHeight))
        let layoutManager = NSLayoutManager()
        let attributes = [ NSFontAttributeName: font ] as [String : AnyObject]?
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textStorage.addAttributes(attributes!, range: NSMakeRange(0, (labelTextField.stringValue as NSString).length))
        
        layoutManager.glyphRangeForTextContainer(textContainer)
        let size = layoutManager.usedRectForTextContainer(textContainer).size
        return CGSizeMake(size.width  + self.leftConstraint.constant + self.rightConstraint.constant, QIssueLabelView.labelHeight)
    }
    
    
    override func layout() {
        layer?.cornerRadius = self.frame.height / 2.0
        
        super.layout()
    }
    
    deinit {
        QLabelStore.removeObserver(self)
    }
    
    override func awakeFromNib() {
        disableThemeObserver = true
        if let layer = self.layer {
            layer.masksToBounds = true
        }
        QLabelStore.addObserver(self)
        //        if let labelTextFieldLayer = labelTextField.layer {
        //            labelTextFieldLayer.borderColor = NSColor.redColor().CGColor
        //            labelTextFieldLayer.borderWidth = 1
        //        }
    }
    
}


extension QIssueLabelView: QStoreObserver {
    func store(store: AnyClass!, didInsertRecord record: AnyObject!) {

    }
    
    func store(store: AnyClass!, didUpdateRecord record: AnyObject!) {
        guard let labelRecord = record as? QLabel, currentLabel = objectValue as? QLabel else {
            return
        }
        
        if let labelName = labelRecord.name, labelColor = labelRecord.color where labelRecord.repository == currentLabel.repository && labelRecord.color != currentLabel.color && labelRecord.name == currentLabel.name {
            dispatch_async(dispatch_get_main_queue(), { 
              self.viewModel = QIssueLabelViewModel(title: labelName, color: NSColor(fromHexadecimalValue: labelColor))
            })
        }
    }
    
    func store(store: AnyClass!, didRemoveRecord record: AnyObject!) {

    }
}
