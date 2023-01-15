//
//  TerrainGenerationViewController.swift
//  Voxel
//
//  Created by Andy Qua on 27/12/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import UIKit
import Engine
import TerrainGeneration


class TerrainGenerationViewController: UIViewController {
    
    var generateBtn : UIButton!
    var erodeBtn : UIButton!
    var texImageBtn : UIButton!
    var showVoxelBtn : UIButton!

    var hmImageView : UIImageView!
    var lmImageView : UIImageView!
    var txImageView : UIImageView!
    
    
    var terrain : Terrain!
    var textureGen = TextureGenerator()
    
    var talus = 4.0/1024    
    var erosion_iterations = 100

    override func viewDidLoad() {
        terrain = Terrain( mapSize: 512)
        
        super.viewDidLoad()
        
        createViews()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let vc = segue.destination as? VoxelViewController {
            vc.depthImage = self.hmImageView.image
            vc.mapImage = self.txImageView.image
        }
    }

    func go() {
        
        // Do any additional setup after loading the view.
        
//        terrain.makePerlinNoiseMap( )
//        terrain.makeTriangleDivision(roughness: 0.9, seed: 2, firValue: 0)
//        terrain.makeDiamondSquare(roughness: 0.9, seed: 2, firValue: 0.9) // Tiles
//        terrain.makeFaultFormation(iterations: 128, filterIterations: 8, firValue: 0.8)
        terrain.makeMidpointDisplacement(roughness: 0.5, seed: 2, firValue: 0)//0.65)
//        terrain.makeParticleDeposition(nMountain: 20, moveDrop: 10, particle: 5000000, caldera: 20, firValue: 0.65)
//        terrain.makePerlinNoise(persistence: 1.0, frequency: 0.02, amplitude: 0.5, octaves: 5, seed: randomInt(in: 0 ... 10000), firValue: 0)
//        terrain.makeVoronoiDiagram(points: 20, seed: randomInt(in: 0 ... 10000), firValue: 0)

        hmImageView.image = terrain.image()
    }
    
    func erode() async {
        await terrain.makeWaterErosion( numErosionIterations: 500000)
        
//        terrain.makeThermalErosion(talus: talus, iterations: erosion_iterations)
//        terrain.makeHydraulicErosion(water: 0.1, sediment: 0.1, evaporation: 0.5, capacity: 0.6, iterations: erosion_iterations);

        lmImageView.image = terrain.image()
    }
    
    func genTexture() {
        
        let bm = terrain.bitmap()
        let tg = TextureGenerator()
        let tm = tg.generateTexture(bm)
        hmImageView.image = UIImage(bitmap:bm)
        txImageView.image = UIImage(bitmap:tm)
    }
    
    func createWrappedTexture() {
        let wt = terrain.createWrappedImage()
        let tg = TextureGenerator()
        let tm = tg.generateTexture(wt)
        hmImageView.image = UIImage(bitmap:wt)
        txImageView.image = UIImage(bitmap:tm)
    }

    
    func createViews() {
        generateBtn = UIButton(type: .system, primaryAction: UIAction(title: "Generate", handler: { _ in
            self.go()
        }))
        
        erodeBtn = UIButton(type: .system, primaryAction: UIAction(title: "Erode", handler: { _ in
            Task {
                await self.erode()
            }
        }))
        
        texImageBtn = UIButton(type: .system, primaryAction: UIAction(title: "Gen Texture", handler: { _ in
            self.genTexture()
        }))
        
        showVoxelBtn = UIButton(type: .system, primaryAction: UIAction(title: "Show Voxels", handler: { _ in
            self.performSegue(withIdentifier: "showTerrain", sender: self)
        }))

        
        hmImageView = UIImageView(frame: .zero)
        lmImageView = UIImageView(frame: .zero)
        txImageView = UIImageView(frame: .zero)
        
        generateBtn.translatesAutoresizingMaskIntoConstraints = false
        erodeBtn.translatesAutoresizingMaskIntoConstraints = false
        texImageBtn.translatesAutoresizingMaskIntoConstraints = false
        showVoxelBtn.translatesAutoresizingMaskIntoConstraints = false
        hmImageView.translatesAutoresizingMaskIntoConstraints = false
        lmImageView.translatesAutoresizingMaskIntoConstraints = false
        txImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(generateBtn)
        self.view.addSubview(erodeBtn)
        self.view.addSubview(texImageBtn)
        self.view.addSubview(showVoxelBtn)
        self.view.addSubview(hmImageView)
        self.view.addSubview(lmImageView)
        self.view.addSubview(txImageView)
        
        generateBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        generateBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        
        erodeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        erodeBtn.leadingAnchor.constraint(equalTo: generateBtn.trailingAnchor, constant: 20).isActive = true
        
        texImageBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        texImageBtn.leadingAnchor.constraint(equalTo: erodeBtn.trailingAnchor, constant: 20).isActive = true
        
        showVoxelBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        showVoxelBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true

        hmImageView.topAnchor.constraint(equalTo: generateBtn.bottomAnchor, constant: 20).isActive = true
        hmImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        hmImageView.heightAnchor.constraint(equalToConstant: 256).isActive = true
        hmImageView.widthAnchor.constraint(equalToConstant: 256).isActive = true
        
        lmImageView.topAnchor.constraint(equalTo: generateBtn.bottomAnchor, constant: 20).isActive = true
        lmImageView.leadingAnchor.constraint(equalTo: hmImageView.trailingAnchor).isActive = true
        lmImageView.heightAnchor.constraint(equalToConstant: 256).isActive = true
        lmImageView.widthAnchor.constraint(equalToConstant: 256).isActive = true
        
        txImageView.topAnchor.constraint(equalTo: generateBtn.bottomAnchor, constant: 20).isActive = true
        txImageView.leadingAnchor.constraint(equalTo: lmImageView.trailingAnchor).isActive = true
        txImageView.heightAnchor.constraint(equalToConstant: 256).isActive = true
        txImageView.widthAnchor.constraint(equalToConstant: 256).isActive = true
        
    }
}
