// ParamDefFloat.swift — Float parameter definition
// Ported from live2d-v2/live2d/core/param/param_def_float.py

import Foundation

final class ParamDefFloat: Live2DSerializable {
    var minValue: Float = 0
    var maxValue: Float = 0
    var defaultValue: Float = 0
    var paramId: Live2DId?

    func read(_ br: BinaryReader) {
        minValue = br.readFloat32()
        maxValue = br.readFloat32()
        defaultValue = br.readFloat32()
        paramId = br.readObject() as? Live2DId
    }

    func getMinValue() -> Float { minValue }
    func getMaxValue() -> Float { maxValue }
    func getDefaultValue() -> Float { defaultValue }
    func getParamID() -> Live2DId? { paramId }
}
