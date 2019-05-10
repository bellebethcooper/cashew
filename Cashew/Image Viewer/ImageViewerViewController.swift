//
//  ImageViewerViewController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/4/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import os.log

@objc(SRImageViewerItemViewController)
class ImageViewerItemViewController: BaseViewController { }

@objc(SRImageViewerViewController)
class ImageViewerViewController: NSViewController {
    
    @IBOutlet weak var nextImageButton: NSButton!
    @IBOutlet weak var previousImageButton: NSButton!
    
    @IBOutlet weak var arrowContainerView: BaseView!
    fileprivate var pageController: NSPageController?
    @IBOutlet weak var pageControllerView: BaseView!
    fileprivate let imageCache = NSCache<AnyObject, AnyObject>()
    var onScrollToPage: ((Int) -> ())?
    var imageURLs = [URL]() {
        didSet {
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
            pageController.transitionStyle = .horizontalStrip
            
            if (pageController.arrangedObjects.count == 1) {
                self.nextImageButton.isHidden = true
                self.previousImageButton.isHidden  = true
            } else {
                self.nextImageButton.isHidden = false
                self.previousImageButton.isHidden  = false
            }
            if let onScrollToPage = self.onScrollToPage {
                onScrollToPage(1)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ImageViewerViewController.windowDidEndLiveResize(_:)), name: NSNotification.Name.qWindowDidEndLiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ImageViewerViewController.windowWillStartLiveResize(_:)), name: NSNotification.Name.qWindowWillStartLiveNotification, object: nil)
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        configureButtons()
        imageCache.countLimit = 50
        arrowContainerView.disableThemeObserver = true
        arrowContainerView.backgroundColor = NSColor.clear
        pageControllerView.disableThemeObserver = true
        pageControllerView.backgroundColor = NSColor.black
    }
    
    fileprivate func configureButtons() {
        nextImageButton.image = nextImageButton.image?.withTintColor(NSColor.white)
        previousImageButton.image = previousImageButton.image?.withTintColor(NSColor.white)
    }
    
    @objc func windowWillStartLiveResize(_ notification: Notification) {
        guard let window = self.view.window, let senderWindow = notification.object as? NSWindow , senderWindow == window else { return }
        //pageWhileResizing = currentPage
    }
    
    @objc func windowDidEndLiveResize(_ notification: Notification) {
        // guard let window = self.view.window, senderWindow = notification.object as? NSWindow where senderWindow == window else { return }
        //  pageWhileResizing = nil
    }
    
    func scrollViewDidScroll(_ notification: Notification) {
        //DDLogDebug("scrollOffset \(collectionViewScrollView.documentVisibleRect)")
    }
    
    fileprivate func preCacheImages() {
        imageCache.removeAllObjects()
        for url in imageURLs {
            QImageManager.shared().downloadImageURL(url, onCompletion: { [weak self] (image, downloadURL, err) in
                guard let image = image else  { return }
                self?.imageCache.setObject(image, forKey: downloadURL as AnyObject)
                })
        }
    }
    
    
    // MARK: Actions
    @IBAction func didClickPreviousButton(_ sender: AnyObject) {
        //pageController.selectedIndex = max(0, pageController.selectedIndex - 1)
        guard let pageController = pageController else { return }
        pageController.navigateBack(sender)
    }
    
    @IBAction func didClickNextButton(_ sender: AnyObject) {
        //pageController.selectedIndex = min(imageURLs.count - 1, pageController.selectedIndex + 1)
        guard let pageController = pageController else { return }
        pageController.navigateForward(sender)
    }
    
}


extension ImageViewerViewController: NSPageControllerDelegate {
    
    func pageController(_ pageController: NSPageController, didTransitionTo object: Any) {
        if let onScrollToPage = onScrollToPage {
            onScrollToPage(pageController.selectedIndex + 1)
        }
    }
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
        
        if let url = object as? URL, let index = imageURLs.firstIndex(of: url) {
            return String(index)
        }
        
        return ""
    }
    
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
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
        [imageView.leftAnchor.constraint(equalTo: imageViewContainerView.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: imageViewContainerView.rightAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageViewContainerView.bottomAnchor),
            imageView.topAnchor.constraint(equalTo: imageViewContainerView.topAnchor)
            ].forEach { (constraint) in
                // constraint.priority = NSLayoutPriorityWindowSizeStayPut - 1
                constraint.isActive = true
        }
        
        imageView.wantsLayer = true
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.layer?.backgroundColor = NSColor.black.cgColor
        
        viewController.view.autoresizingMask = [.width, .height]
        viewController.view.frame = pageController.view.bounds
        viewController.view.wantsLayer = true
        if let viewControllerView = viewController.view as? BaseView {
            viewControllerView.disableThemeObserver = true
        }
        viewController.view.layer?.backgroundColor = NSColor.black.cgColor
        
        let url = imageURLs[index]
        
        if let image = imageCache.object(forKey: url as AnyObject) as? NSImage {
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
            progressIndicator.style = .spinning
            viewController.view.addSubview(progressIndicator)
            progressIndicator.translatesAutoresizingMaskIntoConstraints = false
            progressIndicator.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor).isActive = true
            progressIndicator.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor).isActive = true
            progressIndicator.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
            progressIndicator.startAnimation(nil)
            QImageManager.shared().downloadImageURL(url, onCompletion: { [weak self] (image, downloadURL, err) in
                guard let strongSelf = self , downloadURL == url && err == nil else {
                    os_log("Error downloading: %@", log: .default, type: .debug, err!.localizedDescription)
                    DispatchQueue.main.async {
                        progressIndicator.stopAnimation(nil)
                        progressIndicator.removeFromSuperview()
                    }
                    return
                }
                // let aspectRatio = image.size.width / image.size.height
                if (image?.size.width)! >= (image?.size.height)! {
                    image?.size = NSSize(width: strongSelf.view.bounds.size.width, height: strongSelf.view.bounds.size.width * ((image?.size.height)! / (image?.size.width)!) )
                } else {
                    image?.size = NSSize(width: strongSelf.view.bounds.size.height * ((image?.size.width)! / (image?.size.height)!) , height: strongSelf.view.bounds.size.height)
                }
                DispatchQueue.main.async {
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

