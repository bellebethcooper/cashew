//
//  NSString+Emoji.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/21/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation

extension NSString {
    @objc class func emoji(_ str: NSString) -> String {
        let string = str as String
        return string.emojiUnescapedString
    }
}

