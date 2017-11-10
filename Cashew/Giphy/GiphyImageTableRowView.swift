//
//  GiphyImageTableRowView.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/29/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import AVKit
import AVFoundation

@objc(SRGiphyPlayerView)
class GiphyPlayerView: AVPlayerView {
    
    override func hitTest(aPoint: NSPoint) -> NSView? {
        return nil
    }
    
    override var allowsVibrancy: Bool {
        return false
    }
    
    deinit {
        isPlaying = false
        self.player?.pause()
        NSNotificationCenter.defaultCenter().removeObserver(self)
        //DDLogDebug("deallocing giphy player \(self)")
    }
    
    private var isPlaying = false
    
    override var player: AVPlayer? {
        didSet {
            if isMouseOver() {
               play()
            } else {
                pause()
            }
        }
    }
    
    func play() {
        DispatchOnMainQueue {
            self.isPlaying = true
            self.player?.play()
        }
    }
    
    func pause() {
        DispatchOnMainQueue {
            self.isPlaying = false
            self.player?.pause()
        }
    }
    
    override func awakeFromNib() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GiphyPlayerView.playerDidReachEnd(_:)), name:AVPlayerItemDidPlayToEndTimeNotification, object: nil)
    }
    
    @objc
    private func playerDidReachEnd(notification: NSNotification) {
        DispatchOnMainQueue {

            if let item = notification.object as? AVPlayerItem where self.player?.currentItem == item && self.isPlaying {
                self.player?.seekToTime(kCMTimeZero)
                if self.isMouseOver() {
                    self.player?.play()
                }
            }
        }
    }
    
    
}

@objc(SRGiphyImageTableRowView)
class GiphyImageTableRowView: NSTableRowView {
    
    @IBOutlet weak var viewPlayer: GiphyPlayerView!
    
    private var currentTrackingArea: NSTrackingArea?
    
    var model: GiphyImage? {
        didSet {
            didSetModel()
        }
    }
    
    
    func didSetModel() {
        guard let model = model else {
            viewPlayer.pause()
            viewPlayer.player = nil
            return
        }
        
        viewPlayer.player = AVPlayer(URL: model.mp4URL) //[AVPlayer playerWithURL:model.mp4URL];
        viewPlayer.pause()
    }
    
    override func updateTrackingAreas() {
        if let currentTrackingArea = currentTrackingArea {
            self.removeTrackingArea(currentTrackingArea)
        }
        let trackingArea = NSTrackingArea(rect: bounds, options: [.MouseEnteredAndExited, .ActiveAlways] , owner: self, userInfo: nil)
        self.currentTrackingArea = trackingArea
        self.addTrackingArea(trackingArea);
    }
    
    
    override func mouseEntered(theEvent: NSEvent) {
        viewPlayer.play()
    }
    
    override func mouseExited(theEvent: NSEvent) {
        viewPlayer.pause()
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    class func instantiateFromNib() -> GiphyImageTableRowView? {
        var viewArray: NSArray?
        let className = "GiphyImageTableRowView"
        
        assert(NSThread.isMainThread())
        NSBundle.mainBundle().loadNibNamed(className, owner: nil, topLevelObjects: &viewArray)
        
        for view in viewArray as! [NSObject] {
            if object_getClass(view) == GiphyImageTableRowView.self {
                return view as? GiphyImageTableRowView
            }
        }
        
        return nil
    }
    
}
