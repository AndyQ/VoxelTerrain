//
//  PerlinNoiseGenerator.swift
//  Voxel
//
//  Created by Andy Qua on 27/12/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import Foundation
import Engine

typealias CompletionHandler = (Int)->(String)

typealias InterpolateFunction = (Double, Double, Double) -> Double
typealias NoiseFunction = (Int, Int) -> Double
typealias NoiseBoundFunction = (Double) -> Double

public class PerlinNoiseGenerator
{
    // Vars for current perlin noise
    // This is just a convienient place to cache them so aren't parsing text from the text boxes
    // in a tight loop (== BAD)
    public struct PerlinVars
    {
        var ifreq : Double = 0.03125
        var iamp : Double = 1.0
        var octaves : Int = 5
        var persistance : Double = 0.5
        var useRandomSeed : Bool = false
        var random_seed : Int = 0
        var wrap : Bool = true
        var size_x : Int = 256
        var size_y : Int = 256
        var cur_freq : Double  = 0// used to manage wrap around texture generation, a bit of a hack
        var palette : Bool = false
    }
    
    private var SelectedInterpolateFunction : InterpolateFunction!
    private var SelectedNoiseFunction : NoiseFunction!
    private var SelectedNoiseBoundFunction : NoiseBoundFunction!
    
    
    var bitmap : Bitmap!
    private var perlinVars = PerlinVars()

    
    /// <summary>
    /// The main entry point for the application.
    /// </summary>
//    static void Main2() {
//        PerlinNoiseGenerator app = new PerlinNoiseGenerator()
//        app.GenerateNoise()
//        app.NoiseImage.Save( "noisemap.jpg", ImageFormat.Jpeg )
//    }
    
    public init( sizeX : Int = 256, sizeY: Int = 256) {
        SelectedInterpolateFunction = CosineInterpolate
        SelectedNoiseFunction = Noise
        SelectedNoiseBoundFunction = NormalizedTruncateBoundNoise
        
        perlinVars.size_x = sizeX
        perlinVars.size_y = sizeY
    }
    
    public func setNoInterpolation() {
        SelectedInterpolateFunction = NoInterpolation
    }
    
    public func setLinearInterpolation() {
        SelectedInterpolateFunction = LinearInterpolate
    }
    
    public func setCosineInterpolation() {
        SelectedInterpolateFunction = CosineInterpolate
    }
    
    public func setCubicInterpolation() {
        SelectedInterpolateFunction = CubicInterpolate
    }
    
    
    public func setSmoothing( val : Bool ) {
        if val {
            SelectedNoiseFunction = SmoothedNoise
        } else {
            SelectedNoiseFunction = Noise
        }
    }
    
    public func setAbsNoiseBound() {
        SelectedNoiseBoundFunction = AbsBoundNoise
    }
    
    public func setTruncateNoiseBound() {
        SelectedNoiseBoundFunction = TruncateBoundNoise
    }
    
    public func setNormalizedTruncateNoiseBound() {
        SelectedNoiseBoundFunction = NormalizedTruncateBoundNoise
    }
    
    public func GenerateNoise() {
        bitmap = Bitmap( width:perlinVars.size_x, height:perlinVars.size_y, color:Color.black )
        
        if perlinVars.useRandomSeed {
            perlinVars.random_seed = Int.random(in: Int.min..<Int.max)
        }
        
        print( "Generating heightmap" )
        for x in 0 ..< bitmap.width {
            for y in 0 ..< bitmap.height {
                let c = UInt8(SelectedNoiseBoundFunction(PerlinNoise(x, y))*255.0)
                bitmap[x,y]  = Color(r: c, g: c, b: c)
            }
            
            if x % 10 == 0 {
                print( "Percentage completed - \(x*100/bitmap.width)" )
            }
        }
        
        print( "Finished" )
    }
    
    private func AbsBoundNoise( _ val : Double) -> Double {
        var n = val
        if n < 0.0 {
            n = -n
        }
        if n > 1.0 {
            n = 1.0
        }
        return n
    }
    
    private func TruncateBoundNoise(_ val : Double) -> Double {
        var n = val
        if n < 0.0 {
            n = 0.0
        }
        if n > 1.0 {
            n = 1.0
        }
        return n
    }
    
    private func NormalizedTruncateBoundNoise(_ val : Double) -> Double {
        var n = val
        
        if n < -1.0 {
            n = -1.0
        }
        if n > 1.0 {
            n = 1.0
        }
        return (n * 0.5) + 0.5
    }
    
    private func Noise(_ val : Int) -> Double
    {
        var x = val + perlinVars.random_seed
        x = ((x<<13) & 0xffffffff) ^ x
        
        let x1 = x &* x &* 15731 &+ 789221
        let x2 = x &* x1 &+ 1376312589
        let x3 : Double = Double(x2 & 0x7fffffff)
        let x4 = 1.0 - (x3 / 1073741824.0)
        return x4
//        return ( 1.0 - ( (x &* (x &* x &* 15731 &+ 789221) &+ 1376312589) & 0x7fffffff) / 1073741824.0)
    }
    
    private func Noise(_ valX : Int, _ valY : Int) -> Double {
        var x = valX
        var y = valY
        if perlinVars.wrap {
            let s = Int(round(Double(perlinVars.size_x)*perlinVars.cur_freq))
            if s > 0 {
                x %= s
                y %= s
            }
            if x < 0 {
                x += s
            }
            if y < 0 {
                y += s
            }
        }
        // all the mysterious large numbers in these functions are prime.
        let n = Noise(x &+ y &* 8997587)//57)
        //print( "\(x), \(y) = \(n)")
        return n
    }
    
    private func Noise(_ x : Int, _ y : Int, _ z : Int ) -> Double {
        return Noise(x &+ (y &* 89213) &+ (z &* 8997587))
    }
    
    private func SmoothedNoise(_ x : Int, _ y : Int) -> Double {
        let corners = ( Noise(x-1, y-1)+Noise(x+1, y-1)+Noise(x-1, y+1)+Noise(x+1, y+1) ) / 16
        let sides   = ( Noise(x-1, y)  + Noise(x+1, y)  + Noise(x, y-1)  + Noise(x, y+1) ) /  8
        let center  =  Noise(x, y) / 4
        return corners + sides + center
    }
    
    private func InterpolatedNoise(_ x : Double, _ y : Double) -> Double {
        let a = Int(x)
        let b = Int(y)
        let frac_a = x - Double(a)
        let frac_b = y - Double(b)
        
        let v1 = SelectedNoiseFunction(a,b)
        let v2 = SelectedNoiseFunction(a + 1, b)
        let v3 = SelectedNoiseFunction(a,b+1)
        let v4 = SelectedNoiseFunction(a+1,b+1)
        
        let i1 = SelectedInterpolateFunction(v1 , v2 , frac_a)
        let i2 = SelectedInterpolateFunction(v3 , v4 , frac_a)
        
        return SelectedInterpolateFunction(i1 , i2 , frac_b)
    }
    
    private func LinearInterpolate(_ a : Double, _ b : Double, _ x : Double) -> Double {
        return a*(1-x) + b*x
    }
    
    private func CosineInterpolate(_ a : Double, _ b : Double, _ x : Double) -> Double {
        let ft = x * 3.1415927
        let f = (1 - cos(ft)) * 0.5
        return a*(1-f)+b*f
    }
    
    private func CubicInterpolate(_ a : Double, _ b : Double, _ x : Double) -> Double {
        let fac1 = 3 * pow(1-x, 2) - 2 * pow(1-x,3)
        let fac2 = 3 * pow(x, 2) - 2 * pow(x, 3)
        
        return a*fac1 + b*fac2 //add the weighted factors
        
    }
    
    private func NoInterpolation(_ a : Double, _ b : Double, _ x : Double) -> Double {
        return a
    }
    
    private func PerlinNoise(_ x : Int, _ y : Int) -> Double {
        var total : Double = 0
        let p = perlinVars.persistance
        let n = perlinVars.octaves
        
        let ifreq = perlinVars.ifreq
        let iamp = perlinVars.iamp
        
        var freq = ifreq            // Math.Pow(2,i)
        var amp = iamp                // Math.Pow(p,i)
        
        for _ in 0 ..< n {
            perlinVars.cur_freq = freq
            let noise = InterpolatedNoise(Double(x) * freq, Double(y) * freq) * amp
            total += noise
//            print( noise );

            freq *= 2
            amp *= p
        }
        return total
    }
}
