// AffineEnt.swift — Affine transform entry for rotation deformers
// Ported from live2d-v2/live2d/core/deformer/roation_deformer.py (AffineEnt class)

import Foundation

final class AffineEnt: Live2DSerializable {
    var originX: Float = 0
    var originY: Float = 0
    var scaleX: Float = 1
    var scaleY: Float = 1
    var rotationDeg: Float = 0
    var reflectX: Bool = false
    var reflectY: Bool = false

    func initFrom(_ other: AffineEnt) {
        originX = other.originX
        originY = other.originY
        scaleX = other.scaleX
        scaleY = other.scaleY
        rotationDeg = other.rotationDeg
        reflectX = other.reflectX
        reflectY = other.reflectY
    }

    func read(_ br: BinaryReader) {
        originX = br.readFloat32()
        originY = br.readFloat32()
        scaleX = br.readFloat32()
        scaleY = br.readFloat32()
        rotationDeg = br.readFloat32()
        if br.getFormatVersion() >= Live2DDEF.LIVE2D_FORMAT_VERSION_V2_10_SDK2 {
            reflectX = br.readBoolean()
            reflectY = br.readBoolean()
        }
    }
}
