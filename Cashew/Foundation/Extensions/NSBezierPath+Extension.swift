//
//  NSBezierPath+Extension.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 2/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


extension NSBezierPath {
    func toCGPath () -> CGPath? {
        if self.elementCount == 0 {
            return nil
        }
        
        let path = CGMutablePath()
        var didClosePath = false
        
        for i in 0...self.elementCount-1 {
            var points = [NSPoint](repeating: NSZeroPoint, count: 3)
            
            switch self.element(at: i, associatedPoints: &points) {
            case .moveToBezierPathElement:path.move(to: CGPoint(x: points[0].x, y: points[0].y))
            case .lineToBezierPathElement:path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
            case .curveToBezierPathElement:path.addCurve(to: CGPoint(x: points[2].x, y: points[2].y), control1: CGPoint(x: points[0].x, y: points[0].y), control2: CGPoint(x: points[1].x, y: points[1].y))
            case .closePathBezierPathElement:path.closeSubpath()
            didClosePath = true;
            }
        }
        
        if !didClosePath {
            path.closeSubpath()
        }
        
        return path.copy()
    }
}
