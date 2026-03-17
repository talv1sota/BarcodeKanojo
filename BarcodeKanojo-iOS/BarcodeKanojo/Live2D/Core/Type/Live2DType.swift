// Live2DType.swift — Array type aliases for Live2D engine
// Ported from live2d-v2/live2d/core/type/array.py
//
// In the Python version these are factory functions returning plain lists.
// In Swift we use typed arrays directly.

import Foundation

typealias Float32Array = [Float]
typealias Float64Array = [Double]
typealias Int32Array = [Int32]
typealias Int16Array = [Int16]
typealias Int8Array = [Int8]

// Generic array for mixed-type containers (mirrors Python's Array(size))
// In Swift we use [Any?] when the container holds heterogeneous objects.
typealias Live2DArray = [Any?]

extension Array where Element == Float {
    /// Create a zero-filled Float array of given size
    static func zeros(_ count: Int) -> [Float] {
        return [Float](repeating: 0.0, count: count)
    }
}

extension Array where Element == Double {
    /// Create a zero-filled Double array of given size
    static func zeros(_ count: Int) -> [Double] {
        return [Double](repeating: 0.0, count: count)
    }
}

extension Array where Element == Int32 {
    /// Create a zero-filled Int32 array of given size
    static func zeros(_ count: Int) -> [Int32] {
        return [Int32](repeating: 0, count: count)
    }
}

extension Array where Element == Int16 {
    /// Create a zero-filled Int16 array of given size
    static func zeros(_ count: Int) -> [Int16] {
        return [Int16](repeating: 0, count: count)
    }
}
