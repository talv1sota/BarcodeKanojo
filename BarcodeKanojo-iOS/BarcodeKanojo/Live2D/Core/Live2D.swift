// Live2D.swift — Live2D engine singleton
// Ported from live2d-v2/live2d/core/live2d.py

import Foundation

final class Live2D {
    static var L2D_OUTSIDE_PARAM_AVAILABLE: Bool = false
    static var clippingMaskBufferSize: Int = 256

    private static var firstInit: Bool = true

    static func initialize() {
        if firstInit {
            firstInit = false
        }
    }

    static func dispose() {
        Live2DId.releaseStored()
    }
}
