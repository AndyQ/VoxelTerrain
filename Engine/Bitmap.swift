//
//  Bitmap.swift
//  Voxel
//
// Parts of this are based on Nick Lockwoods RetroRampage series
// https://github.com/nicklockwood/RetroRampage
//

public struct Bitmap {
    public var pixels: [Color]
    public let width: Int
    
    public init(width: Int, pixels: [Color]) {
        self.width = width
        self.pixels = pixels
    }
}

public extension Bitmap {
    var height: Int {
        return pixels.count / width
    }
    
    subscript(x: Int, y: Int) -> Color {
        get { return pixels[y * width + x] }
        set {
            guard x >= 0, y >= 0, x < width, y < height else { return }
            pixels[y * width + x] = newValue
        }
    }
    
    init(width: Int, height: Int, color: Color) {
        self.pixels = Array(repeating: color, count: width * height)
        self.width = width
    }
    
    mutating func fill(color: Color) {
        self.pixels = self.pixels.map { _ in color }
    }

}
