// DeformerContext.swift — Base context for deformers
// Ported from live2d-v2/live2d/core/deformer/deformer_context.py

import Foundation

class DeformerContext {
    var partsIndex: Int = -1
    var outsideParam: [Bool] = [false]
    var available: Bool = true
    var deformer: Deformer
    var totalScale: Float = 1.0
    var interpolatedOpacity: Float = 1.0
    var totalOpacity: Float = 1.0

    init(_ deformer: Deformer) {
        self.deformer = deformer
    }

    func isAvailable() -> Bool { available && !outsideParam[0] }
    func setAvailable(_ v: Bool) { available = v }
    func getDeformer() -> Deformer { deformer }
    func setPartsIndex(_ idx: Int) { partsIndex = idx }
    func getPartsIndex() -> Int { partsIndex }
    func isOutsideParam() -> Bool { outsideParam[0] }
    func setOutsideParam(_ v: Bool) { outsideParam[0] = v }
    func getTotalScale() -> Float { totalScale }
    func setTotalScale_notForClient(_ v: Float) { totalScale = v }
    func getInterpolatedOpacity() -> Float { interpolatedOpacity }
    func setInterpolatedOpacity(_ v: Float) { interpolatedOpacity = v }
    func getTotalOpacity() -> Float { totalOpacity }
    func setTotalOpacity(_ v: Float) { totalOpacity = v }
}
