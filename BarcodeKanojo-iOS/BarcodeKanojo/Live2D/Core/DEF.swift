// DEF.swift — Live2D Cubism 2.x constants
// Ported from live2d-v2/live2d/core/DEF.py

import Foundation

enum Live2DDEF {
    // Vertex layout types
    static let VERTEX_TYPE_OFFSET0_STEP2: Int = 1
    static let VERTEX_TYPE_OFFSET2_STEP5: Int = 2

    // Current vertex configuration
    static let VERTEX_OFFSET: Int = 0
    static let VERTEX_STEP: Int = 2
    static let VERTEX_TYPE: Int = VERTEX_TYPE_OFFSET0_STEP2
    // Metal textures have origin at top-left (matching image files).
    // OpenGL textures have origin at bottom-left, needing V-flip.
    // Since we use Metal, do NOT reverse texture T coordinates.
    static let REVERSE_TEXTURE_T: Bool = false

    // Interpolation
    static let MAX_INTERPOLATION: Int = 5
    static let PIVOT_TABLE_SIZE: Int = 65
    static let GOSA: Float = 0.0001

    // Format versions
    static let LIVE2D_FORMAT_VERSION_V2_8_TEX_OPTION: Int = 8
    static let LIVE2D_FORMAT_VERSION_V2_10_SDK2: Int = 10
    static let LIVE2D_FORMAT_VERSION_V2_11_SDK2_1: Int = 11
    static let LIVE2D_FORMAT_VERSION_AVAILABLE: Int = LIVE2D_FORMAT_VERSION_V2_11_SDK2_1

    // Binary reader
    static let OBJECT_REF: Int = 33
}
