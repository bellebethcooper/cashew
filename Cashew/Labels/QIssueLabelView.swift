//
//  QIssueLabelView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 2/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

enum QIssueLabelViewMode {
    case coloredForeground
    case coloredBackground
    case gray
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
    @IBOutlet fileprivate weak var labelTextField: QIssueLabelViewTextView!
    
    fileprivate static let labelHeight: CGFloat = 15.0
    
    var mode: QIssueLabelViewMode = QIssueLabelViewMode.coloredForeground {
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
    
    
    fileprivate func updateLabelColors() {
        guard let viewModel = viewModel, let layer = layer else {
            backgroundColor = NSColor.clear
            labelTextField.backgroundColor = self.backgroundColor
            return
        }
        
        
        let otherColor: NSColor
        
        if let viewModelColor = viewModel.color.usingColorSpaceName(NSColorSpaceName.calibratedRGB) {
            let red = viewModelColor.redComponent * 255
            let green = viewModelColor.greenComponent * 255
            let blue = viewModelColor.blueComponent * 255
            
            if (red * 0.299 + green * 0.587 + blue * 0.114) > 186 {
                otherColor = NSColor.black.withAlphaComponent(0.9)
            } else {
                otherColor = NSColor.white
            }
        } else {
            otherColor = NSColor.white
        }
        
        
        
        
        
        switch mode {
        case .coloredBackground:
            backgroundColor = viewModel.color//NSColor(fromHexadecimalValue: label.color)
            labelTextField.textColor = otherColor // NSColor.whiteColor()
            layer.borderWidth = 0
        //    layer.borderColor = NSColor(calibratedWhite: 0.90, alpha: 1).CGColor
        case .coloredForeground:
            backgroundColor = otherColor // NSColor.clear()
            labelTextField.textColor = viewModel.color //NSColor(fromHexadecimalValue: label.color)
            layer.borderWidth = 1
            layer.borderColor = NSColor(calibratedWhite: 0, alpha: 0.1).cgColor //QIssueLabelView.labelFontColor.CGColor
        case .gray:
            backgroundColor = NSColor.clear
            labelTextField.textColor = NSColor(calibratedWhite: 1, alpha: 0.6) //QIssueLabelView.labelFontColor
            layer.borderWidth = 1
            layer.borderColor = NSColor(calibratedWhite: 1, alpha: 0.1).cgColor //QIssueLabelView.labelFontColor.CGColor
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
        let textContainer = NSTextContainer(containerSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: QIssueLabelView.labelHeight))
        let layoutManager = NSLayoutManager()
        let attributes = [ NSAttributedStringKey.font.rawValue: font ]
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
//        textStorage.addAttributes(attributes, range: NSMakeRange(0, (labelTextField.stringValue as NSString).length))
        
        layoutManager.glyphRange(for: textContainer)
        let size = layoutManager.usedRect(for: textContainer).size
        return CGSize(width: size.width  + self.leftConstraint.constant + self.rightConstraint.constant, height: QIssueLabelView.labelHeight)
    }
    
    
    override func layout() {
        layer?.cornerRadius = self.frame.height / 2.0
        
        super.layout()
    }
    
    deinit {
        QLabelStore.remove(self)
    }
    
    override func awakeFromNib() {
        disableThemeObserver = true
        if let layer = self.layer {
            layer.masksToBounds = true
        }
        QLabelStore.add(self)
        //        if let labelTextFieldLayer = labelTextField.layer {
        //            labelTextFieldLayer.borderColor = NSColor.redColor().CGColor
        //            labelTextFieldLayer.borderWidth = 1
        //        }
    }
    
}


extension QIssueLabelView: QStoreObserver {
    func store(_ store: AnyClass!, didInsertRecord record: Any!) {

    }
    
    func store(_ store: AnyClass!, didUpdateRecord record: Any!) {
        guard let labelRecord = record as? QLabel, let currentLabel = objectValue as? QLabel else {
            return
        }
        
        if let labelName = labelRecord.name, let labelColor = labelRecord.color , labelRecord.repository == currentLabel.repository && labelRecord.color != currentLabel.color && labelRecord.name == currentLabel.name {
            DispatchQueue.main.async(execute: { 
              self.viewModel = QIssueLabelViewModel(title: labelName, color: NSColor(fromHexadecimalValue: labelColor))
            })
        }
    }
    
    func store(_ store: AnyClass!, didRemoveRecord record: Any!) {

    }
}
