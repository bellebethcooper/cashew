//
//  BaseView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 1/23/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

private class PopoverFixBackgroundView: NSView {
    
    var backgroundColor: NSColor? {
        didSet {
            needsDisplay = true
            needsToDraw(bounds)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let color = backgroundColor {
            color.set()
//            NSRect.fill(self.bounds)
        }
    }
}


@IBDesignable
@objc class BaseView: NSView {
    
    fileprivate let popoverFixBgView = PopoverFixBackgroundView()
    fileprivate var roundedCornerMask: CAShapeLayer?
    
    @objc var allowMouseToMoveWindow = true
    @objc var disableThemeObserver = false {
        didSet {
            if disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(self)
            }
        }
    }
    var objectValue: AnyObject?
    
    @IBInspectable var shouldAllowVibrancy: Bool = true
    
    @objc var popoverBackgroundColorFixEnabed: Bool = false
    
    override var allowsVibrancy: Bool {
        get {
            return shouldAllowVibrancy
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if let aFrameView = window?.contentView?.superview , popoverBackgroundColorFixEnabed {
            popoverFixBgView.frame = aFrameView.bounds
            popoverFixBgView.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
            aFrameView.addSubview(popoverFixBgView, positioned:NSWindow.OrderingMode.below, relativeTo: aFrameView)
        }
    }
    
    @IBInspectable var backgroundColor: NSColor! {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.layer?.backgroundColor = self.backgroundColor.cgColor
            CATransaction.commit()
            popoverFixBgView.backgroundColor = backgroundColor
        }
    }
    
    @IBInspectable var borderColor: NSColor? {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.layer?.borderColor = borderColor?.cgColor
            self.layer?.borderWidth = 1
            CATransaction.commit()
            self.window?.contentView
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.layer?.cornerRadius = cornerRadius
            self.layer?.masksToBounds = true
            CATransaction.commit()
        }
    }
    
    override var mouseDownCanMoveWindow: Bool {
        return self.allowMouseToMoveWindow
    }
    
    @objc var userInteractionEnabled: Bool = true
    
    override func mouseDown(with theEvent: NSEvent) {
        if userInteractionEnabled {
            super.mouseDown(with: theEvent)
        }
    }
    
    static func instantiateFromNib<T: BaseView>(_ viewType: T.Type) -> T? {
        var viewArray: NSArray?
        let className = NSStringFromClass(viewType).components(separatedBy: ".").last! as String
        
        //DDLogDebug(" viewType = %@", className)
        assert(Thread.isMainThread)
        Bundle.main.loadNibNamed(className, owner: nil, topLevelObjects: &viewArray)
        
        for view in viewArray as! [NSObject] {
            if object_getClass(view) == viewType {
                return view as? T
            }
        }
        
        return nil //viewArray!.objectAtIndex(1) as! T
    }

    @objc
    static func instantiateFromNib() -> Self {
        return instantiateFromNib(self)!
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    deinit {
        ThemeObserverController.sharedInstance.removeThemeObserver(self)
    }
    
    fileprivate func setup() {
        self.wantsLayer = true
        self.canDrawConcurrently = true;
        
        if disableThemeObserver {
            return;
        }
        
        ThemeObserverController.sharedInstance.addThemeObserver(self) { [weak self] (mode) in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(strongSelf)
                return;
            }
            strongSelf.backgroundColor = CashewColor.backgroundColor()
        }
    }

    override var isFlipped: Bool {
        get {
            return true
        }
    }
    
    override func layout() {
        if let roundedCornerMask = roundedCornerMask {
            roundedCornerMask.frame = bounds
        }
        super.layout()
    }
    
    func setImageURL(_ url: URL?) {
        if let aURL = url {
            if let cachedImage = QImageManager.shared().cachedImage(for: aURL) {
                self.layer?.contents = cachedImage
                return
            }
            QImageManager.shared().downloadImageURL(aURL, onCompletion: {[weak self] (image, downloadURL, err) -> Void in
                guard aURL == downloadURL else { return }
                
                if err != nil {
                    DispatchQueue.main.async {
                        CATransaction.begin()
                        CATransaction.setDisableActions(true)
                        self?.layer?.contents = nil
                        CATransaction.commit()
                    }
                    return
                }
                
                
                DispatchQueue.global(qos: .background).async {
                    assert(Thread.isMainThread == false)
                    guard let strongSelf = self else {
                        return;
                    }
                    
                    let strongSelfSize = strongSelf.bounds.size
                    
                    guard strongSelfSize.width > 0 && strongSelfSize.height > 0 && (image?.size.height)! > CGFloat(0) && (image?.size.width)! > 0 else {
                        return
                    }
                    
                    //if let strongSelf = self where image.size.height > 0 && image.size.width > 0 {
                    let smallImage = NSImage(size: strongSelfSize)
                    smallImage.lockFocus()
                    image?.size = strongSelfSize
                    NSGraphicsContext.current?.imageInterpolation = .high
                    image?.draw(at: NSPoint.zero, from: CGRect(x: 0, y: 0, width: strongSelfSize.width, height: strongSelfSize.height), operation: .copy, fraction: 1.0)
                    smallImage.unlockFocus()
                    
                    let cgImage = smallImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
                    DispatchQueue.main.async {
                        CATransaction.begin()
                        CATransaction.setDisableActions(true)
                        self?.layer?.contents = cgImage; //image
                        CATransaction.commit()
                    }
                    // }
                }
                })
        } else {
            self.layer?.contents = nil
        }
    }
    
}
