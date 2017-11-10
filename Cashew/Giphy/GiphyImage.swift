//
//  GiphyImage.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/29/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRGiphyImage)
class GiphyImage: NSObject {
    
    let caption: String?
    let url: NSURL
    let mp4URL: NSURL
    let width: CGFloat
    let height: CGFloat
    
    init(url: NSURL,  mp4URL: NSURL, width: CGFloat, height: CGFloat, caption: String?) {
        self.url = url
        self.width = width
        self.height = height
        self.mp4URL = mp4URL
        self.caption = caption
        super.init()
    }

}
