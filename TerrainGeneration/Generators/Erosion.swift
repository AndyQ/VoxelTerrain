//
//  Erode.swift
//  HeightmapGenerator
//
//  Created by Andy Qua on 08/01/2023.
//

import Foundation


public class Erosion {
    
    var seed:  Int = 0
    
    var erosionRadius : Int = 3  // Range 2 - 8
    
    // 0 - 1
    var inertia : Double = 0.05 // At zero, water will instantly change direction to flow downhill. At 1, water will never change direction.
    var sedimentCapacityFactor : Double = 4 // Multiplier for how much sediment a droplet can carry
    var minSedimentCapacity : Double = 0.01 // Used to prevent carry capacity getting too close to zero on flatter terrain

    var erodeSpeed : Double = 0.03 // 0 - 1
    var depositSpeed : Double = 0.3 // 0 - 1
    var evaporateSpeed : Double = 0.01 // 0 - 1
    var gravity : Double = 4
    var maxDropletLifetime : Int = 30
    
    var initialWaterVolume : Double = 1
    var initialSpeed : Double = 1
    
    // Indices and weights of erosion brush precomputed for every node
    var erosionBrushIndices : [[Int]] = []
    var erosionBrushWeights : [[Double]] = []
    
    var currentSeed : Int = 0
    var currentErosionRadius : Int = 0
    var currentMapSize : Int = 0
    
    init() {
        
    }
    
    // Initialization creates a Random object and precomputes indices and weights of erosion brush
    func setup( mapSize : Int,  resetSeed : Bool) {
        if (resetSeed || currentSeed != seed) {
            currentSeed = seed
        }
        
        if erosionBrushIndices.count == 0 || currentErosionRadius != erosionRadius || currentMapSize != mapSize {
            initializeBrushIndices(mapSize:mapSize, radius:erosionRadius)
            currentErosionRadius = erosionRadius
            currentMapSize = mapSize
        }
    }
    
    func erode ( hm : [Double], mapSize : Int, numIterations : Int = 1, resetSeed : Bool = false) -> [Double] {
        setup(mapSize: mapSize, resetSeed: resetSeed)
        
        var map = hm
        
        for _ in 0 ..< numIterations {
            // Create water droplet at random point on map
            var posX : Double = randomDouble( in:0 ... Double(mapSize - 1))
            var posY : Double = randomDouble( in:0 ... Double(mapSize - 1))
            var dirX : Double = 0
            var dirY : Double = 0
            var speed : Double = initialSpeed
            var water : Double = initialWaterVolume
            var sediment : Double = 0
            
            for _ in 0 ..< maxDropletLifetime {
                let nodeX : Int = Int(posX)
                let nodeY : Int = Int(posY)
                let dropletIndex : Int = nodeY * mapSize + nodeX
                // Calculate droplet's offset inside the cell (0,0) = at NW node, (1,1) = at SE node
                let cellOffsetX : Double = posX - Double(nodeX)
                let cellOffsetY : Double = posY - Double(nodeY)
                
                // Calculate droplet's height and direction of flow with bilinear interpolation of surrounding heights
                let heightAndGradient : HeightAndGradient = calculateHeightAndGradient(map: map, mapSize: mapSize, x: posX, y:posY)
                
                // Update the droplet's direction and position (move position 1 unit regardless of speed)
                dirX = (dirX * inertia - heightAndGradient.gradientX * (1 - inertia))
                dirY = (dirY * inertia - heightAndGradient.gradientY * (1 - inertia))
                // Normalize direction
                let len = sqrt(dirX * dirX + dirY * dirY)
                if len != 0 {
                    dirX /= len
                    dirY /= len
                }
                posX += dirX
                posY += dirY
                
                if posX.isNaN || posY.isNaN {
                    break
                }
                // Stop simulating droplet if it's not moving or has flowed over edge of map
                if (dirX == 0 && dirY == 0) || posX < 0 || posX >= Double(mapSize - 1) || posY < 0 || posY >= Double(mapSize) - 1 {
                    break
                }
                
                // Find the droplet's new height and calculate the deltaHeight
                let newHeight : Double = calculateHeightAndGradient(map: map, mapSize: mapSize, x: posX, y: posY).height
                let deltaHeight : Double = newHeight - heightAndGradient.height
                
                // Calculate the droplet's sediment capacity (higher when moving fast down a slope and contains lots of water)
                let sedimentCapacity : Double = max(-deltaHeight * speed * water * sedimentCapacityFactor, minSedimentCapacity)
                
                // If carrying more sediment than capacity, or if flowing uphill:
                if sediment > sedimentCapacity || deltaHeight > 0 {
                    // If moving uphill (deltaHeight > 0) try fill up to the current height, otherwise deposit a fraction of the excess sediment
                    let amountToDeposit : Double = (deltaHeight > 0) ? min(deltaHeight, sediment) : (sediment - sedimentCapacity) * depositSpeed
                    sediment -= amountToDeposit
                    
                    // Add the sediment to the four nodes of the current cell using bilinear interpolation
                    // Deposition is not distributed over a radius (like erosion) so that it can fill small pits
                    
                    map[dropletIndex] += amountToDeposit * (1 - cellOffsetX) * (1 - cellOffsetY)
                    map[dropletIndex + 1] += amountToDeposit * cellOffsetX * (1 - cellOffsetY)
                    map[dropletIndex + mapSize] += amountToDeposit * (1 - cellOffsetX) * cellOffsetY
                    map[dropletIndex + mapSize + 1] += amountToDeposit * cellOffsetX * cellOffsetY
                    
                } else {
                    // Erode a fraction of the droplet's current carry capacity.
                    // Clamp the erosion to the change in height so that it doesn't dig a hole in the terrain behind the droplet
                    let amountToErode : Double = min((sedimentCapacity - sediment) * erodeSpeed, -deltaHeight)
                    
                    // Use erosion brush to erode from all nodes inside the droplet's erosion radius
                    for brushPointIndex in 0 ..< erosionBrushIndices[dropletIndex].count {
                        let nodeIndex : Int = erosionBrushIndices[dropletIndex][brushPointIndex]
                        let weighedErodeAmount : Double = amountToErode * erosionBrushWeights[dropletIndex][brushPointIndex]
                        let deltaSediment : Double = (map[nodeIndex] < weighedErodeAmount) ? map[nodeIndex] : weighedErodeAmount
                        map[nodeIndex] -= deltaSediment
                        
                        sediment += deltaSediment
                    }
                }
                
                // Update droplet's speed and water content
                let os = speed
                speed = sqrt(speed * speed + deltaHeight * gravity)
                if speed.isNaN {
                    speed = os
                }
                water *= (1 - evaporateSpeed)
            }
        }
        
        return map
    }
    
    func calculateHeightAndGradient(map nodes : [Double], mapSize : Int, x posX : Double, y posY : Double ) -> HeightAndGradient {
        let coordX : Int = Int(posX)
        let coordY : Int = Int(posY)
        
        // Calculate droplet's offset inside the cell (0,0) = at NW node, (1,1) = at SE node
        let x : Double = posX - Double(coordX)
        let y : Double = posY - Double(coordY)
        
        // Calculate heights of the four nodes of the droplet's cell
        let nodeIndexNW : Int = coordY * mapSize + coordX
        let heightNW : Double = nodes[nodeIndexNW]
        let heightNE : Double = nodes[nodeIndexNW + 1]
        let heightSW : Double = nodes[nodeIndexNW + mapSize]
        let heightSE : Double = nodes[nodeIndexNW + mapSize + 1]
        
        // Calculate droplet's direction of flow with bilinear interpolation of height difference along the edges
        let gradientX : Double = (heightNE - heightNW) * (1 - y) + (heightSE - heightSW) * y
        let gradientY : Double = (heightSW - heightNW) * (1 - x) + (heightSE - heightNE) * x
        
        // Calculate height with bilinear interpolation of the heights of the nodes of the cell
        let height : Double = heightNW * (1 - x) * (1 - y) + heightNE * x * (1 - y) + heightSW * (1 - x) * y + heightSE * x * y
        
        return HeightAndGradient(height: height, gradientX: gradientX, gradientY: gradientY )
    }
    
    func initializeBrushIndices( mapSize : Int,  radius : Int ) {
        erosionBrushIndices = [[Int]](repeating:[], count:mapSize * mapSize)
        erosionBrushWeights = [[Double]](repeating:[], count:mapSize * mapSize)
        
        var xOffsets : [Int] = [Int](repeating:0, count:radius * radius * 4)
        var yOffsets : [Int] = [Int](repeating:0, count:radius * radius * 4)
        var weights : [Double] = [Double](repeating:0, count:radius * radius * 4)
        var weightSum : Double = 0
        var addIndex : Int = 0
        
        for i in 0 ..< erosionBrushIndices.count {
            let centreX : Int = i % mapSize
            let centreY : Int = i / mapSize
            
            if centreY <= radius || centreY >= mapSize - radius || centreX <= radius + 1 || centreX >= mapSize - radius {
                weightSum = 0
                addIndex = 0
                for y in -radius ..< radius {
                    for x in -radius ..< radius {
                        let sqrDst : Double = Double(x * x + y * y)
                        if sqrDst < Double(radius * radius) {
                            let coordX : Int = centreX + x
                            let coordY : Int = centreY + y
                            
                            if coordX >= 0 && coordX < mapSize && coordY >= 0 && coordY < mapSize {
                                let weight : Double = 1 - sqrt(sqrDst) / Double(radius)
                                weightSum += weight
                                weights[addIndex] = weight
                                xOffsets[addIndex] = x
                                yOffsets[addIndex] = y
                                addIndex += 1
                            }
                        }
                    }
                }
            }
            
            let numEntries : Int = addIndex
            erosionBrushIndices[i] = [Int](repeating:0, count:numEntries)
            erosionBrushWeights[i] = [Double](repeating:0, count:numEntries)
            
            for j in 0 ..< numEntries {
                erosionBrushIndices[i][j] = (yOffsets[j] + centreY) * mapSize + xOffsets[j] + centreX
                erosionBrushWeights[i][j] = weights[j] / weightSum
            }
        }
    }
    
    struct HeightAndGradient {
        var height : Double
        var gradientX : Double
        var gradientY : Double
    }
}
