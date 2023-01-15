//
//  TerrainGenerator.swift
//  PatchTerrain
//
//  Created by Andy on 10/05/2016.
//  Copyright © 2016 Andy. All rights reserved.
//

import Engine

// Some notes: from http://gamedev.stackexchange.com/questions/23625/how-do-you-generate-tileable-perlin-noise
/*
Perlin noise is generated from a summation of little "surflets" which are the product of a randomly oriented gradient 
 and a separable polynomial falloff function. This gives a positive region (yellow) and negative region (blue)

Kernel

The surflets have a 2x2 extent and are centered on the integer lattice points, so the value of Perlin noise at each point 
 in space is produced by summing the surflets at the corners of the cell that it occupies.

Summation

If you make the gradient directions wrap with some period, the noise itself will then wrap seamlessly with the same period. This is why the code above takes the lattice coordinate modulo the period before hashing it through the permutation table.

The other step, is that when summing the octaves you will want to scale the period with the frequency of the octave. Essentially, you will want each octave to tile the entire just image once, rather than multiple times:
*/

import CoreImage

func randomInt( _ from: UInt8, to: UInt8 ) -> UInt8 {
    return UInt8(arc4random_uniform(UInt32(to)-UInt32(from))) + from
}



class TerrainGenerator: NSObject {
    
    // MARK: Terrain Generation
    var perm : [Int] = (0 ..< 256).map{ $0 }
    var dirs : [(Double,Double)]!
    
    var permSize = 256
    var terrainSize = 128
    
    func generateTerrain( _ mapSize: Int ) -> (Bitmap, Bitmap) {
        
        permSize = mapSize*2
        terrainSize = mapSize
        
        perm = (0 ..< permSize).map{ $0 }
        perm.shuffle()
        perm += perm
        
        let val = 2.0 * Double.pi / Double(permSize)
        dirs = (0 ..< permSize).map{ (cos(Double($0) * val), sin(Double($0) * val)) }
        
        let size = terrainSize
        let freq = 1/32.0
        let octs = 5
        
        var height = Bitmap(width: size, height: size, color: .black)
        var map = Bitmap(width: size, height: size, color: .black)
        for y in 0 ..< size {
            for x in 0 ..< size {
                var val = fBm(Double(x)*freq, y: Double(y)*freq, per: Int(Double(size)*freq), octs: octs)
                val = val*100 + 100
                
                if val <= 60 {
                    val = 60
                }
                let c = UInt8(val)
                height[x,y] = Color(r: c, g: c, b: c)
                map[x,y] = getColor(c)
            }
        }
        
        print( "got image")
        return (height ,map)
    }
    
    func fBm(_ x : Double, y : Double, per : Int, octs : Int) -> Double {
        var val = 0.0
        for o in 0 ..< octs {
            let od = Double(o)
            val += pow(0.5,od) * noise(x*pow(2,od), y: y*pow(2,od), per: Int(Double(per)*pow(2,od)))
        }
        return val
    }
    
    func noise( _ x : Double, y : Double, per : Int ) -> Double {
        
        func surflet( _ gridX: Int, gridY : Int ) -> Double {
            let distX = abs(x - Double(gridX))
            let distY = abs(Double(y) - Double(gridY))
            let polyX = 1 - 6*pow(distX,5) + 15*pow(distX,4) - 10*pow(distX,3)
            let polyY = 1 - 6*pow(distY,5) + 15*pow(distY,4) - 10*pow(distY,3)
            let hashed = Int(perm[perm[Int(gridX)%per] + Int(gridY)%per])
            let grad = (x-Double(gridX))*dirs[hashed].0 + (y-Double(gridY))*dirs[hashed].1
            return polyX * polyY * grad
        }
        
        let intX = Int(x)
        let intY = Int(y)
        return (surflet(intX+0, gridY: intY+0) + surflet(intX+1, gridY: intY+0) +
            surflet(intX+0, gridY: intY+1) + surflet(intX+1, gridY: intY+1))
    }
    
    func getColor( _ val : UInt8 ) -> Color {
        var r : UInt8 = 0
        var g : UInt8 = 0
        var b : UInt8 = 0
        if val <= 105 {
            r = UInt8(val/10 + randomInt(0, to:30))
            g = UInt8(val/10 + 100 + randomInt(0, to:30))
            b = 255
        } else if val <= 110 {
            r = 255
            g = 255
        } else {
            r = UInt8(val/10 + randomInt(0, to:100))
            g = UInt8(val/10 + 100 + randomInt(0, to:60))
            b = UInt8(val/10 + randomInt(0, to:100))
        }
        
        return Color( r: r, g: g, b: b, a:255 )
    }
}
