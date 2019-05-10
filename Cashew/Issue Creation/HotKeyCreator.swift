//
//  HotKeyCreator.swift
//  Cashew
//
//  Created by Belle Beth Cooper on 2/12/18.
//  Copyright © 2018 SimpleRocket LLC. All rights reserved.
//

import Foundation
import HotKey
import os.log

@objc class HotKeyCreator: NSObject {
    
    private var hotKey: HotKey? {
        didSet {
            hotKey?.keyDownHandler = {
                os_log("HotKeyCreator key down", log: .default, type: .debug)
                if let delegate = NSApplication.shared.delegate as? AppDelegate {
                    os_log("HotKeyCreator got delegate", log: .default, type: .debug)
                    delegate.didUseNewIssueHotKey()
                }
            }
        }
    }
    
    public func unregister() {
        hotKey = nil
    }
    
    @objc public func register() {
        hotKey = HotKey(keyCombo: KeyCombo(key: .r, modifiers: [.command, .option]))
    }
}

