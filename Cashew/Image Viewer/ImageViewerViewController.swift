//
//  ImageViewerViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/4/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRImageViewerItemViewController)
class ImageViewerItemViewController: BaseViewController { }

@objc(SRImageViewerViewController)
class ImageViewerViewController: NSViewController {
    
    @IBOutlet weak var nextImageButton: NSButton!
    @IBOutlet weak var previousImageButton: NSButton!
    
    @IBOutlet weak var arrowContainerView: BaseView!
    private var pageController: NSPageController?
    @IBOutlet weak var pageControllerView: BaseView!
    private let imageCache = NSCache()
    var onScrollToPage: ((Int) -> ())?
    var imageURLs = [NSURL]() {
        didSet {
            Analytics.logCustomEventWithName("Show Image Viewer Controller", customAttributes: ["imageURLCount": imageURLs.count])
            preCacheImages()
            self.pageControllerView.subviews.forEach { (view) in
                view.removeFromSuperview()
            }
            let pageController = NSPageController()
            self.pageController = pageController
            pageController.view = self.pageControllerView
            pageController.delegate = self
            pageController.arrangedObjects = self.imageURLs
            pageController.selectedIndex = 0
            pageController.transitionStyle = .HorizontalStrip
            
            if (pageController.arrangedObjects.count == 1) {
                self.nextImageButton.hidden = true
                self.previousImageButton.hidden  = true
            } else {
                self.nextImageButton.hidden = false
                self.previousImageButton.hidden  = false
            }
            if let onScrollToPage = self.onScrollToPage {
                onScrollToPage(1)
            }
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ImageViewerViewController.windowDidEndLiveResize(_:)), name: kQWindowDidEndLiveNotificationNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ImageViewerViewController.windowWillStartLiveResize(_:)), name: kQWindowWillStartLiveNotificationNotification, object: nil)
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.blackColor().CGColor
        
        configureButtons()
        imageCache.countLimit = 50
        arrowContainerView.disableThemeObserver = true
        arrowContainerView.backgroundColor = NSColor.clearColor()
        pageControllerView.disableThemeObserver = true
        pageControllerView.backgroundColor = NSColor.blackColor()
    }
    
    private func configureButtons() {
        nextImageButton.image = nextImageButton.image?.imageWithTintColor(NSColor.whiteColor())
        previousImageButton.image = previousImageButton.image?.imageWithTintColor(NSColor.whiteColor())
    }
    
    func windowWillStartLiveResize(notification: NSNotification) {
        guard let window = self.view.window, senderWindow = notification.object as? NSWindow where senderWindow == window else { return }
        //pageWhileResizing = currentPage
    }
    
    func windowDidEndLiveResize(notification: NSNotification) {
        // guard let window = self.view.window, senderWindow = notification.object as? NSWindow where senderWindow == window else { return }
        //  pageWhileResizing = nil
    }
    
    func scrollViewDidScroll(notification: NSNotification) {
        //DDLogDebug("scrollOffset \(collectionViewScrollView.documentVisibleRect)")
    }
    
    private func preCacheImages() {
        imageCache.removeAllObjects()
        for url in imageURLs {
            QImageManager.sharedImageManager().downloadImageURL(url, onCompletion: { [weak self] (image, downloadURL, err) in
                guard let image = image else  { return }
                self?.imageCache.setObject(image, forKey: downloadURL)
                })
        }
    }
    
    
    // MARK: Actions
    @IBAction func didClickPreviousButton(sender: AnyObject) {
        //pageController.selectedIndex = max(0, pageController.selectedIndex - 1)
        guard let pageController = pageController else { return }
        pageController.navigateBack(sender)
    }
    
    @IBAction func didClickNextButton(sender: AnyObject) {
        //pageController.selectedIndex = min(imageURLs.count - 1, pageController.selectedIndex + 1)
        guard let pageController = pageController else { return }
        pageController.navigateForward(sender)
    }
    
}


extension ImageViewerViewController: NSPageControllerDelegate {
    
    func pageController(pageController: NSPageController, didTransitionToObject object: AnyObject) {
        if let onScrollToPage = onScrollToPage {
            onScrollToPage(pageController.selectedIndex + 1)
        }
    }
    
    func pageController(pageController: NSPageController, identifierForObject object: AnyObject) -> String {
        
        if let url = object as? NSURL, index = imageURLs.indexOf(url) {
            return String(index)
        }
        
        return ""
    }
    
    func pageController(pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        let index = (identifier as NSString).integerValue
        
        let viewController = ImageViewerItemViewController()
        let imageView = NSImageView()
        let imageViewContainerView = BaseView()
        viewController.view.addSubview(imageViewContainerView)
        imageViewContainerView.pinAnchorsToSuperview()
        imageViewContainerView.allowMouseToMoveWindow = true
        //imageViewContainerView.borderColor = NSColor.redColor()
        
        imageViewContainerView.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        [imageView.leftAnchor.constraintEqualToAnchor(imageViewContainerView.leftAnchor),
            imageView.rightAnchor.constraintEqualToAnchor(imageViewContainerView.rightAnchor),
            imageView.bottomAnchor.constraintEqualToAnchor(imageViewContainerView.bottomAnchor),
            imageView.topAnchor.constraintEqualToAnchor(imageViewContainerView.topAnchor)
            ].forEach { (constraint) in
                // constraint.priority = NSLayoutPriorityWindowSizeStayPut - 1
                constraint.active = true
        }
        
        imageView.wantsLayer = true
        imageView.imageScaling = .ScaleProportionallyUpOrDown
        imageView.layer?.backgroundColor = NSColor.blackColor().CGColor
        
        viewController.view.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        viewController.view.frame = pageController.view.bounds
        viewController.view.wantsLayer = true
        if let viewControllerView = viewController.view as? BaseView {
            viewControllerView.disableThemeObserver = true
        }
        viewController.view.layer?.backgroundColor = NSColor.blackColor().CGColor
        
        let url = imageURLs[index]
        
        if let image = imageCache.objectForKey(url) as? NSImage {
            //let aspectRatio = image.size.width /
            if image.size.width >= image.size.height {
                image.size = NSSize(width: view.bounds.size.width, height: view.bounds.size.width * (image.size.height / image.size.width) )
            } else {
                image.size = NSSize(width: view.bounds.size.height * (image.size.width / image.size.height) , height: view.bounds.size.height)
            }
            if imageView.image != image {
                imageView.image = image
                // imageView.frame = view.bounds
            }
        } else {
            let progressIndicator = NSProgressIndicator()
            progressIndicator.style = .SpinningStyle
            viewController.view.addSubview(progressIndicator)
            progressIndicator.translatesAutoresizingMaskIntoConstraints = false
            progressIndicator.centerXAnchor.constraintEqualToAnchor(viewController.view.centerXAnchor).active = true
            progressIndicator.centerYAnchor.constraintEqualToAnchor(viewController.view.centerYAnchor).active = true
            progressIndicator.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
            progressIndicator.startAnimation(nil)
            QImageManager.sharedImageManager().downloadImageURL(url, onCompletion: { [weak self] (image, downloadURL, err) in
                guard let strongSelf = self where downloadURL == url && err == nil else {
                    DDLogDebug("error downloading \(err)")
                    dispatch_async(dispatch_get_main_queue()) {
                        progressIndicator.stopAnimation(nil)
                        progressIndicator.removeFromSuperview()
                    }
                    return
                }
                // let aspectRatio = image.size.width / image.size.height
                if image.size.width >= image.size.height {
                    image.size = NSSize(width: strongSelf.view.bounds.size.width, height: strongSelf.view.bounds.size.width * (image.size.height / image.size.width) )
                } else {
                    image.size = NSSize(width: strongSelf.view.bounds.size.height * (image.size.width / image.size.height) , height: strongSelf.view.bounds.size.height)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    imageView.image = image
                    progressIndicator.stopAnimation(nil)
                    progressIndicator.removeFromSuperview()
                    //imageView.frame = strongSelf.view.bounds
                }
                })
        }
        
        return viewController
    }
}

