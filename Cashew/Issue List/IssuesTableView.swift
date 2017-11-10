//
//  IssuesTableView.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/8/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRIssuesTableView)
class IssuesTableView: BaseTableView {
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
    }
    
//    override func highlightSelectionInClipRect(clipRect: NSRect) {
//        let evenColor = NSColor.redColor()
//        let oddColor = NSColor.greenColor()
//        
//        let rowHeight = self.rowHeight + self.intercellSpacing.height;
//        let visibleRect = self.visibleRect;
//        var highlightRect = NSMakeRect(NSMinX(visibleRect), (NSMinY(clipRect)/rowHeight)*rowHeight, NSWidth(visibleRect), rowHeight)
//        
//        
//        while (NSMinY(highlightRect) < NSMaxY(clipRect)) {
//            let clippedHighlightRect = NSIntersectionRect(highlightRect, clipRect);
//            let row =  floor((NSMinY(highlightRect)+rowHeight/2.0)/rowHeight);
//            let rowColor = (0 == row % 2) ? evenColor : oddColor;
//            rowColor.set()
//            NSRectFill(clippedHighlightRect);
//            highlightRect.origin.y += rowHeight;
//        }
//        
//        super.highlightSelectionInClipRect(clipRect)
//    }
  
//    override func drawRow(row: Int, clipRect: NSRect) {
//      //  - (void) drawRow:(int) rowIndex clipRect:(NSRect) clipRect
//       // {
//        let evenColor = NSColor.redColor()
//        let oddColor = NSColor.greenColor()
//            if (row % 2 == 0) && (selectedRow != row) {
//                let evenColor = NSColor.redColor()
//                let rect = rectOfRow(row)
//                evenColor.set()
//                
//                NSRectFill(rect);
//            }
//            super.drawRow(row, clipRect: clipRect)
//       // }
//
//    }
}
//    - (void) drawRow:(int) rowIndex clipRect:(NSRect) clipRect
//    {
//    if ((rowIndex % 2 == 0) && ([self selectedRow] != rowIndex))
//    {
//    NSColor* bgColor =[NSColor colorWithCalibratedRed:0.97 green: 0.97
//    blue: 0.97 alpha: 0.97];
//    NSRect rect= [self rectOfRow: rowIndex];
//    [bgColor set];
//    
//    NSRectFill(rect);
//    }
//    [super  drawRow: rowIndex clipRect: clipRect];
//    }
//    


