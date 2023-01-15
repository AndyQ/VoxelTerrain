//
//  Utils.swift
//  Engine
//
//  Created by Andy Qua on 27/12/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import Foundation

public func deg2rad(_ number: Int) -> Double {
    return Double(number) * .pi / 180
}

public func rad2deg(_ number: Double) -> Double {
    return number * 180 / .pi
}

public func blendColor(_ c1 : Int, _ c2 : Int, _ factor : Int) -> Int {
    return ( ( ( (c1 & 0xFF00FF) * (256 - factor) + (c2 & 0xFF00FF) * factor ) & 0xFF00FF00)  | (( (c1 & 0x00FF00) * (256-factor) + (c2 & 0x00FF00) * factor) & 0x00FF0000 ) ) >> 8;
}
