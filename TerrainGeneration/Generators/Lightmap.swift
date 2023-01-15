//
//  Lightmap.swift
//  Voxel
//
//  Created by Andy Qua on 27/12/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import Foundation
import Engine

public struct Point {
    var x: Int = 0
    var y: Int = 0
}
public class Lightmap
{
    var sunPos : Vector3<Float>
    var currentPoint : Vector3<Float>
    
    var hmap : Bitmap!
    var lmap : Bitmap
    
    var ambient : UInt8 = 150
        
    var brightness : UInt8 = 50
    
    init( ) {
        lmap = Bitmap( width:100, height:100, color:.black )
        //            sunPos = new Vector( 550, 5000, 250 )
        sunPos = Vector3<Float>( 128, 500, 128 )
        currentPoint = Vector3<Float>( 0, 0, 0 )
    }
    
    public func generateLightmap( _ originalHmap: Bitmap ) {
        
        hmap = originalHmap
        lmap = Bitmap( width:hmap.width, height:hmap.height, color:Color(r: ambient, g: ambient, b: ambient) )

        currentPoint = Vector3<Float>( 0, 0, 0 )
        generateLightmap()
        
//        lmap = new Bitmap( lmap, originalHmap.Width, originalHmap.Height )
    }
    
    public func setSunPos( _ x : Int, _ y : Int, _ z : Int ) {
        sunPos = Vector3<Float>( Float(x), Float(y), Float(z) )
    }
    
    public func getSunPos() ->  Vector3<Float> {
        return sunPos
    }
    
    public func getHeightmap() -> Bitmap {
        return hmap
    }
    
    public func getLightmap() -> Bitmap {
        return lmap
    }
    
//    public void Save( String filename, ImageFormat fmt, int sizeX, int sizeY )
//    {
//        Bitmap b = new Bitmap( lmap, sizeX, sizeY )
//        b.Save( filename, fmt )
//    }
    
    private func generateLightmap() {
        print( "Generating lightmap" )
                
        for x in 0 ..< hmap.width {
            for y in 0 ..< hmap.height {
                currentPoint.x = Float(x)
                currentPoint.y = Float(hmap[x,y].b)
                currentPoint.z = Float(y)
                
                var hit = intersectMap( )
                if ( hit.x == -1 )
                {
                    hit.x = x
                    hit.x = y
                }
                
                var c = Int(lmap[x,y].b)
                c += Int(brightness)
                if c >= 255 {
                    c = 255
                }
                lmap[hit.x, hit.y] = Color( r: UInt8(c), g: UInt8(c), b: UInt8(c) )
            }
            
            if x % 10 == 0  {
                print( "Percent complete = \(x * 100/hmap.width)" )
            }
        }
        print( "Finished" )
    }
    
    private func intersectMap( ) -> Point {
        var ptHit = Point( x:-1, y:-1 )
        var pos = Vector3<Float>( currentPoint )
        var dir = sunPos - pos
        dir.y = 0
        dir = Vector3.normalize( dir )
        
        let v1 = Vector3<Float>( currentPoint.x, 0, currentPoint.z )
        let v2 = Vector3<Float>( sunPos.x, 0, sunPos.z )
        
        let totalDistance = Vector3<Float>.distance( v1, v2 )
        while pos.x > 0 && Int(pos.x) < hmap.width && pos.z > 0 && Int(pos.z) < hmap.height {
            let x = Int(floor( pos.x ))
            let z = Int(floor( pos.z ))
            
            if abs(Float(x)-sunPos.x) <= 2.5  && abs( Float(z) - sunPos.z) <= 2.5 {
                break
            }
            
            let dx = Vector3<Float>.distance( currentPoint, pos )
            let h = currentPoint.y + (dx * sunPos.y) / totalDistance
            if Float(hmap[x,z].b) > h {
                ptHit.x = x
                ptHit.y = z
            }
            
            pos = pos + dir
        }
        
        return ptHit
    }
}
