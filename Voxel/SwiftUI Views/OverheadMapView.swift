//
//  MapOverheadView.swift
//  Voxel
//
//  Created by Andy Qua on 15/01/2023.
//  Copyright © 2023 Andy Qua. All rights reserved.
//

import SwiftUI
import Engine

struct OverheadMapView : View {
    @Binding var mapImage : UIImage
    @Binding var playerPos : CGPoint
    @Binding var angle : Double
    
    var body : some View {
        ZStack {
            Image( uiImage: mapImage )
                .resizable()
            
            TimelineView(.periodic(from: .now, by: 0.1)) { timeline in
                Canvas { context, size in
                    
                    let cx = playerPos.x //size.width/2
                    let cy = playerPos.y //size.height/2
                    
                    let deg = Int(rad2deg(angle))
                    let nx = cx + 10 * cos(deg2rad(deg))
                    let ny = cy + 10 * sin(deg2rad(deg))
                    
                    let circle = Circle().path(in: CGRect(x: cx-2, y: cy-2, width: 4, height: 4))
                    context.fill( circle, with:.color(.yellow) )
                    context.stroke( circle, with:.color(.red) )

                    
                    let line = Path { path in
                        let points: [CGPoint] = [
                            .init(x: cx, y: cy),
                            .init(x: nx, y: ny),
                        ]
                        path.move(to: CGPoint(x:cx, y: cy))
                        path.addLines(points)
                    }
                    context.stroke( line, with: .color(.red), lineWidth: 2)
                    context.stroke( line, with: .color(.yellow), lineWidth: 1)
                }
                
            }
        }
        .frame(width:128, height:128)
        
    }
}

//struct OverheadMapView_Previews: PreviewProvider {
//    static var previews: some View {
//        OverheadMapView()
//    }
//}
