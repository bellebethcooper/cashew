//
//  BaseViewController.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/28/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class BaseViewController: NSViewController {
    
    override func loadView() {
        self.view = BaseView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
}
