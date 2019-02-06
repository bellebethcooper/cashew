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
    
    fileprivate static let padding: CGFloat = 6.0
    fileprivate static let textFieldHeight: CGFloat = 22.0
    fileprivate static let placeholderColor = NSColor(calibratedWhite: 0.7, alpha: 1)
    fileprivate static let textFont = NSFont.systemFont(ofSize: 14)
    //private static let toolbarView:

    fileprivate let searchImageView = NSImageView()
    fileprivate let textField = PickerSearchTextField()
    fileprivate let textFieldContainerView = BaseView()
    
    var onTextChange: (()->())?
    var text: String {
        return textField.stringValue
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
        
        if UserDefaults.themeMode() == .dark {
            backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
        } else {
            backgroundColor = CashewColor.backgroundColor()
        }
        
        textFieldContainerView.backgroundColor = backgroundColor

        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if mode == .dark {
                strongSelf.backgroundColor = DarkModeColor.sharedInstance.popoverBackgroundColor()
            } else {
                strongSelf.backgroundColor = CashewColor.backgroundColor()
            }
            
            strongSelf.textField.textColor = CashewColor.foregroundColor()
            strongSelf.textFieldContainerView.backgroundColor = strongSelf.backgroundColor
            strongSelf.didSetViewModel()
            
            if let fieldEditor = strongSelf.window?.fieldEditor(true, for: self) as? NSTextView , strongSelf.window?.firstResponder == strongSelf.textField {
                fieldEditor.insertionPointColor = CashewColor.foregroundColor()
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    fileprivate func setupTextField() {
        guard textField.superview == nil else { return }
        textFieldContainerView.addSubview(textField)
        
        textField.focusRingType = .none
        textField.usesSingleLineMode = true
        textField.isBordered = false
        textField.delegate = self
        textField.font = PickerSearchField.textFont
    }
    
    
    fileprivate func didSetViewModel() {
        textField.placeholderAttributedString = NSAttributedString(string: viewModel.placeHolderText, attributes:  [NSAttributedStringKey.font: NSFont.systemFont(ofSize: 14) , NSAttributedStringKey.foregroundColor: CashewColor.foregroundSecondaryColor()])
    }
    
    fileprivate func setupTextFieldContainerView() {
        guard textFieldContainerView.superview == nil else { return }
        addSubview(textFieldContainerView)
    }
    
    fileprivate func setupSearchImageView() {
        guard searchImageView.superview == nil else { return }
        textFieldContainerView.addSubview(searchImageView)
        searchImageView.image = NSImage(named:NSImage.Name(rawValue: "search"))?.withTintColor(PickerSearchField.placeholderColor)
    }
    
    // MARK: Layouts 
    
    override func layout() {

        guard let image = NSImage(named:NSImage.Name(rawValue: "search"))?.withTintColor(PickerSearchField.placeholderColor) else { return }
        
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
    
    override func controlTextDidChange(_ obj: Notification) {
        if let onTextChange = onTextChange {
            //if (textField.stringValue as NSString).trimmedString()
            onTextChange()
        }
    }
    
}

private class PickerSearchTextField: NSTextField {
   
    fileprivate override func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()

        if let fieldEditor = window?.fieldEditor(true, for: self) as? NSTextView , success {
            fieldEditor.insertionPointColor = CashewColor.foregroundColor()
        }
        
        return success
    }
}


