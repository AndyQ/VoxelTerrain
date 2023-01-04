//
//  TerrainGenerationViewController.swift
//  Voxel
//
//  Created by Andy Qua on 27/12/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import UIKit
import SceneKit
import GameKit
import Engine

// Just some stuff I'm playing with at the moment - not currently used and probably will be mostly removed


func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
    return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
}

func UIColorFromHex (hex:String) -> UIColor {
    let cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    var rgbValue: UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)

    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

let NOISE_SAMPLE_COUNT : Int = 1024
let NOISE_SAMPLE_SIZE : Double = 800.0

class TerrainGenerationViewController: UIViewController {
    
    var showVoxelBtn : UIButton!
    var hmImageView : UIImageView!
    var lmImageView : UIImageView!
    var txImageView : UIImageView!
    
    var heightMap : Bitmap!
    var lightMap : Bitmap!
    var imageMap : Bitmap!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupControls()
    }
    
    func generate() {
        
//        let terrg = TerrainGenerator()
//        var (heightMap, imageMap) = terrg.generateTerrain( 256 )
        
//        (heightMap, imageMap) = generateNoiseMap()
        
//        let t = Terrain(width: 512, height: 512)
//        heightMap = t.generate()
//        imageMap = heightMap
        
        heightMap = UIImage(named:"render")!.getBitmap()
        imageMap = heightMap

        
        let hmI = UIImage(bitmap: heightMap)!
        let imI = UIImage(bitmap: imageMap)!
        heightMap = hmI.resize(to: CGSize(width: 1024,height: 1024), with:.uikit)!.getBitmap()
        imageMap = imI.resize(to: CGSize(width: 1024,height: 1024), with:.uikit)!.getBitmap()

        
        let tg = TextureGenerator()

//        let hm = UIImage(named:"D1")!
//        let tm = UIImage(named:"C1")!
        hmImageView.image = UIImage(bitmap: heightMap)
        txImageView.image = UIImage(bitmap: imageMap)

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            let lm = tg.generateLightmap(self.heightMap)
            let lmImage = UIImage(bitmap:lm)
            self.lmImageView.image = lmImage

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                let merge = tg.mergeLightmapWithTexture(self.imageMap, lm)
                let mImage = UIImage(bitmap:merge)
                self.txImageView.image = mImage
            }
        }


/*
        let app = PerlinNoiseGenerator(sizeX:256, sizeY:256)
        app.GenerateNoise()
        let image = UIImage(bitmap:app.bitmap)
        hmImageView.image = image
        
//        let lm = Lightmap()
//        lm.generateLightmap(app.bitmap)
//        let lmImage = UIImage(bitmap:lm.lmap)
//        lmImageView.image = lmImage

        
        let tg = TextureGenerator()
        let lm = tg.generateLightmap(app.bitmap)
        let lmImage = UIImage(bitmap:lm)
        lmImageView.image = lmImage

        let bm = tg.generateTexture(app.bitmap)
        let texImage = UIImage(bitmap:bm)
        txImageView.image = texImage
        
        Task {
            let merge = tg.mergeLightmapWithTexture(bm, lm)
            let mImage = UIImage(bitmap:merge)
            txImageView.image = mImage
            print( "Done" )

        }
*/
    }
    
    func setupControls() {
        
        showVoxelBtn = UIButton(type: .system, primaryAction: UIAction(title: "Button Title", handler: { _ in
            self.performSegue(withIdentifier: "showTerrain", sender: self)
        }))
        
        hmImageView = UIImageView(frame: .zero)
        lmImageView = UIImageView(frame: .zero)
        txImageView = UIImageView(frame: .zero)

        showVoxelBtn.translatesAutoresizingMaskIntoConstraints = false
        hmImageView.translatesAutoresizingMaskIntoConstraints = false
        lmImageView.translatesAutoresizingMaskIntoConstraints = false
        txImageView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(showVoxelBtn)
        self.view.addSubview(hmImageView)
        self.view.addSubview(lmImageView)
        self.view.addSubview(txImageView)

        showVoxelBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        showVoxelBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true

        hmImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        hmImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        hmImageView.heightAnchor.constraint(equalToConstant: 256).isActive = true
        hmImageView.widthAnchor.constraint(equalToConstant: 256).isActive = true

        lmImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        lmImageView.leadingAnchor.constraint(equalTo: hmImageView.trailingAnchor).isActive = true
        lmImageView.heightAnchor.constraint(equalToConstant: 256).isActive = true
        lmImageView.widthAnchor.constraint(equalToConstant: 256).isActive = true

        txImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        txImageView.leadingAnchor.constraint(equalTo: lmImageView.trailingAnchor).isActive = true
        txImageView.heightAnchor.constraint(equalToConstant: 256).isActive = true
        txImageView.widthAnchor.constraint(equalToConstant: 256).isActive = true

        
        
    }
    
    
    func generateNoiseMap() -> (Bitmap, Bitmap)
    {
        let noiseSource : GKNoiseSource = GKPerlinNoiseSource(frequency: Double(randomBetweenNumbers(firstNum: 0.005, secondNum: 0.01)), octaveCount: Int(randomBetweenNumbers(firstNum: 5, secondNum: 10)), persistence: Double(randomBetweenNumbers(firstNum: 0.2, secondNum: 0.5)), lacunarity: Double(randomBetweenNumbers(firstNum: 0.5, secondNum: 2.0)), seed: Int32(randomBetweenNumbers(firstNum: 0, secondNum: 1024)))
        
        
        let hmNoise : GKNoise = GKNoise(noiseSource, gradientColors: [-1.0 : UIColorFromHex(hex: "000000"), 1.0 : UIColor.white])
        let txNoise : GKNoise = GKNoise(noiseSource, gradientColors: [-1.0 : UIColorFromHex(hex: "2F971C"), -0.5 : UIColorFromHex(hex: "5CA532") ,-0.0 : UIColorFromHex(hex: "DFED8B"), 0.6 : UIColorFromHex(hex: "A9A172"), 0.8 : UIColorFromHex(hex: "A9A172"), 1.0 : UIColor.white])
        
        let hmNoiseMap = GKNoiseMap(hmNoise, size: vector2(NOISE_SAMPLE_SIZE,NOISE_SAMPLE_SIZE), origin: vector2(0, 0), sampleCount: vector2(Int32(NOISE_SAMPLE_COUNT), Int32(NOISE_SAMPLE_COUNT)), seamless: true)
        let hmNoiseTexture : SKTexture = SKTexture(noiseMap: hmNoiseMap)
        let hm = UIImage(cgImage: hmNoiseTexture.cgImage()).getBitmap()

        let txNoiseMap = GKNoiseMap(txNoise, size: vector2(NOISE_SAMPLE_SIZE,NOISE_SAMPLE_SIZE), origin: vector2(0, 0), sampleCount: vector2(Int32(NOISE_SAMPLE_COUNT), Int32(NOISE_SAMPLE_COUNT)), seamless: true)
        let txNoiseTexture : SKTexture = SKTexture(noiseMap: txNoiseMap)
        let tx = UIImage(cgImage: txNoiseTexture.cgImage()).getBitmap()
        return (hm, tx)
    }

    

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let vc = segue.destination as? VoxelViewController {
            vc.depthImage = self.hmImageView.image
            vc.mapImage = self.txImageView.image
        }
    }

}



class Terrain {
    //reference for local functions
    var width : Int = 512
    var height : Int = 512
    
    var rough = 255;//255;
    var passSize = 32;
    //contains all point data .. will be filled into a 2d array
    var points = [[Point]]();
    
    var x : Int = 0
    var y : Int = 0
    var z : Int = 0

    init(width : Int,height : Int) {
        self.width = width-1
        self.height = height-1
        
    }
    
    class Point {
        var x : Int
        var y : Int
        var z : Int
        
        init(x: Int, y:Int ) {
            self.x = x;
            self.y = y;
            
            self.z = 0;
            
            if Float.random(in: 0..<1) > 0.3 {
                self.z = Int(abs(sin(Double(x*y))*255))
            }
        }
    }
    

    //get the value of a point at world-wrapped x,y
    func getPoint(x : Int, y : Int) -> Int {
        self.x = (x+self.width) % self.width
        self.y = (y+self.height) % self.height
        
        return self.points[self.x][self.y].z;
    };
    
    //set the value of a point at world-wrapped x,y
    func setPoint(x : Int, y : Int, value: Int) {
        self.x = (x+self.width)%self.width
        self.y = (y+self.height)%self.height
        
        self.points[self.x][self.y].z = value;
    };
    
    //get values of points from 4 corners of a square around point based on size, assign the point average of their values + another value
    func pointFromSquare(x : Int, y : Int, size : Int, value : Int) {
        let hs = size / 2
            // a   b
            //   x
            // c   d
        let a = self.getPoint(x: x - hs, y: y - hs)
        let b = self.getPoint(x: x + hs, y: y - hs)
        let c = self.getPoint(x: x - hs, y: y + hs)
        let d = self.getPoint(x: x + hs, y: y + hs)
        
        self.setPoint(x: x, y: y, value: (a + b + c + d) / 4 + value);
    };
    
    //get values of points from 4 corners of a diamond around point based on size, assignt he point average of their values + another value
    func pointFromDiamond(x : Int, y : Int, size : Int, value : Int) {
        let hs = size / 2
            //   c
            //a  x  b
            //   d
        let a = self.getPoint(x: x - hs, y: y)
        let b = self.getPoint(x: x + hs, y: y)
        let c = self.getPoint(x: x, y: y - hs)
        let d = self.getPoint(x: x, y: y + hs)
        
        self.setPoint(x: x, y: y, value: (a + b + c + d) / 4 + value);
    };
    
    //do a full pass with both diamond and squares
    func diamondSquare(stepSize : Int, scale : Int) {
        let halfStep = stepSize / 2;
        
        for y in stride( from: halfStep, to: self.height + halfStep, by: stepSize) {
            for x in stride( from: halfStep, to: self.width + halfStep, by: stepSize) {
                self.pointFromSquare(x: x, y: y, size: stepSize, value: Int(Double.random(in:0..<1) * Double(scale)));
            }
        }
        
        for y in stride( from: 0, to: self.height, by: stepSize) {
            for x in stride( from: 0, to: self.width, by: stepSize) {
                self.pointFromDiamond(x: x + halfStep, y: y, size: stepSize, value: Int(Double.random(in:0..<1) * Double(scale)));
                self.pointFromDiamond(x: x, y: y + halfStep, size: stepSize, value: Int(Double.random(in:0..<1) * Double(scale)));
            }
        }
    };
    
    //create/refresh the 2d array structure and seed random z values
    func seed() {
        let newWidth = self.width;
        let newHeight = self.height;
        
        for x in 0 ..< newWidth {
            for y in 0 ..< newHeight {
                if(x <= self.points.count) {
                    self.points.append([]);
                }
                
                if( y <= self.points[x].count) {
                    self.points[x].append( Point(x: x,y: y));
                }
                else {
                    self.setPoint(x: x,y: y, value: Int(Double.random(in:0...1)*255))
                }
            }
        }
    };
    
    //invoke immediately so we have placeholder data
    
    func smoothTerrain() {
        var sampleSize = self.passSize,
            scaleFactor = 1;
        
        while(sampleSize > 1) {
            self.diamondSquare(stepSize: sampleSize,scale: scaleFactor);
            
            sampleSize /= 2;
            scaleFactor /= 2;
        }
    };
    
    func generate() -> Bitmap {
        self.seed();
        
        //invoke immediately so we have wrapped smooth terrain
        self.smoothTerrain();
        
        self.passSize = 128;
        self.smoothTerrain();

        var bm = Bitmap(width: self.width, height: self.height, color: .black)
        
        for x in 0..<self.points.count {
            let col = self.points[x];
            
            for y in 0..<col.count {
                let lum = UInt8(col[y].z)
                
                bm[x,y] = Color(r: lum, g: lum, b: lum, a: lum)
            }
        }
                
        return bm;
    };
}

