//
//  ModifierFlagsTests.swift
//  HotKey
//
//  Created by Sam Soffes on 7/21/17.
//  Copyright © 2017 Sam Soffes. All rights reserved.
//

import XCTest
import AppKit
import Carbon
import HotKey

final class ModiferFlagsTests: XCTestCase {
	func testCarbonToCocoaConversion() {
		var cocoa = NSEvent.ModifierFlags()
		cocoa.insert(.command)
		XCTAssertEqual(NSEvent.ModifierFlags(carbonFlags: UInt32(cmdKey)), cocoa)

		cocoa.insert(.control)
		cocoa.insert(.option)
		XCTAssertEqual(NSEvent.ModifierFlags(carbonFlags: UInt32(cmdKey|controlKey|optionKey)), cocoa)
	}

	func testCocoaToCarbonConversion() {
		var cocoa = NSEvent.ModifierFlags()
		cocoa.insert(.command)
		XCTAssertEqual(UInt32(cmdKey), cocoa.carbonFlags)

		cocoa.insert(.control)
		cocoa.insert(.option)
		XCTAssertEqual(UInt32(cmdKey|controlKey|optionKey), cocoa.carbonFlags)
	}
}
