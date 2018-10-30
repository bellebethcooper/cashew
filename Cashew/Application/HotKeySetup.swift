//
//  HotKeySetup.swift
//  Cashew
//
//  Created by Belle Beth Cooper on 31/10/18.
//  Copyright © 2018 SimpleRocket LLC. All rights reserved.
//

import Foundation
import HotKey


@objc class HotKeySetup: NSObject {
    
    var hotkey: HotKey? = nil
    
    @objc func setUp() {
        DDLogDebug("HotKeySetup setUp called")
        self.hotkey = HotKey(key: .a, modifiers: [.command, .option, .shift], keyDownHandler: {
            DDLogDebug("HotKeySetup setUp - u + cmd + alt pressed!")
        }, keyUpHandler: {
            DDLogDebug("HotKeySetup setUp - key up!")
        })
        
        DDLogDebug("HotKey: \(hotkey?.isPaused) \(hotkey?.keyCombo)")
    }
}
