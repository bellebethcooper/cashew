//
//  QBaseWindowController.m
//  Issues
//
//  Created by Hicham Bouabdallah on 3/26/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseWindowController.h"

@interface QBaseWindowController ()

@end

@implementation QBaseWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.window.contentView.wantsLayer = true;
    self.window.contentView.layer.masksToBounds = true;
    
    if (self.viewController) {
        [self.contentViewController addChildViewController:self.viewController];
        [self.window.contentView addSubview:self.viewController.view];
        
        self.viewController.view.translatesAutoresizingMaskIntoConstraints = false;
        [self.viewController.view.leftAnchor constraintEqualToAnchor:self.window.contentView.leftAnchor].active = true;
        [self.viewController.view.rightAnchor constraintEqualToAnchor:self.window.contentView.rightAnchor ].active = true;
        [self.viewController.view.topAnchor constraintEqualToAnchor:self.window.contentView.topAnchor].active = true;
        [self.viewController.view.bottomAnchor constraintEqualToAnchor:self.window.contentView.bottomAnchor].active = true;
    }
}



- (void)windowWillClose:(NSNotification *)notification
{
    [self.baseWindowControllerDelegate willCloseBaseWindowController:self];
}

@end

//@objc protocol BaseWindowControllerDelegate: class {
//    func willCloseBaseWindowController(baseWindowController: BaseWindowController);
//}
//
//@objc(BaseWindowController)
//@IBDesignable class BaseWindowController: NSWindowController {
//    
//    @IBOutlet weak var windowContentView: BaseWindowView!
//    
//    var viewController: NSViewController?
//    weak var baseWindowControllerDelegate: BaseWindowControllerDelegate?
//    
//    override func windowDidLoad() {
//        super.windowDidLoad()
//        
//        if let aViewController = self.viewController {
//            
//            self.contentViewController?.addChildViewController(aViewController)
//            
//            self.windowContentView.addSubview(aViewController.view)
//            aViewController.view.translatesAutoresizingMaskIntoConstraints = false
//            
//            aViewController.view.leftAnchor.constraintEqualToAnchor(windowContentView.leftAnchor).active = true
//            aViewController.view.rightAnchor.constraintEqualToAnchor(windowContentView.rightAnchor).active = true
//            aViewController.view.topAnchor.constraintEqualToAnchor(windowContentView.topAnchor, constant: 25).active = true
//            aViewController.view.bottomAnchor.constraintEqualToAnchor(windowContentView.bottomAnchor).active = true
//        }
//    }
//    
//    
//    
//    
//    func windowWillClose(notification: NSNotification) {
//        self.baseWindowControllerDelegate?.willCloseBaseWindowController(self)
//    }
//}