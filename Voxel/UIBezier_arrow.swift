//
//  UIBezier_arrow.swift
//  Voxel
//
//  Created by Andy Qua on 05/11/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import UIKit

extension UIBezierPath {
    
    class func arrow(from start: CGPoint, to end: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) -> Self {
        
        let length = hypot(end.x - start.x, end.y - start.y)
        let tailLength = length - headLength
        
        let points: [CGPoint] = [
            CGPoint( x:0, y:tailWidth / 2),
            CGPoint( x:tailLength, y:tailWidth / 2),
            CGPoint( x:tailLength, y:headWidth / 2),
            CGPoint( x:length, y:0),
            CGPoint( x:tailLength, y:-headWidth / 2),
            CGPoint( x:tailLength, y:-tailWidth / 2),
            CGPoint( x:0, y:-tailWidth / 2)
        ]
        
        let cosine = (end.x - start.x) / length
        let sine = (end.y - start.y) / length
        let transform = CGAffineTransform(a: cosine, b: sine, c: -sine, d: cosine, tx: start.x, ty: start.y)
        
        let path = CGMutablePath()
        path.addLines(between: points, transform: transform )
        path.closeSubpath()
        return self.init(cgPath: path)
    }
    
}


