//
//  NSBezierPath+Extension.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 2/10/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Foundation


extension NSBezierPath {
    @objc
    func toCGPath () -> CGPath? {
        if self.elementCount == 0 {
            return nil
        }
        
        let path = CGMutablePath()
        var didClosePath = false
        
        for i in 0...self.elementCount-1 {
            var points = [NSPoint](repeating: NSZeroPoint, count: 3)
            
            switch self.element(at: i, associatedPoints: &points) {
            case .moveTo:path.move(to: CGPoint(x: points[0].x, y: points[0].y))
            case .lineTo:path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
            case .curveTo:path.addCurve(to: CGPoint(x: points[2].x, y: points[2].y), control1: CGPoint(x: points[0].x, y: points[0].y), control2: CGPoint(x: points[1].x, y: points[1].y))
            case .closePath:path.closeSubpath()
            didClosePath = true;
            }
        }
        
        if !didClosePath {
            path.closeSubpath()
        }
        
        return path.copy()
    }
}
