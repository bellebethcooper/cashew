//
//  ImageViewerWindowController.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/4/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRImageViewerWindowController)
class ImageViewerWindowController: NSWindowController {
    
    @IBOutlet weak var windowContainerView: NSView!
    @IBOutlet weak var titleLabel: NSTextField!
    
    let imageViewerViewController = ImageViewerViewController(nibName: "ImageViewerViewController", bundle: nil)!
    var imageURLs = [NSURL]() {
        didSet {
            imageViewerViewController.imageURLs = imageURLs
        }
    }
    
    var issue: QIssue?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        guard let contentView = self.window?.contentView else { return }
        self.window?.titlebarAppearsTransparent = true
        self.window?.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        contentView.wantsLayer = true
        contentView.layer?.masksToBounds = true
        contentView.layer?.backgroundColor = NSColor.blackColor().CGColor
        windowContainerView.wantsLayer = true
        windowContainerView.layer?.backgroundColor = NSColor.blackColor().CGColor
        titleLabel.superview?.addSubview(imageViewerViewController.view)
        titleLabel.superview?.addSubview(titleLabel)
        
        imageViewerViewController.view.pinAnchorsToSuperview()
        let onScrollToPage = { [weak self] (page: Int) in
            guard let strongSelf = self else { return }
            
            var suffix = ""
            if let issue = self?.issue {
                suffix = " - \(issue.repository.fullName) - #\(issue.number)"
            }
            
            if strongSelf.imageViewerViewController.imageURLs.count == 1 {
                strongSelf.titleLabel.stringValue = "1 Photo \(suffix)"
            } else {
                strongSelf.titleLabel.stringValue = "\(page) of \(strongSelf.imageViewerViewController.imageURLs.count) Photos \(suffix)"
            }
        }
        imageViewerViewController.onScrollToPage = onScrollToPage
    }
    
    override func keyDown(event: NSEvent) {
        switch event.keyCode {
        case 123:
            imageViewerViewController.didClickPreviousButton(imageViewerViewController.previousImageButton)
           // super.keyDown(event)
        case 124:
            imageViewerViewController.didClickNextButton(imageViewerViewController.nextImageButton)
          //  super.keyDown(event)
        default:
            super.keyDown(event)
        }
    }
}
