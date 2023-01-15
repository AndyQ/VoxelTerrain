//
//  Vector2.swift
//  HeightmapGenerator
//
//  Created by Andy Qua on 08/01/2023.
//

import Foundation


import Foundation

// MARK: Types

public typealias Scalar = Double

public struct Vector2: Hashable {
    public var x: Scalar
    public var y: Scalar
}

// MARK: Scalar

public extension Scalar {
    static let halfPi = pi / 2
    static let quarterPi = pi / 4
    static let twoPi = pi * 2
    static let degreesPerRadian = 180 / pi
    static let radiansPerDegree = pi / 180
    static let epsilon: Scalar = 0.0001
    
    static func ~= (lhs: Scalar, rhs: Scalar) -> Bool {
        return Swift.abs(lhs - rhs) < .epsilon
    }
    
    fileprivate var sign: Scalar {
        return self > 0 ? 1 : -1
    }
}

// MARK: Vector2

public extension Vector2 {
    static let zero = Vector2(0, 0)
    static let x = Vector2(1, 0)
    static let y = Vector2(0, 1)
    
    var lengthSquared: Scalar {
        return x * x + y * y
    }
    
    var length: Scalar {
        return sqrt(lengthSquared)
    }
    
    var inverse: Vector2 {
        return -self
    }
    
    init(_ x: Scalar, _ y: Scalar) {
        self.init(x: x, y: y)
    }
    
    init(_ x: Int, _ y: Int) {
        self.init(x: Scalar(x), y: Scalar(y))
    }
    
    init(_ v: Scalar) {
        self.init(x: v, y: v)
    }
    
    init(_ v: Int) {
        self.init(x: Scalar(v), y: Scalar(v))
    }
    
    init(_ v: [Scalar]) {
        assert(v.count == 2, "array must contain 2 elements, contained \(v.count)")
        self.init(v[0], v[1])
    }
    
    func toArray() -> [Scalar] {
        return [x, y]
    }
    
    func dot(_ v: Vector2) -> Scalar {
        return x * v.x + y * v.y
    }
    
    func cross(_ v: Vector2) -> Scalar {
        return x * v.y - y * v.x
    }
    
    func normalized() -> Vector2 {
        let lengthSquared = self.lengthSquared
        if lengthSquared ~= 0 || lengthSquared ~= 1 {
            return self
        }
        return self / sqrt(lengthSquared)
    }
    
    func rotated(by radians: Scalar) -> Vector2 {
        let cs = cos(radians)
        let sn = sin(radians)
        return Vector2(x * cs - y * sn, x * sn + y * cs)
    }
    
    func rotated(by radians: Scalar, around pivot: Vector2) -> Vector2 {
        return (self - pivot).rotated(by: radians) + pivot
    }
    
    func angle(with v: Vector2) -> Scalar {
        if self == v {
            return 0
        }
        
        let t1 = normalized()
        let t2 = v.normalized()
        let cross = t1.cross(t2)
        let dot = max(-1, min(1, t1.dot(t2)))
        
        return atan2(cross, dot)
    }
    
    func interpolated(with v: Vector2, by t: Scalar) -> Vector2 {
        return self + (v - self) * t
    }
    
    static prefix func - (v: Vector2) -> Vector2 {
        return Vector2(-v.x, -v.y)
    }
    
    static func + (lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.x + rhs.x, lhs.y + rhs.y)
    }
    
    static func - (lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.x - rhs.x, lhs.y - rhs.y)
    }
    
    static func * (lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.x * rhs.x, lhs.y * rhs.y)
    }
    
    static func * (lhs: Vector2, rhs: Scalar) -> Vector2 {
        return Vector2(lhs.x * rhs, lhs.y * rhs)
    }
        
    static func / (lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.x / rhs.x, lhs.y / rhs.y)
    }
    
    static func / (lhs: Vector2, rhs: Scalar) -> Vector2 {
        return Vector2(lhs.x / rhs, lhs.y / rhs)
    }
    
    static func ~= (lhs: Vector2, rhs: Vector2) -> Bool {
        return lhs.x ~= rhs.x && lhs.y ~= rhs.y
    }
}
