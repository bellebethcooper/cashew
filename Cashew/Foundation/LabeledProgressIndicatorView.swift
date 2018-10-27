//
//  LabeledProgressIndicatorView.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 6/23/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

class LabeledProgressIndicatorView: BaseView {
    
    fileprivate static let progressIndicatorSize = NSSize(width: 14, height: 14)
    fileprivate static let progressIndicatorLeftPadding: CGFloat = 10.0
    fileprivate static let progressLabelLeftPadding: CGFloat = 5.0
    
    fileprivate let uploadStatusContainerView = BaseView()
    fileprivate let progressLabel = BaseLabel()
    fileprivate let progressIndicator = NSProgressIndicator()
    
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
    
    fileprivate func setupThemeObserver() {
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(strongSelf)
                return;
            }
            strongSelf.backgroundColor = CashewColor.backgroundColor()
            if (.dark == mode) {
                let appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
                strongSelf.progressIndicator.appearance = appearance
            } else {
                let appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
                strongSelf.progressIndicator.appearance = appearance
            }
        }
    }
    
    fileprivate func setupStatusLabel() {
        addSubview(uploadStatusContainerView)
        
        uploadStatusContainerView.isHidden = true
        uploadStatusContainerView.pinAnchorsToSuperview()
        uploadStatusContainerView.backgroundColor =  NSColor.clear //NSColor(calibratedWhite: 1, alpha: 0.95)
        uploadStatusContainerView.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .vertical)
        uploadStatusContainerView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .vertical)
        
        uploadStatusContainerView.addSubview(progressIndicator)
        progressIndicator.style = .spinning
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .vertical)
        progressIndicator.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .vertical)
        progressIndicator.leftAnchor.constraint(equalTo: leftAnchor, constant: LabeledProgressIndicatorView.progressIndicatorLeftPadding).isActive = true
        progressIndicator.centerYAnchor.constraint(equalTo: uploadStatusContainerView.centerYAnchor).isActive = true
        progressIndicator.heightAnchor.constraint(equalToConstant: LabeledProgressIndicatorView.progressIndicatorSize.height).isActive = true
        progressIndicator.widthAnchor.constraint(equalToConstant: LabeledProgressIndicatorView.progressIndicatorSize.width).isActive = true
        
        uploadStatusContainerView.addSubview(progressLabel)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.setContentHuggingPriority(NSLayoutConstraint.Priority.required, for: .vertical)
        progressLabel.setContentCompressionResistancePriority(NSLayoutConstraint.Priority.required, for: .vertical)
        progressLabel.centerYAnchor.constraint(equalTo: uploadStatusContainerView.centerYAnchor).isActive = true
        progressLabel.leftAnchor.constraint(equalTo: progressIndicator.rightAnchor, constant: LabeledProgressIndicatorView.progressLabelLeftPadding).isActive = true
        progressLabel.rightAnchor.constraint(equalTo: uploadStatusContainerView.rightAnchor, constant: 12).isActive = true
        progressLabel.textColor = NSColor.darkGray
        progressLabel.font = NSFont.systemFont(ofSize: 12)
        progressLabel.stringValue = ""
    }
    
    func showProgressWithString(_ text: String) {
        self.progressLabel.stringValue = text
        invalidateIntrinsicContentSize()
        self.progressIndicator.startAnimation(nil)
        self.uploadStatusContainerView.isHidden = false
    }
    
    func hideProgress() {
        self.progressLabel.stringValue = ""
        invalidateIntrinsicContentSize()
        self.progressIndicator.stopAnimation(nil)
        self.uploadStatusContainerView.isHidden = true
    }
}
