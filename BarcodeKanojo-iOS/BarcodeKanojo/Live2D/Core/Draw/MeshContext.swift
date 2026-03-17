// MeshContext.swift — Context for mesh rendering
// Ported from live2d-v2/live2d/core/draw/mesh_context.py

import Foundation

final class MeshContext: IDrawContext {
    var tmpDeformerIndex: Int = IDrawData.DEFORMER_INDEX_NOT_INIT
    var interpolatedPoints: [Float]?
    var transformedPoints: [Float]?

    func getTransformedPoints() -> [Float]? {
        return transformedPoints ?? interpolatedPoints
    }
}
