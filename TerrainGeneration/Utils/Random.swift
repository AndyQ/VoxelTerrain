//
//  Random.swift
//  TerrainGeneration
//
//  Created by Andy Qua on 15/01/2023.
//  Copyright © 2023 Andy Qua. All rights reserved.
//

import Foundation
import GameplayKit

struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
    init(seed: Int) { srand48(seed) }
    func setSeed( seed: Int ) {
        srand48(seed)
    }
    func next() -> UInt64 { return UInt64(drand48() * Double(UInt64.max)) }
}

var seededGenerator = RandomNumberGeneratorWithSeed(seed: Int.random(in: Int.min ... Int.max))

public func setRandomSeed( _ seed : Int ) {
    seededGenerator.setSeed(seed: seed)
}

public func randomInt( in range:Range<Int>) -> Int {
    return Int.random(in: range, using: &seededGenerator)
}

public func randomInt( in range:ClosedRange<Int>) -> Int {
    return Int.random(in: range, using: &seededGenerator)
}

func randomDouble( in range:Range<Double>) -> Double {
    return Double.random(in: range, using: &seededGenerator)
}

func randomDouble( in range:ClosedRange<Double>) -> Double {
    return Double.random(in: range, using: &seededGenerator)
}

