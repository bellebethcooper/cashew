//
//  GeometryUtilities.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/3/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class GeometryUtilities: NSObject {

}

func CGRectIntegralMake(x x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
    return CGRectIntegral(CGRect(x: x, y: y, width: width, height: height))
}
