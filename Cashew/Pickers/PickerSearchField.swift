//
//  PickerSearchField.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa


@objc(SRPickerSearchFieldViewModel)
class PickerSearchFieldViewModel: NSObject {
    let placeHolderText: String
    
    init(placeHolderText: String) {
        self.placeHolderText = placeHolderText
        super.init()
    }
}

@objc(SRPickerSearchField)
class PickerSearchField: BaseView {
    
    private static let padding: CGFloat = 6.0
    private static let textFieldHeight: CGFloat = 22.0
    private static let placeholderColor = NSColor(calibratedWhite: 0.7, alpha: 1)
    private static let textFont = NSFont.systemFontOfSize(14)
    //private static let toolbarView:

    private let searchImageView = NSImageView()
    private let textField = PickerSearchTextField()
    private let textFieldContainerView = BaseView()
    
    var onTextChange: dispatch_block_t?
    var text: String {
        return textField.stringValue ?? ""
    }
    
    var viewModel: PickerSearchFieldViewModel {
        didSet {
            didSetViewModel()
        }
    }
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    required init(viewModel: PickerSearchFieldViewModel) {
        self.viewModel = viewModel
        super.init(frame: CGRect.zero)
        didSetViewModel()
        setupTextField()
        setupSearchImageView()
        setupTextFieldContainerView()
        textField.drawsBackground = false
        
        textFieldContainerView.disableThemeObserver = true
        
        if NSUserDefaults.themeMode() == .Dark {
            backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
        } else {
            backgroundColor = CashewColor.backgroundColor()
        }
        
        textFieldContainerView.backgroundColor = backgroundColor

        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if mode == .Dark {
                strongSelf.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                strongSelf.backgroundColor = CashewColor.backgroundColor()
            }
            
            strongSelf.textField.textColor = CashewColor.foregroundColor()
            strongSelf.textFieldContainerView.backgroundColor = strongSelf.backgroundColor
            strongSelf.didSetViewModel()
            
            if let fieldEditor = strongSelf.window?.fieldEditor(true, forObject: self) as? NSTextView where strongSelf.window?.firstResponder == strongSelf.textField {
                fieldEditor.insertionPointColor = CashewColor.foregroundColor()
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    private func setupTextField() {
        guard textField.superview == nil else { return }
        textFieldContainerView.addSubview(textField)
        
        textField.focusRingType = .None
        textField.usesSingleLineMode = true
        textField.bordered = false
        textField.delegate = self
        textField.font = PickerSearchField.textFont
    }
    
    
    private func didSetViewModel() {
        textField.placeholderAttributedString = NSAttributedString(string: viewModel.placeHolderText, attributes:  [NSFontAttributeName: NSFont.systemFontOfSize(14) , NSForegroundColorAttributeName: CashewColor.foregroundSecondaryColor()])
    }
    
    private func setupTextFieldContainerView() {
        guard textFieldContainerView.superview == nil else { return }
        addSubview(textFieldContainerView)
    }
    
    private func setupSearchImageView() {
        guard searchImageView.superview == nil else { return }
        textFieldContainerView.addSubview(searchImageView)
        searchImageView.image = NSImage(named:"search")?.imageWithTintColor(PickerSearchField.placeholderColor)
    }
    
    // MARK: Layouts 
    
    override func layout() {

        guard let image = NSImage(named:"search")?.imageWithTintColor(PickerSearchField.placeholderColor) else { return }
        
        var searchImageSize = image.size
        image.size = CGSize(width: searchImageSize.width * 0.9, height: searchImageSize.height * 0.9)
        searchImageView.image = image
        
        let textFieldContainerViewRect = CGRectIntegralMake(x: 0, y: 0, width: bounds.width, height: bounds.height)
        
        searchImageSize = image.size
        let searchImageViewFrame = CGRectIntegralMake(x: PickerSearchField.padding * 2, y: bounds.height / 2.0 - searchImageSize.height / 2.0 - 3, width: searchImageSize.width, height: searchImageSize.height)
        
        let textFieldWidth = bounds.width - PickerSearchField.padding * 2 - searchImageViewFrame.maxX
        
        //let size = textField.placeholderString!.textSizeForWithAttributes([NSFontAttributeName: textField.font!], containerSize: CGSize(width: textFieldWidth, height: CGFloat.max))
        let textFieldTop = textFieldContainerViewRect.height / 2.0 - PickerSearchField.textFieldHeight / 2.0
        let textFieldRect = CGRectIntegralMake(x: searchImageViewFrame.maxX + PickerSearchField.padding, y: textFieldTop, width: textFieldWidth, height: PickerSearchField.textFieldHeight)
        
        textFieldContainerView.frame = textFieldContainerViewRect;
        textField.frame = textFieldRect;
        searchImageView.frame = searchImageViewFrame
        
        super.layout()
    }
 

}


extension PickerSearchField: NSTextFieldDelegate {
    
    override func controlTextDidChange(obj: NSNotification) {
        if let onTextChange = onTextChange {
            //if (textField.stringValue as NSString).trimmedString()
            onTextChange()
        }
    }
    
}

private class PickerSearchTextField: NSTextField {
   
    private override func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()

        if let fieldEditor = window?.fieldEditor(true, forObject: self) as? NSTextView where success {
            fieldEditor.insertionPointColor = CashewColor.foregroundColor()
        }
        
        return success
    }
}


