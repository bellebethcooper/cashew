//
//  SRMenu.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 9/11/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRMenu)
class SRMenu: NSMenu {
    
    convenience init() {
        self.init(title: "")
        DDLogDebug("created nsnmenu...")
    }
}
