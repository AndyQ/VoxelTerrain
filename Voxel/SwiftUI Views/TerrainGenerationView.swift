//
//  TerrainGenerationView.swift
//  Voxel
//
//  Created by Andy Qua on 15/01/2023.
//  Copyright © 2023 Andy Qua. All rights reserved.
//

import SwiftUI
import TerrainGeneration

enum TerrainType : String {
    case midpointDisplacement = "Midpoint displacement"
    case perlinNoise1 = "Perlin noise #1"
    case perlinNoise2 = "Perlin noise #2"
    case triangleDivision = "Triangle division"
    case diamondSquare = "Diamond square"
    case faultFormation = "Fault formation"
    case particleDeposition = "Particle deposition"
    case veronoiDiagram = "Veronoi diagram"
}

enum ErosionType : String {
    case water = "Water"
    case thermal = "Thermal"
    case hydraulic = "Hydraulic"
}

struct TerrainGenerationView : View {
    @State var terrain = Terrain(mapSize: 512)
    var textureGen = TextureGenerator()
    
    @State var heightMapImage : UIImage = UIImage()
    @State var erodeMapImage : UIImage = UIImage()
    @State var textureImage : UIImage = UIImage()
    
    @State var eroding = false
    @State var hasDepth = false
    @State var hasEroded = false
    @State var hasTexture = false
    
    @State var selectedTerrainType : TerrainType = .midpointDisplacement
    @State var selectedErosionType : ErosionType = .water

    @EnvironmentObject var appModel : AppModel
    var body : some View {
        
        VStack {
            HStack {
                HeightMapGeneratorMenu(selectedTerrainType: $selectedTerrainType)
                    .disabled(eroding)
                ErosionMenu(selectedErosionType: $selectedErosionType)
                    .disabled(eroding)
            }
            .padding([.top, .leading])

            HStack(spacing:20) {
                AsyncButton(action: {
                    await generateTerrain( type: selectedTerrainType )
                }, label: {
                    Text( "Generate")
                })
                .disabled(eroding)

                
                AsyncButton(action: {
                    await erodeTerrain( type: selectedErosionType )
                }, label: {
                    Text( "Erode")
                })
                .disabled(!hasDepth)
                
                AsyncButton(action: {
                    let bm =  (hasEroded ? erodeMapImage : heightMapImage).getBitmap()
                    let tg = TextureGenerator()
                    let tm = tg.generateTexture(bm)

                    textureImage = UIImage(bitmap:tm)!
                    hasTexture = true

                }, label: {
                    Text( "Generate Texture")
                })
                .disabled(!hasDepth || eroding)
                Spacer()
                
                Button("Show Voxels") {
                    appModel.depthImage = hasEroded ? erodeMapImage : heightMapImage
                    appModel.mapImage = textureImage
                    appModel.path.append( "Voxel" )
                }
                .disabled(eroding || !hasDepth || !hasTexture )
            }
            .padding(.leading)
            .padding(.top, 5)

            
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
            .padding([.leading])
        }
        .navigationTitle("Terrain Generation")
    }
    
    func generateTerrain( type: TerrainType ) async {
        let seed = randomInt(in: 0 ... 10000)
        switch type {
            case .midpointDisplacement:
                terrain.makeMidpointDisplacement(roughness: 0.5, seed: seed, firValue: 0)//0.65)
            case .perlinNoise1:
                terrain.makePerlinNoiseMap( )
            case .perlinNoise2:
                terrain.makePerlinNoise(persistence: 1.0, frequency: 0.02, amplitude: 0.5, octaves: 5, seed: seed, firValue: 0)
            case .triangleDivision:
                terrain.makeTriangleDivision(roughness: 0.9, seed: seed, firValue: 0)
            case .diamondSquare:
                terrain.makeDiamondSquare(roughness: 0.9, seed: seed, firValue: 0.9) // Tiles
            case .faultFormation:
                terrain.makeFaultFormation(iterations: 128, filterIterations: 8, firValue: 0.8)
            case .particleDeposition:
                terrain.makeParticleDeposition(nMountain: 20, moveDrop: 10, particle: 5000000, caldera: 20, firValue: 0.65)
            case .veronoiDiagram:
                terrain.makeVoronoiDiagram(points: 20, seed: seed, firValue: 0)
        }
        
        heightMapImage = terrain.image()
        erodeMapImage = UIImage()
        textureImage = UIImage()
        hasDepth = true
        hasEroded = false
        hasTexture = false
    }

    func erodeTerrain( type: ErosionType ) async {
        
        eroding = true
        textureImage = UIImage()
        hasTexture = false
        
        let talus = 4.0/1024
        let erosion_iterations = 100

        switch type {
            case .water:
                await terrain.makeWaterErosion( numErosionIterations: 500000)
            case .thermal:
                await terrain.makeThermalErosion(talus: talus, iterations: erosion_iterations)
            case .hydraulic:
                await terrain.makeHydraulicErosion(water: 0.1, sediment: 0.1, evaporation: 0.5, capacity: 0.6, iterations: erosion_iterations);
        }
        erodeMapImage = terrain.image()
        hasEroded = true
        
        eroding = false
    }
    
}


struct TerrainGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        TerrainGenerationView()
    }
}
