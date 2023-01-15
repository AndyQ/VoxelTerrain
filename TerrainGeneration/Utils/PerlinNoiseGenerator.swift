//
//  PerlinNoiseGenerator.swift
//  Voxel
//
//  Created by Andy Qua on 27/12/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import Foundation
class PerlinNoise {
    var persistence: Double
    var frequency: Double
    var amplitude: Double
    var octaves: Int
    var randomseed: Int
    
    init() {
        persistence = 0
        frequency = 0
        amplitude  = 0
        octaves = 0
        randomseed = 0
    }
    
    init(persistence: Double, frequency: Double, amplitude: Double, octaves: Int, seed: Int) {
        self.persistence = persistence
        self.frequency = frequency
        self.amplitude  = amplitude
        self.octaves = octaves
        self.randomseed = seed//2 + seed * seed
    }
    
    func set(persistence: Double, frequency: Double, amplitude: Double, octaves: Int, randomseed: Int) {
        self.persistence = persistence
        self.frequency = frequency
        self.amplitude  = amplitude
        self.octaves = octaves
        self.randomseed = 2 + randomseed * randomseed
    }
    
    func getHeight(x: Double, y: Double) -> Double {
        return amplitude * total(i: x, j: y)
    }
    
    func total(i: Double, j: Double) -> Double {
        var t = 0.0
        var amplitude = 1.0
        var freq = frequency
        
        for _ in 0..<octaves {
            t += getValue(x: j * freq + Double(randomseed), y: i * freq + Double(randomseed)) * amplitude
            amplitude *= persistence
            freq *= 2
        }
        return t
    }
    
    func getValue(x: Double, y: Double) -> Double {
        let Xint = Int(x)
        let Yint = Int(y)
        let Xfrac = x - Double(Xint)
        let Yfrac = y - Double(Yint)
        
        let n01 = noise(x: Xint-1, y: Yint-1)
        let n02 = noise(x: Xint+1, y: Yint-1)
        let n03 = noise(x: Xint-1, y: Yint+1)
        let n04 = noise(x: Xint+1, y: Yint+1)
        let n05 = noise(x: Xint-1, y: Yint)
        let n06 = noise(x: Xint+1, y: Yint)
        let n07 = noise(x: Xint, y: Yint-1)
        let n08 = noise(x: Xint, y: Yint+1)
        let n09 = noise(x: Xint, y: Yint)
        
        let n12 = noise(x: Xint+2, y: Yint-1)
        let n14 = noise(x: Xint+2, y: Yint+1)
        let n16 = noise(x: Xint+2, y: Yint)
        
        let n23 = noise(x: Xint-1, y: Yint+2)
        let n24 = noise(x: Xint+1, y: Yint+2)
        let n28 = noise(x: Xint, y: Yint+2)
        
        let n34 = noise(x: Xint+2, y: Yint+2);
        
        //find the noise values of the four corners
        let x0y0 = 0.0625*(n01+n02+n03+n04) + 0.125*(n05+n06+n07+n08) + 0.25*(n09);
        let x1y0 = 0.0625*(n07+n12+n08+n14) + 0.125*(n09+n16+n02+n04) + 0.25*(n06);
        let x0y1 = 0.0625*(n05+n06+n23+n24) + 0.125*(n03+n04+n09+n28) + 0.25*(n08);
        let x1y1 = 0.0625*(n09+n16+n28+n34) + 0.125*(n08+n14+n06+n24) + 0.25*(n04);
        
        //interpolate between those values according to the x and y fractions
        let v1 = interpolate(x: x0y0, y: x1y0, a: Xfrac); //interpolate in x direction (y)
        let v2 = interpolate(x: x0y1, y: x1y1, a: Xfrac); //interpolate in x direction (y+1)
        let fin = interpolate(x: v1, y: v2, a: Yfrac);  //interpolate in y direction
        
        return fin;
    }
    
    func interpolate(x: Double, y: Double, a: Double) -> Double {
        let negA = 1.0 - a
        let negASqr = negA * negA
        let fac1 = 3.0 * (negASqr) - 2.0 * (negASqr * negA)
        let aSqr = a * a
        let fac2 = 3.0 * aSqr - 2.0 * (aSqr * a)
        
        return x * fac1 + y * fac2
    }
    
    func noise(x: Int, y: Int) -> Double {
        var n  = x + y * 57
        n = (n << 13) ^ n
        let t = (n &* (n &* n &* 15731 &+ 789221) &+ 1376312589) & 0x7fffffff
        return 1.0 - Double(t) * 0.931322574615478515625e-9
    }
}
