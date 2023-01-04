//
//  TextureGenerator.swift
//  Voxel
//
//  Created by Andy Qua on 27/12/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import UIKit
import Engine

public class TextureGenerator
{
    public let LIGHT_SOFTNESS : UInt8 = 25     //makes lighting more transitive, smooth, and less abrupt
    public let MAX_BRIGHT : UInt8 = 255        //maximum brightness
    public let MIN_BRIGHT : UInt8 = 75//50        //minimal brightness (hillsides are never pitch black during the day)
    
    public let AMBIENT : UInt8 = 100//75
    
    
    public init( ) {
    }
    
    public func generateTexture( _ heightmap : Bitmap ) -> Bitmap {
        let textureNames = [ "snow", "rock", "grass", "sand", "water" ]
        return generateTexture( heightmap, textureNames: textureNames )
    }
    
    public func generateTexture( _ heightmap : Bitmap, textureNames : [String] ) -> Bitmap {
        var textures : [Bitmap] = []
        for n in textureNames {
            let image = UIImage(named: n)
            textures.append( image!.getBitmap())
        }
        return generateTexture( heightmap: heightmap, textures: textures  )
    }
    
    public func generateLightmap( _ heightmap : Bitmap ) -> Bitmap {
        // Generate Lightmap
        return generateLightMap( heightmap: heightmap )
    }
    
    public func mergeLightmapWithTexture( _ texture : Bitmap, _ lightmap : Bitmap ) -> Bitmap {
        // Merge lightmap (need to create one)
        print( "Merging lightmap" )
        return mergeLightmap( texture, lightmap )
    }
    
    public func generateTexture( heightmap : Bitmap, textures tex : [Bitmap] ) -> Bitmap {
        let width = heightmap.width
        let height = heightmap.height
        
        var tex_fact = [Float](repeating: 0, count: tex.count)  //Percentage of visibility for each texture
        var hmap_height : Float = 0 //The height at pos (x/y)
        var final_tex = Bitmap( width:width, height:height, color:.black )   //The final texture to be returned
        
        //Go through a map of 256x256
        for y in 0 ..< height {
            if y % 10 == 0 {
                print( "Dealing with line \(y)/\(height)" )
            }
            for x in 0 ..< width {
                //Get height at pos (x/y) out of bitmap
                hmap_height = Float(heightmap[x,y].b)
                
                //Get percentage for all bitmaps(Regions)
                tex_fact[0] = texfactor( 256, hmap_height)
                tex_fact[1] = texfactor( 192, hmap_height)
                tex_fact[2] = texfactor( 128, hmap_height)
                tex_fact[3] = texfactor( 64, hmap_height)
                tex_fact[4] = texfactor( 0, hmap_height)
                
                //Read all texture rgb values
                
                //The new rgb values to be written
                var r = 0
                var g = 0
                var b = 0
                for i in 0 ..< tex.count {
                    let tx = x%tex[i].width
                    let ty = y%tex[i].height
                    r += Int(tex_fact[i] * Float(tex[i][tx,ty].r))
                    g += Int(tex_fact[i] * Float(tex[i][tx,ty].g))
                    b += Int(tex_fact[i] * Float(tex[i][tx,ty].b))
                }
                
                //Write new color to texture
                final_tex[x,y] = Color(r: UInt8(r), g: UInt8(g), b: UInt8(b))
            }
        }
        return final_tex
    }
    
    public func generateSlopeLightingLightMap( heightmap : Bitmap ) -> Bitmap {
        let w = heightmap.width
        let h = heightmap.height
        
        var lmap = 0
        
        var lightmap = Bitmap( width:w, height:h, color:Color.black )
        print( "Generating Slope Lighting lightmap....." )
        
        for y in 1 ..< h-1 {
            if y % 10 == 0 {
                print( "Dealing with line \(y)/\(heightmap.height)" )
            }
            for x in 1 ..< w-1 {
                let h1 = heightmap[x-1,y-1].b
                let h2 = heightmap[x,y].b
                
                lmap = Int(h1) - Int(h2)
                lmap += 100
                if lmap > MAX_BRIGHT {
                    lmap = Int(MAX_BRIGHT)
                }
                if lmap < MIN_BRIGHT {
                    lmap = Int(MIN_BRIGHT)
                }
                
                //                Console.WriteLine( "x = {0}, y = {1}, h1 = {2}, h2 = {3}, lmap = {4}", x, y, h1, h2, lmap )
                //                field[x][y].light = (int)255*lmap
                
                let val = UInt8(lmap)
                lightmap[x,y] = Color(r: val, g: val, b: val)
            }
        }
        
        print( "\nSmoothing lightmap....." )
        smoothLightmap( lightmap:&lightmap )
        print( "Finished smoothing lightmap....." )
        
        return lightmap
    }
    
    private func smoothLightmap( lightmap : inout Bitmap ) {
        let w = lightmap.width
        let h = lightmap.height
        
        // SMOOTH TERRAIN
        for cnt in 0 ..< 3 {
            for y in 1 ..< h-1 {
                if y % 10 == 0 {
                    print( "Pass \(cnt) - Dealing with line \(y)/\(lightmap.height)", cnt, y, lightmap.height )
                }
                for x in 1 ..< w-1 {
                    let val = UInt8((Int(lightmap[x+1,y].b) +
                                Int(lightmap[x,y+1].b) +
                               Int(lightmap[x-1,y].b) +
                               Int(lightmap[x,y-1].b))/4)
                    
                    lightmap[x,y] = Color(r: val, g: val, b: val)
                }
            }
        }
    }
    
    
    let sun_pos : Float = 5000.0
    let sun_height : Float = 5000.0
    private func generateLightMap( heightmap: Bitmap ) -> Bitmap {
        // Setup sun position
        
        let w = heightmap.width
        let h = heightmap.height
        
        var hm = [[Int]](repeating: [Int](repeating: 0, count: w), count: h)
        var lm = [[Int]](repeating: [Int](repeating: 0, count: w), count: h)

        var lightmap = Bitmap( width:w, height:h, color:.black )
        
        
        print( "Reading heightmap" )
        for y in 0 ..< h {
            for x in 0 ..< w {
                hm[x][y] = Int(heightmap[x,y].b)
            }
        }
        
        let nrRayCols = w
        
        var lmap = [[Int]](repeating: [Int](repeating: 0, count: w), count: h)
        
        print( "Generating lightmap" )
        // OK, we want to shoot rays across the landscape starting from the
        for x in 0 ..< w {
            if x % 10 == 0 {
                print( "Shooting ray \(x)     " )
            }
            var finished = false
            for y in stride(from:nrRayCols-1, to:-500, by: -1) {
                if finished {
                    break
                }
                finished = true
                
                // Set ambient light
                if y >= 0 && lmap[x][y] == 0 {
                    lmap[x][y] = 100
                    lm[x][y] = 100
                }
                
                // Find where our ray collides with the landscape
                let p = findCollisionPoint( x, y, hm )
                if p.x == -1 {
                    // If no collision then move onto the next square
                    continue
                }
                
                // We have a collision
                finished = false
                
                // Increase the light at this point
                lmap[x][Int(p.x)] += 100
                var c = Int(lmap[x][Int(p.x)])
                if c > 255 {
                    c = 255
                }
                lm[x][Int(p.x)] = c
            }
        }
        
        print( "Finished generating lightmap, creating image....." )
        
        for y in 0 ..< h {
            for x in 0 ..< w {
                var v = lm[x][y]
                if v > 255 {
                    v = 255
                }
                lightmap[x,y] = Color( r:UInt8(v), g:UInt8(v), b:UInt8(v) )
            }
        }
        print( "Finished creating lightmap image....." )
        
        return lightmap
    }
    
    // This method uses a little trig
    // basically with a triangle:
    //
    //        /|
    //      /  |
    //    /    | opp
    //  /x_____|
    //     adj
    //
    // tan x = opp/adj
    //
    
    struct FPoint {
        var x : Float
        var y : Float
    }
    
    private func findCollisionPoint( _ x : Int, _ y: Int, _ hm:[[Int]] ) -> FPoint {
        // Calculate angle of ray
        let tan_angle = sun_height/(sun_pos - Float(y))
        
        var startPos = hm[0].count - 1
        var ret = FPoint( x:-1, y:-1)
        while startPos >= y && startPos >= 0 {
            // Calculate height of ray at this terrain position
            let rayHeight = Float(startPos-y) * tan_angle
            
            // If the terrain is higher than the ray then we have a collision
            if hm[x][startPos] >= Int(rayHeight) {
                ret.x = Float(startPos)
                ret.y = rayHeight
                break
            }
            
            startPos -= 1
        }
        
        return ret
    }
    
    private func mergeLightmap( _ texture : Bitmap, _ lightmap : Bitmap ) -> Bitmap {
        let width = texture.width
        let height = texture.height
        
        var litTex =  Bitmap( width:width, height:height, color:.black )
        
        // lock images
        
        // Take the blue value from the lightmap and use that to adjust the light of the texture
        for y in 0 ..< height {
            if y % 10 == 0 {
                print( "Dealing with line \(y)/\(height)", y, height )
            }
            for x in 0 ..< width {
                let l = lightmap[x,y]
                let t = texture[x,y]
                
                let val : Float = Float(l.b)/255
                let r = UInt8(Float(t.r) * val)
                let g = UInt8(Float(t.g) * val)
                let b = UInt8(Float(t.b) * val)
                let nc = Color(r: r, g: g, b: b)
                litTex[x,y] = nc//Color(r: r, g: g, b: b)
            }
        }
        
        return litTex
    }
    
    func texfactor(_ h1: Float, _ h2 : Float) -> Float {
        var percent : Float = Float((64.0 - abs(h1 - h2)) / 64.0)
        
        if percent < 0.0 {
            percent = 0.0
        } else if percent > 1.0 {
            percent = 1.0
        }
        
        return percent
    }
    
}
