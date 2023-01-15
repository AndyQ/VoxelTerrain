//
//  TerrainGenerationView.swift
//  Voxel
//
//  Created by Andy Qua on 15/01/2023.
//  Copyright © 2023 Andy Qua. All rights reserved.
//

import SwiftUI
import TerrainGeneration

struct TerrainGenerationView : View {
    var terrain = Terrain(mapSize: 512)
    var textureGen = TextureGenerator()
    
    @State var heightMapImage : UIImage = UIImage()
    @State var erodeMapImage : UIImage = UIImage()
    @State var textureImage : UIImage = UIImage()
    
    @State var eroding = false
    @State var hasDepth = false
    @State var hasEroded = false
    @State var hasTexture = false
    
    @EnvironmentObject var appModel : AppModel
    var body : some View {
        
        VStack {
            HStack {
                Button("Generate") {
                    terrain.makeMidpointDisplacement(roughness: 0.5, seed: Int.random(in: 0...Int.max), firValue: 0)//0.65)
                    heightMapImage = terrain.image()
                    erodeMapImage = UIImage()
                    textureImage = UIImage()
                    hasDepth = true
                    hasEroded = false
                    hasTexture = false

                }
                .padding()
                .disabled(eroding)
                
                AsyncButton(action: {
                    eroding = true
                    textureImage = UIImage()
                    hasTexture = false
                    await terrain.makeWaterErosion( numErosionIterations: 500000)
                    erodeMapImage = terrain.image()
                    hasEroded = true

                    eroding = false
                }, label: {
                    Text( "Erode")
                })
                .padding()
                .disabled(!hasDepth)
                
                Button("Texture") {
                    let bm = terrain.bitmap()
                    let tg = TextureGenerator()
                    let tm = tg.generateTexture(bm)

                    heightMapImage = UIImage(bitmap:bm)!
                    textureImage = UIImage(bitmap:tm)!
                    hasTexture = true

                }
                .disabled(!hasDepth || eroding)
                .padding()
                Spacer()
                
                Button("Show Voxels") {
                    appModel.depthImage = hasEroded ? erodeMapImage : heightMapImage
                    appModel.mapImage = textureImage
                    appModel.path.append( "Voxel" )
                }
                .disabled(eroding || !hasDepth || !hasTexture )
            }
            HStack {
                Image(uiImage:heightMapImage)
                    .resizable()
                    .frame(maxWidth:256, maxHeight:256)
                Image(uiImage:erodeMapImage)
                    .resizable()
                    .frame(maxWidth:256, maxHeight:256)
                Image(uiImage:textureImage)
                    .resizable()
                    .frame(maxWidth:256, maxHeight:256)
            }
        }
        .navigationTitle("Terrain Generation")
    }
}


struct TerrainGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        TerrainGenerationView()
    }
}
