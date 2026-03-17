// WarpContext.swift — Context for warp deformers
// Ported from live2d-v2/live2d/core/deformer/warp_context.py

import Foundation

final class WarpContext: DeformerContext {
    var tmpDeformerIndex: Int = Deformer.DEFORMER_INDEX_NOT_INIT
    var interpolatedPoints: [Float]?
    var transformedPoints: [Float]?

    override init(_ deformer: Deformer) {
        super.init(deformer)
    }
}
