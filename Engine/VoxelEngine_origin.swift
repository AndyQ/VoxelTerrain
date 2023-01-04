//
//  VoxelEngine.swift
//  Voxel
//
//  Created by Andy Qua on 05/11/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import GameplayKit

/*
public struct Camera {
    var x : CGFloat = 512
    var y : CGFloat = 800
    var height : CGFloat = 78
    var angle : CGFloat = 0
    public var horizon : CGFloat = 100
    var distance : CGFloat = 3200//4200
}

struct Map {
    var width: Int = 1024
    var height: Int = 1024
    var altitude: [Int] //= [UInt8](repeating:0,  count:1024*1024) // 1024 * 1024 byte array with height information
    var color: [Color] //= [Color](repeating:Color.black, count:1024*1024)
    
    init( w: Int = 1024, h:Int = 1024 ) {
        width = w
        height = h
        altitude = [Int](repeating:0,  count:width*height) // 1024 * 1024 byte array with height information
        color = [Color](repeating:Color.black, count:width*height)
    }
    func getMapOffset( x: Int, y: Int ) -> Int {
        let map_offset = (y & (width - 1)) * width + (x & (height - 1));
        
        return map_offset
    }
    
    func getMapOffset( x: Double, y: Double ) -> Int {
        let map_offset = (Int(y) & (width - 1)) * width + (Int(x) & (height - 1));
        
        return map_offset
    }
    
}
*/

// This is based on @s-macke's rendering engine - Works nicely but couldn't get tilt working properly yet
// https://github.com/s-macke/VoxelSpace
public class VoxelEngine_origin {
    
    public var screenImage : Bitmap! = nil
    var mapData : Bitmap
    var depthData : Bitmap
    
    public var camera = Camera()
    var map : Map!
    //    var screendata = Screendata()
    var screenSize : CGSize
    var hiddeny = [Int]()
    
    public var speed : CGFloat = 0.0
    public var strafeSpeed : CGFloat = 0.0
    public var leftRight : CGFloat = 0.0
    public var upDown : CGFloat = 0.0
    public var tilt : Double = 0
    
    var backgroundColor = Color(r: 64, g: 139, b: 246)
    var fogColor : Int = Color(r: 69, g: 144, b: 246).getInt()
    var fogDistance = 0
    
    var tx : Double = 0
    var ty : Double = 0
    var follow_terrain = false
    
    public init( mapData: Bitmap, depthData: Bitmap, size: CGSize ) {
        self.mapData = mapData
        self.depthData = depthData
        map = Map(w:mapData.width, h:mapData.height, mapScale:8)
        self.screenSize = size
        self.initImage(size: size)
        
        
        self.fogDistance = Int(camera.distance) - 500//Int((size.width / 2) / tan(deg2rad(90 / 2)));
        
    }
    
    
    public func setMapData( mapData: Bitmap, depthData: Bitmap ) {
        self.mapData = mapData
        self.depthData = depthData
        map = Map(w:mapData.width, h:mapData.height, mapScale:8)
        self.initImage(size: screenSize)
    }
    
    
}

public extension VoxelEngine_origin {
    
    func initImage( size: CGSize ) {
        var i = 0
        for y in 0 ..< map.height {
            for x in 0 ..< map.width {
                let c = mapData[x,y]
                let d = depthData[x,y]
                
                map.color[i] = c
                map.altitude[i] = Int(d.r) * 4// 2
                
                i += 1
            }
        }
        
        screenImage = Bitmap(width:Int(size.width/2), height:Int(size.height/2), color: Color.white)
        
        hiddeny = [Int](repeating: screenImage.height, count: screenImage.width)
        
    }
    
    func drawVerticalLine(x: Int, ytop: Int, ybottom: Int, col: Color)
    {
        let yt = max(0, ytop)
        if yt > ybottom {
            return
        }
        
        for var y in (yt) ..< (ybottom) {
            y = min(y, screenImage.height-1)
            y = max(y, 0)
            screenImage.pixels[y * screenImage.width + x] = col
        }
    }
    
    func updateCamera(timeStep: Double ) {
        
        camera.x -= speed * sin(camera.angle) * CGFloat(timeStep) * 0.16
        camera.y -= speed * cos(camera.angle) * CGFloat(timeStep) * 0.16
        
        camera.x -= strafeSpeed * sin(camera.angle+CGFloat.pi/2) * CGFloat(timeStep) * 0.16
        camera.y -= strafeSpeed * cos(camera.angle+CGFloat.pi/2) * CGFloat(timeStep) * 0.16
        
        if (leftRight != 0)
        {
            camera.angle += leftRight * 0.1 * CGFloat(timeStep) * 0.03
        }
        
        if (upDown != 0)
        {
            camera.height += upDown * CGFloat(timeStep) * 0.03
        }
        
        // Collision detection. Don't fly below the surface.
        let cmap_height = map.altitude[map.getMapOffset( x:camera.x, y:camera.y)]
        let tmap_height = map.altitude[map.getMapOffset( x:tx, y:ty)]
        if follow_terrain {
            camera.height = CGFloat(max(cmap_height,tmap_height) + 10)
        } else {
            if (cmap_height+10) > Int(camera.height) || (tmap_height+10) > Int(camera.height) {
                camera.height = CGFloat(max(cmap_height,tmap_height) + 10)
            }
        }
    }
    
    func update(timeStep: Double) {
        
        updateCamera(timeStep: timeStep)
        
        screenImage.fill( color:backgroundColor )
        
        let screenWidth = screenImage.width
        let sinang = sin(camera.angle)
        let cosang = cos(camera.angle)
        
        _ = hiddeny.withUnsafeMutableBytes { ptr in
            ptr.initializeMemory(as: Int.self, repeating: screenImage.height)
        }
        
        var deltaz : CGFloat = 1.0
        var z : CGFloat = 1.0
        var fogFactor = 0;
        
        let r : Double = 50
        tx = (-r * sin(Double(camera.angle))) + camera.x;
        ty = (-r * cos(Double(camera.angle))) + camera.y;
        
        while z < camera.distance {
            // 90 degree field of view
            var plx =  -cosang * z - sinang * z
            var ply =   sinang * z - cosang * z
            let prx =   cosang * z - sinang * z
            let pry =  -sinang * z - cosang * z
            
            let dx = (prx - plx) / CGFloat(screenWidth)
            let dy = (pry - ply) / CGFloat(screenWidth)
            plx += camera.x
            ply += camera.y
            let invz = 1.0 / z * 240.0
            
            for i in 0 ..< screenWidth {
                let map_offset = map.getMapOffset( x:plx, y:ply)
                
                let heightonscreen = (camera.height - CGFloat(map.altitude[map_offset])) * invz + camera.horizon
                
                //add fog
                var colorRGB = map.color[map_offset].getInt()
                if( z > Double(fogDistance)) {
                    fogFactor = Int( (z - Double(fogDistance)) * 0.75); //arbitrary value that looked good
                    if(fogFactor > 256) {
                        fogFactor = 256;
                    }
                    colorRGB = blendColor(colorRGB, fogColor, fogFactor);
                }
                
                if plx >= (tx-1) && plx <= (tx+1) && ply >= (ty-1) && ply <= (ty+1) {
                    colorRGB = Color.red.getInt()
                }

                
                // Tilt - doesn't quite work properly - need to figure out why!
                //                let tiltOffset = tilt * ((Double(i) / Double(screenWidth) - 0.5) + 0.5) * Double(screenHeight) / 4
                //                drawVerticalLine(x: i, ytop: Int(heightonscreen + tiltOffset), ybottom: hiddeny[i] + tiltOffset), col: Color(c:UInt32(colorRGB)))
                
                drawVerticalLine(x: i, ytop: Int(heightonscreen), ybottom: hiddeny[i], col: Color(c:UInt32(colorRGB)))
                if (Int(heightonscreen) < hiddeny[i]) {
                    hiddeny[i] = Int(heightonscreen)
                }
                plx += dx
                ply += dy
            }
            
            z += deltaz
            deltaz += 0.005
        }
    }
    
}
