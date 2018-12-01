//
//  HotKeyCreator.swift
//  Cashew
//
//  Created by Belle Beth Cooper on 2/12/18.
//  Copyright © 2018 SimpleRocket LLC. All rights reserved.
//

import Foundation
import HotKey


@objc class HotKeyCreator: NSObject {
    
    private var hotKey: HotKey? {
        didSet {
            hotKey?.keyDownHandler = {
                DDLogDebug("HotKeyCreator key down")
                if let delegate = NSApplication.shared.delegate as? AppDelegate {
                    DDLogDebug("HotKeyCreator got delegate")
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

