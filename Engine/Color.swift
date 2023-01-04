//
//  Color.swift
//  Voxel
//
// Parts of this are based on Nick Lockwoods RetroRampage series
// https://github.com/nicklockwood/RetroRampage
//

public struct Color {
    private var c : UInt32
    
    public init( c : UInt32) {
        self.c = c
    }
    
    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.c = (UInt32(a) << 24) + (UInt32(b) << 16) + (UInt32(g) << 8) + UInt32(r)
    }
    
    public var r : UInt8 {
        return UInt8(c & 0xFF)
    }
    
    public var g : UInt8 {
        return UInt8((c >> 8) & 0xFF)
    }
    
    public var b : UInt8 {
        return UInt8((c >> 16) & 0xFF)
    }
    
    public var a : UInt8 {
        return UInt8((c >> 24) & 0xFF)
    }
    
    public func getInt() -> Int {
        return Int(c)
    }

}

public extension Color {
    static let clear = Color(r: 0, g: 0, b: 0, a: 0)
    static let black = Color(r: 0, g: 0, b: 0)
    static let white = Color(r: 255, g: 255, b: 255)
    static let gray = Color(r: 192, g: 192, b: 192)
    static let red = Color(r: 255, g: 0, b: 0)
    static let green = Color(r: 0, g: 255, b: 0)
    static let blue = Color(r: 0, g: 0, b: 255)
}
