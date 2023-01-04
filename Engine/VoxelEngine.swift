//
//  VoxelEngine.swift
//  Voxel
//
//  Created by Andy Qua on 05/11/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import GameplayKit

public struct Camera {
    var x : CGFloat = 512
    var y : CGFloat = 800
    var height : CGFloat = 624//78
    var angle : CGFloat = 0
    public var horizon : CGFloat = 10 //100
    var distance : CGFloat = 3200
}

struct Map {
    var width: Int = 1024
    var height: Int = 1024
    var mapScale: Double = 2
    var altitude: [Int]
    var color: [Color]
    
    init( w: Int = 1024, h:Int = 1024, mapScale : Int = 2 ) {
        self.width = w
        self.height = h
        self.mapScale = Double(mapScale)
        self.altitude = [Int](repeating:0,  count:width*height) // 1024 * 1024 byte array with height information
        self.color = [Color](repeating:Color.black, count:width*height)
    }

    func getMapOffset( x: Double, y: Double ) -> Int {
        let map_offset = (Int(y/mapScale) & (width - 1)) * width + (Int(x/mapScale) & (height - 1));
        
        return map_offset
    }

}

// This is based on @gustavopezzi's (@Pikukma@mastodon.gamedev.place) rendering engine
// (https://github.com/gustavopezzi/voxelspace)
public class VoxelEngine {
    
    public var screenImage : Bitmap! = nil
    var mapData : Bitmap
    var depthData : Bitmap

    public var camera = Camera()
    var map : Map!
    var screenSize : CGSize

    public var speed : CGFloat = 0.0
    public var strafeSpeed : CGFloat = 0.0
    public var leftRight : CGFloat = 0.0
    public var upDown : CGFloat = 0.0
    public var tilt : Double = 0

    var backgroundColor = Color(r: 64, g: 139, b: 246)
    var fogColor : Int = Color(r: 69, g: 144, b: 246).getInt()
    var fogDistance = 0

    // This is used for a small target point in front of the camera to smooth the terrain collision
    var tx : Double = 0
    var ty : Double = 0
    let follow_terrain = false

    let mapScale = 8


    public init( mapData: Bitmap, depthData: Bitmap, size: CGSize ) {
        self.mapData = mapData
        self.depthData = depthData
        self.map = Map(w:mapData.width, h:mapData.height, mapScale:mapScale)
        self.screenSize = size
        self.initImage(size: size)
        
        self.fogDistance = Int(camera.distance) - 500
    }
    

    public func setMapData( mapData: Bitmap, depthData: Bitmap ) {
        self.mapData = mapData
        self.depthData = depthData
        map = Map(w:mapData.width, h:mapData.height, mapScale: 4)
        self.initImage(size: screenSize)
    }
}

public extension VoxelEngine {
    
    func initImage( size: CGSize ) {
        var i = 0
        for y in 0 ..< map.height {
            for x in 0 ..< map.width {
                let c = mapData[x,y]
                let d = depthData[x,y]
                
                map.color[i] = c
                map.altitude[i] = Int(d.r) * 8// 2
                
                i += 1
            }
        }
        
        screenImage = Bitmap(width:Int(size.width/2), height:Int(size.height/2), color: Color.white)
    }
    
    func updateCamera(timeStep: Double ) {
        
        camera.x += speed * cos(camera.angle) * CGFloat(timeStep) * 0.16
        camera.y += speed * sin(camera.angle) * CGFloat(timeStep) * 0.16
        
        camera.x -= strafeSpeed * cos(camera.angle+CGFloat.pi/2) * CGFloat(timeStep) * 0.16
        camera.y -= strafeSpeed * sin(camera.angle+CGFloat.pi/2) * CGFloat(timeStep) * 0.16

        if (leftRight != 0)
        {
            camera.angle -= leftRight * 0.1 * CGFloat(timeStep) * 0.03
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
        let screenHeight = screenImage.height
        let sinangle = sin(camera.angle)
        let cosangle = cos(camera.angle)
        var fogFactor = 0

        // Left-most point of the FOV
        let plx = cosangle * camera.distance + sinangle * camera.distance;
        let ply = sinangle * camera.distance - cosangle * camera.distance;
        
        // Right-most point of the FOV
        let prx = cosangle * camera.distance - sinangle * camera.distance;
        let pry = sinangle * camera.distance + cosangle * camera.distance;
        
        let r : Double = 50
        tx = (r * cos(Double(camera.angle))) + camera.x
        ty = (r * sin(Double(camera.angle))) + camera.y

        // Loop 320 rays from left to right
        for i in 0 ..< screenWidth {
            let deltax = (plx + (prx - plx) / Double(screenWidth) * Double(i)) / camera.distance;
            let deltay = (ply + (pry - ply) / Double(screenWidth) * Double(i)) / camera.distance;
            
            // Ray (x,y) coords
            var rx : Double = camera.x;
            var ry : Double = camera.y;
            
            // Store the tallest projected height per-ray
            var tallestheight = screenHeight;
            
            // Loop all depth units until the zfar distance limit
            for z in 1 ..< Int(camera.distance) {
                rx += deltax;
                ry += deltay;
                
                // Find the offset that we have to go and fetch values from the heightmap
                let mapoffset = map.getMapOffset( x:Double(rx), y:Double(ry))
                
                // Project height values and find the height on-screen
                let projheight = Int((camera.height - Double(map.altitude[mapoffset])) / Double(z) * 70 + camera.horizon);
                                
                var colorRGB = map.color[mapoffset].getInt()
                if( z > fogDistance) {
                    fogFactor = Int( (Double(z - fogDistance)) * 0.75); //arbitrary value that looked good
                    if fogFactor > 256 {
                        fogFactor = 256
                    }
                    colorRGB = blendColor(colorRGB, fogColor, fogFactor);
                }
                
                if rx >= (tx-1) && rx <= (tx+1) && ry >= (ty-1) && ry <= (ty+1) {
                    colorRGB = Color.red.getInt()
                }

                
                // Only draw pixels if the new projected height is taller than the previous tallest height
                if (projheight < tallestheight) {
                    
                    // Handle tilting the screen
                    let lean : Int = Int((tilt * (Double(i) / Double(screenWidth)-0.5) + 0.5) * Double(screenHeight) / 1)

                    // Draw pixels from previous max-height until new height (offsetting by lean_factor)
                    for y in (projheight + lean) ..< (tallestheight + lean) {
                        if y >= 0 && y < screenHeight {
                            screenImage.pixels[(y * screenWidth) + i] = Color(c:UInt32(colorRGB))
                        }
                    }
                    tallestheight = projheight;
                }
            }
        }
    }
}
