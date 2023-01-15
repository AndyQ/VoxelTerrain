//
//  Terrain.swift
//  HeightmapGenerator
//
//  Created by Andy Qua on 08/01/2023.
//
// Most of the heightmap generation and erosion (thermal and hydraulic erosion) functions
// were converted from @Ziagl's console heightmap program - https://github.com/Ziagl/heightmap
// The water based erosion was ported from @SebLague's Hydralic Erosion app - https://github.com/SebLague/Hydraulic-Erosion

import UIKit
import Engine

public class Terrain {
    
    var seed : Int = 0
    var randomizeSeed = false
    
    var numOctaves = 7;
    var persistence : Double = 0.5
    var lacunarity : Double = 2.0
    var initialScale : Double = 2.0
    
    let perlin2D = Perlin2D(seed: "fish")
    
    var mapSize = 1024
    var map :[Double] = []
    
    var m_iSize : Int               // size of the terrain in pixels
    var m_iSize2 : Int                // pow of size
    var m_iSizeMask : Int        // Size-1

    // Erosion
    
    public init(mapSize : Int) {
        self.mapSize = mapSize
        self.m_iSize = mapSize

        m_iSize2 = mapSize * mapSize
        m_iSizeMask = mapSize - 1

        
        map = [Double](repeating: 0, count: mapSize * mapSize)// new float[mapSize * mapSize];

    }
    
    public func image() -> UIImage {
        return UIImage(bitmap:bitmap())!

    }
    public func bitmap() -> Bitmap {
        var bitmap = Bitmap(width: mapSize, height: mapSize, color: .black)
        for y in 0 ..< mapSize {
            for x in 0 ..< mapSize {
                var v = map[x + y*mapSize]
                if v.isNaN {
                    v = 1
                }
                let c = UInt8(max(0, min(255, v * 255)))
                bitmap[x,y] = Color(r:c , g: c, b: c)
            }
        }

        return bitmap
    }

    public func createWrappedImage( ) -> Bitmap {
        let w = self.mapSize*2
        let h = self.mapSize*2
        
        var newbm = Bitmap(width: w, height: h, color: .black)
        for x in 0..<self.mapSize {
            for y in 0..<self.mapSize {
                let v = map[x + y*mapSize]
                let c = UInt8(v * 255)
                let col = Color(r: c, g: c, b: c)
                newbm[x,y] = col
                newbm[w - x-1,y] = col
                newbm[x,h - y-1] = col
                newbm[w-x-1,h-y-1] = col
            }
        }
        
        // Scale image down
        let im = UIImage(bitmap:newbm)
        let newi = im?.resize(to: CGSize(width:mapSize, height:mapSize))        
        return newi!.getBitmap()
    }
}



extension Terrain {
    public func makePerlinNoiseMap( ) {
        seed = randomizeSeed ? randomInt(in:-10000 ... 10000) : seed
        
        var offsets = [Vector2](repeating:Vector2(0), count:numOctaves)
        for i in 0 ..< numOctaves {
            offsets[i] = Vector2(randomInt(in:-1000 ... 1000), randomInt(in:-1000 ... 1000))
        }
        
        var minValue = Double.greatestFiniteMagnitude
        var maxValue = Double.leastNormalMagnitude
        
        for y in 0 ..< mapSize {
            for x in 0 ..< mapSize {
                var noiseValue : Double = 0
                var scale : Double = initialScale
                var weight :Double = 1;
                for i in 0 ..< numOctaves {
                    let p = offsets[i] + Vector2( Double(x) / Double(mapSize),  Double(y) / Double(mapSize)) * scale;
                    noiseValue += perlin2D.noise(x:p.x, y:p.y) * weight;
                    weight *= persistence;
                    scale *= lacunarity;
                }
                map[y * mapSize + x] = noiseValue
                minValue = min (noiseValue, minValue);
                maxValue = max (noiseValue, maxValue);
            }
        }
        
        // Normalize
        if maxValue != minValue {
            for i in 0 ..< map.count {
                map[i] = max( 0.3,(map[i] - minValue) / (maxValue - minValue))
            }
        }
    }
    
    public func makePerlinNoise(persistence: Float, frequency: Float, amplitude: Float, octaves: Int, seed: Int, firValue: Double) {
        
        let p = PerlinNoise(persistence: Double(persistence), frequency: Double(frequency), amplitude: Double(amplitude), octaves: octaves, seed: seed)
        
        for x in 0..<m_iSize {
            for y in 0..<m_iSize {
                map[computeIndex(x, y)] = p.getHeight(x: Double(x), y: Double(y))
            }
        }
        
        if firValue > 0.0 {
            filterTerrain(filter: firValue)
        }
        
        normalize()
    }
    

    
    public func makeTriangleDivision(roughness: Double, seed: Int, firValue: Double) {
        
        var rectSize = mapSize
        var dh = Double(mapSize) * 0.5
        setRandomSeed( seed )

        let m_iSize = mapSize
        
        // random values for the edge points
        map[computeIndex(0, 0)] = randomDouble(in: -dh...dh)
        map[computeIndex(m_iSize-1, 0)] = randomDouble(in: -dh...dh)
        map[computeIndex(0, m_iSize-1)] = randomDouble(in: -dh...dh)
        map[computeIndex(m_iSize-1, m_iSize-1)] = randomDouble(in: -dh...dh)
        
        while (rectSize > 0) {
            dh = pow(Double(rectSize), roughness) //k^r
            for i in stride(from: 0, to: m_iSize, by: rectSize) {
                for j in stride(from: 0, to: m_iSize, by: rectSize) {
                    let x = (i + rectSize) & m_iSizeMask
                    let y = (j + rectSize) & m_iSizeMask
                    let mx = i + rectSize / 2
                    let my = j + rectSize / 2
                    
                    map[computeIndex(mx, my)] =
                    0.5 * (map[computeIndex(x, j)] + map[computeIndex(i, y)]) + randomDouble(in: -dh...dh)
                    
                    // above
                    map[computeIndex(mx, j)] =
                    0.5 * (map[computeIndex(i, j)] + map[computeIndex(x, j)]) + randomDouble(in: -dh...dh)
                    
                    // links
                    map[computeIndex(i, my)] =
                    0.5 * (map[computeIndex(i, j)] + map[computeIndex(i, y)]) + randomDouble(in: -dh...dh)
                }
            }
            rectSize >>= 1
        }
        
        if firValue > 0.0 {
            filterTerrain(filter: firValue)
        }
        normalize()
    }
    
    public func makeDiamondSquare(roughness: Double, seed: Int, firValue: Double) {
        var rectSize = m_iSize
        var dh = Double(m_iSize) * 0.25
        setRandomSeed( seed )

        var it: Double = 1.0
        
        while (rectSize > 0) {
            dh  = pow(roughness, it) //r^i
            
            // Diamond
            for i in stride(from: 0, to: m_iSize, by: rectSize) {
                for j in stride(from: 0, to: m_iSize, by: rectSize) {
                    let x = (i + rectSize) & m_iSizeMask
                    let y = (j + rectSize) & m_iSizeMask
                    let mx = i + rectSize / 2
                    let my = j + rectSize / 2
                    
                    map[computeIndex(mx, my)] =
                    0.25 * (map[computeIndex(i, j)] + map[computeIndex(x, j)] +
                            map[computeIndex(i, y)] + map[computeIndex(x, y)]) +
                    randomDouble(in: -dh...dh)
                }
            }
            
            // Square
            for i in stride(from: 0, to: m_iSize, by: rectSize) {
                for j in stride(from: 0, to: m_iSize, by: rectSize) {
                    let x = (i + rectSize) & m_iSizeMask
                    let y = (j + rectSize) & m_iSizeMask
                    let mx = i + rectSize / 2
                    let my = j + rectSize / 2
                    let sx = (i - rectSize / 2 + m_iSize) & m_iSizeMask
                    let sy = (j - rectSize / 2 + m_iSize) & m_iSizeMask
                    
                    // oben
                    map[computeIndex(mx, j)] =
                    0.25 * (map[computeIndex(i, j)] + map[computeIndex(x, j)] +
                            map[computeIndex(mx, sy)] + map[computeIndex(mx, my)]) +
                    randomDouble(in: -dh...dh)
                    
                    // links
                    map[computeIndex(i, my)] =
                    0.25 * (map[computeIndex(i, j)] + map[computeIndex(i, y)] +
                            map[computeIndex(sx, my)] + map[computeIndex(mx, my)]) +
                    randomDouble(in: -dh...dh)
                }
            }
            
            rectSize >>= 1
            it += 1
        }
        
        if(firValue > 0.0) {
            filterTerrain(filter: firValue)
        }
        normalize()
    }
    
    
    public func makeFaultFormation(iterations: Int, filterIterations: Int, firValue: Double) {
        for i in 0..<iterations {
            // Calculate height difference for this iteration
            let heightDifference = 100.0 * (1.0 - Double(i) / Double(iterations))
            
            // find two random, unequal points on the heightmap
            var x1, x2, y1, y2: Int
            
            x1 = randomInt(in: 0...m_iSizeMask)
            y1 = randomInt(in: 0...m_iSizeMask)
            
            repeat {
                x2 = randomInt(in: 0...m_iSizeMask)
                y2 = randomInt(in: 0...m_iSizeMask)
            } while (x2 == x1 && y2 == y1)
            
            let dx = Double(x2 - x1)
            var dy = Double(y2 - y1)
            
            let upDown = (dx > 0 && dy < 0) || (dx > 0 && dy > 0)
            
            if dx != 0 {
                dy /= dx
            } else {
                dy = 0.0
            }
            
            var _ :Double = 0.0
            var y : Double = Double(y1 - x1) * dy
            
            // and increase all points of one side (upDown decides!).
            for x2 in 0..<m_iSize {
                for y2 in 0..<m_iSize {
                    if ((upDown && y2 < Int(y)) /*up*/ || (!upDown && y2 > Int(y)) /*down*/) {
                        map[x2 + y2 * m_iSize] += heightDifference
                    }
                }
                y += dy
            }
            
            // and filter if desired
            if firValue > 0 {
                if (i % filterIterations) == 0 && filterIterations != 0 {
                    filterTerrain(filter: firValue);
                }
            }
        }
        
        normalize();
    } // makeFaultFormation
    
    
    public func makeMidpointDisplacement(roughness: Double, seed: Int, firValue: Double) {
        var _: Int
        
        var rectSize = m_iSize
        var dh = Double(m_iSize) * 0.25
        
        setRandomSeed( seed )

        var it = 1.0
        
        while rectSize > 0 {
            dh = pow(roughness, it)
            
            for i in stride(from: 0, to: m_iSize, by: rectSize) {
                for j in stride(from: 0, to: m_iSize, by: rectSize) {
                    let x = (i + rectSize) & m_iSizeMask
                    let y = (j + rectSize) & m_iSizeMask
                    
                    let mx = i + rectSize / 2
                    let my = j + rectSize / 2
                    
                    _ = (i - rectSize / 2 + m_iSize) & m_iSizeMask
                    _ = (j - rectSize / 2 + m_iSize) & m_iSizeMask
                    
                    map[computeIndex(mx, my)] =
                    0.25 * (map[computeIndex(i, j)] + map[computeIndex(x, j)] +
                            map[computeIndex(i, y)] + map[computeIndex(x, y)]) +
                    drand48() * 2 * dh - dh
                    
                    map[computeIndex(mx, j)] =
                    0.5 * (map[computeIndex(i, j)] + map[computeIndex(x, j)]) +
                    drand48() * 2 * dh - dh
                    
                    map[computeIndex(i, my)] =
                    0.5 * (map[computeIndex(i, j)] + map[computeIndex(i, y)]) +
                    drand48() * 2 * dh - dh
                }
            }
            
            rectSize >>= 1
            it += 1.0
        }
        
        if firValue > 0.0 {
            filterTerrain(filter:firValue)
        }
        normalize()
    }
    
    
    public func makeParticleDeposition(nMountain: Int, moveDrop: Int, particle: Int, caldera: Double, firValue: Double) {
        let DX = [0, 1, 0, m_iSize - 1, 1, 1, m_iSize - 1, m_iSize - 1]
        let DY = [1, 0, m_iSize - 1, 0, m_iSize - 1, 1, m_iSize - 1, 1]
        
        for m in 0 ..< nMountain {
            var x = Int(arc4random_uniform(UInt32(m_iSize))) & m_iSizeMask
            var y = Int(arc4random_uniform(UInt32(m_iSize))) & m_iSizeMask
            
            var topX = x
            var topY = y
            
            let nParticles = particle
            
            for i in 0 ..< nParticles {
                if moveDrop > 0 && i % moveDrop == 0 {
                    let dir = Int(arc4random_uniform(8))
                    x = (x + DX[dir]) & m_iSizeMask
                    y = (y + DY[dir]) & m_iSizeMask
                }
                
                map[computeIndex(x, y)] += 1
                
                var px = x
                var py = y
                var ok = 0
                
                while ok < 1 {
                    _ = Int(arc4random_uniform(8))
                    
                    for j in 0 ..< 8 {
                        let ofs = (j + m) & 7
                        let tx = (px + DX[ofs]) & m_iSizeMask
                        let ty = (py + DY[ofs]) & m_iSizeMask
                        
                        if map[computeIndex(px, py)] > map[computeIndex(tx, ty)] + 1.0 {
                            map[computeIndex(tx, ty)] += 1
                            map[computeIndex(px, py)] -= 1
                            px = tx
                            py = ty
                            ok = 0
                            break
                        }
                    }
                    ok += 1
                }
                
                if map[computeIndex(px, py)] > map[computeIndex(topX, topY)] {
                    topX = px
                    topY = py
                }
            }
            
            let calderaLine = map[computeIndex(topX, topY)] - caldera
            
            if calderaLine > 0 {
                createCalderas(x: topX, y: topY, height: calderaLine)
            }
        }
        
        if firValue > 0.0 {
            filterTerrain(filter: firValue)
        }
        normalize()
    }
    
    public func createCalderas( x : Int, y : Int,  height : Double)
    {
        if x < 0 || x >= m_iSize || y < 0 || y >= m_iSize {
            return
        }
        
        if map[ computeIndex( x, y ) ] > height {
            map[ computeIndex( x, y ) ] -= ( map[ computeIndex( x, y ) ] - height ) * 2.0
            
            createCalderas(x: x + 1, y: y, height: height);
            createCalderas(x: x - 1, y: y, height: height);
            createCalderas(x: x, y: y + 1, height: height);
            createCalderas(x: x, y: y - 1, height: height);
        }
    }
    
    public func makeVoronoiDiagram(points: Int, seed: Int, firValue: Double) {
        setRandomSeed( seed )

        let MAX_HEIGHT : Double = 255.0
        map = map.map { _ in 0 }
        
        struct vpoint
        {
            var x : Int
            var y : Int
        }
        
        var voronoiPoints = [vpoint]()
        
        // set random points
        for _ in 0..<points {
            let x = randomInt(in: 0..<m_iSize)
            let y = randomInt(in: 0..<m_iSize)
            voronoiPoints.append(vpoint(x: x, y: y))
        }
        
        let c1: Double = 1.0
        let c2: Double = -1.0
        
        for x in 0..<m_iSize {
            for y in 0..<m_iSize {
                if map[computeIndex(x, y)] == 0.0 {
                    // search next point and set color
                    var closestPoint: Double = 999999.0
                    var secondClosestPoint: Double = 999999.0
                    
                    for point in voronoiPoints {
                        let distance = Double(abs(x - point.x) + abs(y - point.y))
                        if distance < closestPoint {
                            secondClosestPoint = closestPoint
                            closestPoint = distance
                        } else if distance < secondClosestPoint {
                            secondClosestPoint = distance;
                        }
                    }
                    
                    let d1 = MAX_HEIGHT - closestPoint
                    let d2 = MAX_HEIGHT - secondClosestPoint
                    
                    map[computeIndex(x, y)] = c1*d1 + c2*d2
                }
            }
        }
        
        if firValue > 0.0 {
            filterTerrain(filter: firValue)
        }
        normalize()
    }
    
}

// MARK: Erosion
extension Terrain {
    public func makeWaterErosion(numErosionIterations : Int) async {
        let erosion = Erosion()
        map = erosion.erode(hm: map, mapSize: mapSize, numIterations: numErosionIterations);
        
        var bitmap = Bitmap(width: mapSize, height: mapSize, color: .black)
        for y in 0 ..< mapSize {
            for x in 0 ..< mapSize {
                var v = map[x + y*mapSize]
                if v.isNaN {
                    v = 1
                }
                let c = UInt8(v * 255)
                
                bitmap[x,y] = Color(r:c , g: c, b: c)
            }
        }
    }
    

    
    public func makeThermalErosion(talus: Double, iterations: Int) {
        for _ in 0..<iterations {
            for i in 0..<m_iSize {
                for j in 0..<m_iSize {
                    let height = map[computeIndex(i, j)]
                    if height > talus {
                        var material = height - talus
                        material = material * randomDouble(in: 0.01...0.09)
                        
                        var lower_neighbours = 0
                        var up = false
                        var down = false
                        var left = false
                        var right = false
                        
                        if i > 0 {
                            if map[computeIndex(i-1, j)] < height {
                                up = true
                                lower_neighbours += 1
                            }
                        }
                        if i < m_iSize-1 {
                            if map[computeIndex(i+1, j)] < height {
                                down = true
                                lower_neighbours += 1
                            }
                        }
                        if j > 0 {
                            if map[computeIndex(i, j-1)] < height {
                                left = true
                                lower_neighbours += 1
                            }
                        }
                        if j < m_iSize-1 {
                            if map[computeIndex(i, j+1)] < height {
                                right = true
                                lower_neighbours += 1
                            }
                        }
                        
                        if lower_neighbours > 0 {
                            let material_part = material / Double(lower_neighbours)
                            
                            if up {
                                map[computeIndex(i-1, j)] += material_part
                            }
                            if down {
                                map[computeIndex(i+1, j)] += material_part
                            }
                            if left {
                                map[computeIndex(i, j-1)] += material_part
                            }
                            if right {
                                map[computeIndex(i, j+1)] += material_part
                            }
                            
                            map[computeIndex(i, j)] -= material
                        }
                    }
                }
            }
        }
    }
    
    public func makeHydraulicErosion(water: Double, sediment: Double, evaporation: Double, capacity: Double, iterations: Int) {
        var watermap = Array(repeating: Double(0), count: m_iSize2)
        var sedimentmap = Array(repeating: Double(0), count: m_iSize2)
        
        for _ in 0..<iterations {
            //1. Generate new water
            for i in 0..<m_iSize2 {
                watermap[i] += water
            }
            
            //2. Convert height material to sediment proportional to water
            for i in 0..<m_iSize2 {
                var amount = watermap[i] * sediment
                // if more sediment should be generated as height, only use height
                if amount > map[i] {
                    amount = map[i]
                }
                map[i] -= amount
                sedimentmap[i] += amount
            }
            
            //3. Water and sediment distributing to neighbour cells
            for i in 0..<m_iSize {
                for j in 0..<m_iSize {
                    let height = map[computeIndex(i, j)]
                    let water = watermap[computeIndex(i, j)]
                    
                    let a = height + water
                    var a_average = a
                    
                    // count neighbours
                    // use Von Neumann neighbourhood
                    var lower_neighbours = 0
                    var up = false
                    var down = false
                    var left = false
                    var right = false
                    var d1: Double = 0.0
                    var d2: Double = 0.0
                    var d3: Double = 0.0
                    var d4: Double = 0.0
                    
                    // up
                    if i > 0 {
                        d1 = a - (map[computeIndex(i-1, j)] + watermap[computeIndex(i-1, j)])
                        if d1 > 0.0 {
                            a_average += map[computeIndex(i-1, j)] + watermap[computeIndex(i-1, j)]
                            up = true
                            lower_neighbours += 1
                        }
                    }
                    
                    // down
                    if i < m_iSize-1 {
                        d2 = a - (map[computeIndex(i+1, j)] + watermap[computeIndex(i+1, j)])
                        if d2 > 0.0 {
                            a_average += map[computeIndex(i+1, j)] + watermap[computeIndex(i+1, j)]
                            down = true
                            lower_neighbours += 1
                        }
                    }
                    
                    // left
                    if j > 0 {
                        d3 = a - (map[computeIndex(i, j-1)] + watermap[computeIndex(i, j-1)])
                        if d3 > 0.0 {
                            a_average += map[computeIndex(i, j-1)] + watermap[computeIndex(i, j-1)]
                            left = true
                            lower_neighbours += 1
                        }
                    }
                    
                    // right
                    if j < m_iSize-1 {
                        d4 = a - (map[computeIndex(i, j+1)] + watermap[computeIndex(i, j+1)])
                        if d4 > 0.0 {
                            a_average += map[computeIndex(i, j+1)] + watermap[computeIndex(i, j+1)]
                            right = true
                            lower_neighbours += 1
                        }
                    }
                    
                    // move water only if there are lower_neighbours
                    if lower_neighbours > 0 {
                        a_average =  a_average / Double(lower_neighbours + 1)
                        
                        // part of the water moves
                        var d_total = 0.0
                        var water_sum = 0.0
                        var water_part = 0.0
                        var sediment_to_move = 0.0
                        var sediment_part = 0.0
                        
                        let a_delta = a - a_average
                        
                        d_total += d1 > 0.0 ? d1 : 0
                        d_total += d2 > 0.0 ? d2 : 0
                        d_total += d3 > 0.0 ? d3 : 0
                        d_total += d4 > 0.0 ? d4 : 0
                        
                        if up {
                            water_part = min(water, a_delta) * (d1 / d_total)
                            water_sum += water_part
                            sediment_part = sedimentmap[computeIndex(i,j)] * (water_part / water);
                            watermap[computeIndex(i-1,j)] += water_part;
                            sedimentmap[computeIndex(i-1,j)] += sediment_part;
                            sediment_to_move += sediment_part;
                        }
                        if down {
                            water_part = min(water, a_delta) * (d2 / d_total);
                            water_sum += water_part;
                            sediment_part = sedimentmap[computeIndex(i,j)] * (water_part / water);
                            watermap[computeIndex(i+1,j)] += water_part;
                            sedimentmap[computeIndex(i+1,j)] += sediment_part;
                            sediment_to_move += sediment_part;
                        }
                        if left {
                            water_part = min(water, a_delta) * (d3 / d_total);
                            water_sum += water_part;
                            sediment_part = sedimentmap[computeIndex(i,j)] * (water_part / water);
                            watermap[computeIndex(i,j-1)] += water_part;
                            sedimentmap[computeIndex(i,j-1)] += sediment_part;
                            sediment_to_move += sediment_part;
                        }
                        if right {
                            water_part = min(water, a_delta) * (d4 / d_total);
                            water_sum += water_part;
                            sediment_part = sedimentmap[computeIndex(i,j)] * (water_part / water);
                            watermap[computeIndex(i,j+1)] += water_part;
                            sedimentmap[computeIndex(i,j+1)] += sediment_part;
                            sediment_to_move += sediment_part;
                        }
                        
                        if water_sum > watermap[computeIndex(i,j)] {
                            water_sum = watermap[computeIndex(i,j)];
                        }
                        watermap[computeIndex(i,j)] -= water_sum;
                        sedimentmap[computeIndex(i,j)] -= sediment_to_move;
                        if sedimentmap[computeIndex(i,j)] < 0.0 {
                            sedimentmap[computeIndex(i,j)] = 0.0;
                        }
                    }
                }
            }
            
            //4. Evaporate water
            for i in 0..<m_iSize2 {
                if watermap[i] < 0.0 {
                    watermap[i] = 0.0
                }
                
                // evaporation of water
                watermap[i] = watermap[i] * (1.0 - evaporation);
                
                // maximum amount sediment can be carried by water
                let sediment_max = capacity * watermap[i];
                
                // if it is too much sediment --> move back to heightmap
                var sediment_overhead = max(0.0, sedimentmap[i] - sediment_max);
                if sediment_overhead > sedimentmap[i] {
                    sediment_overhead = sedimentmap[i];
                }
                sedimentmap[i] -= sediment_overhead;
                map[i] += sediment_overhead;
            }
        }
            // now write sediments back to heightmap
        for i in 0 ..< m_iSize2 {
            map[i] += sedimentmap[i];
        }
    }
}

// MARK: Helpers
extension Terrain {

    func filterFIR(pos : Int, ofs : Int, filter : Double)
    {
        var v = map[pos];
        var b = pos + ofs
        let ifilter = 1.0 - filter
        
        for _ in 0 ..< m_iSizeMask {
            map[b] = filter * v + ifilter + map[b]
            v = map[b]
            b += ofs
        }
    }

    func filterTerrain( filter : Double )
    {
        // filter the rows from left to right and vice versa
        for i in 0 ..< mapSize {
            filterFIR( pos: m_iSize * i, ofs: 1, filter: filter);
            filterFIR( pos: m_iSize * i + m_iSize - 1, ofs: -1, filter: filter );
        }
        
        // filter the columns from top to bottom and vice versa
        for i in 0 ..< mapSize {
            filterFIR( pos: i, ofs: m_iSize, filter: filter );
            filterFIR( pos: m_iSize * ( m_iSize - 1 ) + i, ofs: -m_iSize, filter: filter );
        }
    }

    
    func normalize() {
        var minHeight: Double
        var maxHeight: Double
 
        minHeight = map[0]
        maxHeight = map[0]
        
        // Find minima and maxima
        for i in 1..<m_iSize2 {
            if map[i] < minHeight {
                minHeight = map[i]
            } else if map[i] > maxHeight {
                maxHeight = map[i]
            }
        }
        
        // and scale landscape accordingly
        let scale = 1.0 / (maxHeight - minHeight)
        
        for i in 0..<m_iSize2 {
            map[i] = max( 0.3, (map[i] - minHeight) * scale)
        }
    }

    func computeIndex(_ a : Int, _ b : Int) -> Int
    {
        if a < 0 || b < 0 || a >= mapSize || a >= mapSize {
            print( "range error in computeIndex" )
            return 0
        } else {
            return a + b * mapSize
        }
    }
}
