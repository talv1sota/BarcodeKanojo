// RotationContext.swift — Context for rotation deformers
// Ported from live2d-v2/live2d/core/deformer/rotation_context.py

import Foundation

final class RotationContext: DeformerContext {
    var tmpDeformerIndex: Int = Deformer.DEFORMER_INDEX_NOT_INIT
    var interpolatedAffine: AffineEnt?
    var transformedAffine: AffineEnt?

    override init(_ deformer: Deformer) {
        super.init(deformer)
    }
}
