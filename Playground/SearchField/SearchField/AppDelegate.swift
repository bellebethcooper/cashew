//
//  AppDelegate.swift
//  SearchField
//
//  Created by Hicham Bouabdallah on 4/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa


@objc
class HishWindow: NSWindow {

}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: HishWindow!


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        print("window \(window)")
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}



