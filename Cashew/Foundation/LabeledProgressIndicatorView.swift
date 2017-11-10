//
//  LabeledProgressIndicatorView.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/23/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class LabeledProgressIndicatorView: BaseView {
    
    private static let progressIndicatorSize = NSSize(width: 14, height: 14)
    private static let progressIndicatorLeftPadding: CGFloat = 10.0
    private static let progressLabelLeftPadding: CGFloat = 5.0
    
    private let uploadStatusContainerView = BaseView()
    private let progressLabel = BaseLabel()
    private let progressIndicator = NSProgressIndicator()
    
    convenience init() {
        self.init(frame: NSRect.zero)
    }
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    required override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupStatusLabel()
        setupThemeObserver()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: NSSize {
        get {
            let width =  LabeledProgressIndicatorView.progressIndicatorLeftPadding + LabeledProgressIndicatorView.progressIndicatorSize.width + LabeledProgressIndicatorView.progressLabelLeftPadding + progressLabel.intrinsicContentSize.width
            let height = max(progressLabel.intrinsicContentSize.height, LabeledProgressIndicatorView.progressIndicatorSize.height)
            return NSSize(width: width, height: height)
        }
    }
    
    private func setupThemeObserver() {
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(strongSelf)
                return;
            }
            strongSelf.backgroundColor = CashewColor.backgroundColor()
            if (.Dark == mode) {
                let appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
                strongSelf.progressIndicator.appearance = appearance
            } else {
                let appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
                strongSelf.progressIndicator.appearance = appearance
            }
        }
    }
    
    private func setupStatusLabel() {
        addSubview(uploadStatusContainerView)
        
        uploadStatusContainerView.hidden = true
        uploadStatusContainerView.pinAnchorsToSuperview()
        uploadStatusContainerView.backgroundColor =  NSColor.clearColor() //NSColor(calibratedWhite: 1, alpha: 0.95)
        uploadStatusContainerView.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        uploadStatusContainerView.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        
        uploadStatusContainerView.addSubview(progressIndicator)
        progressIndicator.style = .SpinningStyle
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        progressIndicator.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        progressIndicator.leftAnchor.constraintEqualToAnchor(leftAnchor, constant: LabeledProgressIndicatorView.progressIndicatorLeftPadding).active = true
        progressIndicator.centerYAnchor.constraintEqualToAnchor(uploadStatusContainerView.centerYAnchor).active = true
        progressIndicator.heightAnchor.constraintEqualToConstant(LabeledProgressIndicatorView.progressIndicatorSize.height).active = true
        progressIndicator.widthAnchor.constraintEqualToConstant(LabeledProgressIndicatorView.progressIndicatorSize.width).active = true
        
        uploadStatusContainerView.addSubview(progressLabel)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.setContentHuggingPriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        progressLabel.setContentCompressionResistancePriority(NSLayoutPriorityRequired, forOrientation: .Vertical)
        progressLabel.centerYAnchor.constraintEqualToAnchor(uploadStatusContainerView.centerYAnchor).active = true
        progressLabel.leftAnchor.constraintEqualToAnchor(progressIndicator.rightAnchor, constant: LabeledProgressIndicatorView.progressLabelLeftPadding).active = true
        progressLabel.rightAnchor.constraintEqualToAnchor(uploadStatusContainerView.rightAnchor, constant: 12).active = true
        progressLabel.textColor = NSColor.darkGrayColor()
        progressLabel.font = NSFont.systemFontOfSize(12)
        progressLabel.stringValue = ""
    }
    
    func showProgressWithString(text: String) {
        self.progressLabel.stringValue = text
        invalidateIntrinsicContentSize()
        self.progressIndicator.startAnimation(nil)
        self.uploadStatusContainerView.hidden = false
    }
    
    func hideProgress() {
        self.progressLabel.stringValue = ""
        invalidateIntrinsicContentSize()
        self.progressIndicator.stopAnimation(nil)
        self.uploadStatusContainerView.hidden = true
    }
}
