//
//  HeightMapGenMenu.swift
//  Voxel
//
//  Created by Andy Qua on 16/01/2023.
//  Copyright © 2023 Andy Qua. All rights reserved.
//

import SwiftUI

struct HeightMapGeneratorMenu: View {
    @Binding var selectedTerrainType : TerrainType
    
    var body: some View {
        HStack {
            Menu("Heightmap type:") {
                Button("Midpoint displacement", action: {
                    selectedTerrainType = .midpointDisplacement
                })
                Button("Perlin noise #1", action: {
                    selectedTerrainType = .perlinNoise1
                })
                Button("Perlin noise #2", action: {
                    selectedTerrainType = .perlinNoise2
                })
                
                Button("Triangle Division", action: {
                    selectedTerrainType = .triangleDivision
                })
                Button("Diamond Square", action: {
                    selectedTerrainType = .diamondSquare
                })
                Button("Fault Formation", action: {
                    selectedTerrainType = .faultFormation
                })
                Button("Particle Deposition", action: {
                    selectedTerrainType = .particleDeposition
                })
                Button("Veronoi Diagram", action: {
                    selectedTerrainType = .veronoiDiagram
                })
            }
            Text( selectedTerrainType.rawValue )
            Spacer()
        }

    }
}


struct HeightMapGenMenu_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(TerrainType.midpointDisplacement) { HeightMapGeneratorMenu(selectedTerrainType: $0) }
    }
}
