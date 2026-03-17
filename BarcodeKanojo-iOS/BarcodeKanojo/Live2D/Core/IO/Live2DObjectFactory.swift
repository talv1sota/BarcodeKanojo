// Live2DObjectFactory.swift — Factory for binary-deserialized objects
// Ported from live2d-v2/live2d/core/io/live2d_object_factory.py

import Foundation

/// Protocol for all Live2D serializable objects
protocol Live2DSerializable: AnyObject {
    func read(_ br: BinaryReader)
}

final class Live2DObjectFactory {
    static func create(_ classNo: Int) -> Live2DSerializable {
        if classNo < 100 {
            switch classNo {
            case 65: return WarpDeformer()
            case 66: return PivotManager()
            case 67: return ParamPivots()
            case 68: return RotationDeformer()
            case 69: return AffineEnt()
            case 70: return Mesh()
            default: break
            }
        } else if classNo < 150 {
            switch classNo {
            case 131: return ParamDefFloat()
            case 133: return PartsData()
            case 136: return ModelImpl()
            case 137: return ParamDefSet()
            case 142: return Avatar()
            default: break
            }
        }
        fatalError("Unknown class ID: \(classNo)")
    }
}
