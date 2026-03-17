// PartsDataContext.swift — Context for a parts data entry
// Ported from live2d-v2/live2d/core/model/parts_context.py

import Foundation

final class PartsDataContext {
    var partsOpacity: Float = 0
    weak var partsData: PartsData?
    var screenColor: [Float] = [0, 0, 0, 0]
    var multiplyColor: [Float] = [1, 1, 1, 0]

    init(_ parts: PartsData) {
        self.partsData = parts
    }

    func getPartsOpacity() -> Float { partsOpacity }
    func setPartsOpacity(_ value: Float) { partsOpacity = value }

    func setPartScreenColor(_ r: Float, _ g: Float, _ b: Float, _ a: Float) {
        screenColor[0] = r; screenColor[1] = g; screenColor[2] = b; screenColor[3] = a
    }

    func setPartMultiplyColor(_ r: Float, _ g: Float, _ b: Float, _ a: Float) {
        multiplyColor[0] = r; multiplyColor[1] = g; multiplyColor[2] = b; multiplyColor[3] = a
    }
}
