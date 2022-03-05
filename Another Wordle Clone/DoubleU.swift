//
//  DoubleU.swift
//  Another Wordle Clone
//
//  Define a shape, per Lecture 6
//  We don't *really* want this in the final app, but it seems worthwhile
//  to go through the process of defining and adding a shape.
//  In this case, we're going to make a "W" shape that will do something when
//  The user inputs a letter
//
//  Created by Ben Torvaney on 05/03/2022.
//

import SwiftUI


struct DoubleU: Shape {
    var angle: Angle
    var scale: CGFloat
    
    // How high should the middle upwards bit of the W be in the middle
    let middleRatio: CGFloat = 2/3
    
    func path(in rect: CGRect) -> Path {
        let start = CGPoint(x: rect.midX, y: rect.midY - rect.height*(middleRatio-0.5))
        let xOffset = rect.height * tan(angle.radians)
        
        // NOTE: Maybe cleaner to add an Extension to Path that will let us set a bearing and
        // a length?
        let rhsPivot = shiftPoint(start, xOffset: xOffset, yOffset: rect.height/middleRatio, scale: scale/2)
        let rhsEnd = shiftPoint(rhsPivot, xOffset: xOffset, yOffset: rect.height, scale: -scale)
        
        let lhsPivot = shiftPoint(start, xOffset: -xOffset, yOffset: rect.height/middleRatio, scale: scale/2)
        let lhsEnd = shiftPoint(lhsPivot, xOffset: -xOffset, yOffset: rect.height, scale: -scale)
        
        var p = Path()
        p.move(to: start)
        p.addLine(to: rhsPivot)
        p.move(to: rhsPivot)
        p.addLine(to: rhsEnd)
        p.move(to: start)
        p.addLine(to: lhsPivot)
        p.move(to: lhsPivot)
        p.addLine(to: lhsEnd)
        
        return p
    }
    
    private func shiftPoint(_ point: CGPoint, xOffset: CGFloat, yOffset: CGFloat, scale: CGFloat) -> CGPoint {
        CGPoint(
            x: point.x + abs(scale)*xOffset,
            y: point.y + scale*yOffset
        )
    }
}
