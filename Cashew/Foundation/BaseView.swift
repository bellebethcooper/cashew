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
            needsToDrawRect(bounds)
        }
    }
    
    override func drawRect(dirtyRect: NSRect) {
        if let color = backgroundColor {
            color.set()
            NSRectFill(self.bounds);
        }
    }
}


@IBDesignable class BaseView: NSView {
    
    private let popoverFixBgView = PopoverFixBackgroundView()
    private var roundedCornerMask: CAShapeLayer?
    
    var allowMouseToMoveWindow = true
    var disableThemeObserver = false {
        didSet {
            if disableThemeObserver {
                ThemeObserverController.sharedInstance.removeThemeObserver(self)
            }
        }
    }
    var objectValue: AnyObject?
    
    @IBInspectable var shouldAllowVibrancy: Bool = true
    
    var popoverBackgroundColorFixEnabed: Bool = false
    
    override var allowsVibrancy: Bool {
        get {
            return shouldAllowVibrancy
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if let aFrameView = window?.contentView?.superview where popoverBackgroundColorFixEnabed {
            popoverFixBgView.frame = aFrameView.bounds
            popoverFixBgView.autoresizingMask = [NSAutoresizingMaskOptions.ViewWidthSizable, NSAutoresizingMaskOptions.ViewHeightSizable]
            aFrameView.addSubview(popoverFixBgView, positioned:NSWindowOrderingMode.Below, relativeTo: aFrameView)
        }
    }
    
    @IBInspectable var backgroundColor: NSColor! {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.layer?.backgroundColor = self.backgroundColor.CGColor
            CATransaction.commit()
            popoverFixBgView.backgroundColor = backgroundColor
        }
    }
    
    @IBInspectable var borderColor: NSColor? {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.layer?.borderColor = borderColor?.CGColor
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
    
    var userInteractionEnabled: Bool = true

    
    override func mouseDown(theEvent: NSEvent) {
        if userInteractionEnabled {
            super.mouseDown(theEvent)
        }
    }
    
    static func instantiateFromNib<T: BaseView>(viewType: T.Type) -> T? {
        var viewArray: NSArray?
        let className = NSStringFromClass(viewType).componentsSeparatedByString(".").last! as String
        
        //DDLogDebug(" viewType = %@", className)
        assert(NSThread.isMainThread())
        NSBundle.mainBundle().loadNibNamed(className, owner: nil, topLevelObjects: &viewArray)
        
        for view in viewArray as! [NSObject] {
            if object_getClass(view) == viewType {
                return view as? T
            }
        }
        
        return nil //viewArray!.objectAtIndex(1) as! T
    }
    
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
    
    private func setup() {
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

    override var flipped: Bool {
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
    
    func setImageURL(url: NSURL?) {
        if let aURL = url {
            if let cachedImage = QImageManager.sharedImageManager().cachedImageForURL(aURL) {
                self.layer?.contents = cachedImage
                return
            }
            QImageManager.sharedImageManager().downloadImageURL(aURL, onCompletion: {[weak self] (image, downloadURL, err) -> Void in
                guard aURL.isEqualTo(downloadURL) else { return }
                
                if err != nil {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        CATransaction.begin()
                        CATransaction.setDisableActions(true)
                        self?.layer?.contents = nil
                        CATransaction.commit()
                    })
                    return
                }
                
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                    assert(NSThread.isMainThread() == false)
                    guard let strongSelf = self else {
                        return;
                    }
                    
                    let strongSelfSize = strongSelf.bounds.size
                    
                    guard strongSelfSize.width > 0 && strongSelfSize.height > 0 && image.size.height > 0 && image.size.width > 0 else {
                        return
                    }
                    
                    //if let strongSelf = self where image.size.height > 0 && image.size.width > 0 {
                    let smallImage = NSImage(size: strongSelfSize)
                    smallImage.lockFocus()
                    image.size = strongSelfSize
                    NSGraphicsContext.currentContext()?.imageInterpolation = .High
                    image.drawAtPoint(NSPoint.zero, fromRect: CGRectMake(0, 0, strongSelfSize.width, strongSelfSize.height), operation: .Copy, fraction: 1.0)
                    smallImage.unlockFocus()
                    
                    let cgImage = smallImage.CGImageForProposedRect(nil, context: nil, hints: nil)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        CATransaction.begin()
                        CATransaction.setDisableActions(true)
                        self?.layer?.contents = cgImage; //image
                        CATransaction.commit()
                    })
                    // }
                })
                })
        } else {
            self.layer?.contents = nil
        }
    }
    
}
