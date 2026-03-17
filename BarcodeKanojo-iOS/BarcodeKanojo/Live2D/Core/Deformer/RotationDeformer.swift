// RotationDeformer.swift — Rotation deformer with affine transform interpolation
// Ported from live2d-v2/live2d/core/deformer/roation_deformer.py

import Foundation

final class RotationDeformer: Deformer {
    // Scratch buffers (static to avoid allocation)
    private static var temp1: [Float] = [0, 0]
    private static var temp2: [Float] = [0, 0]
    private static var temp3: [Float] = [0, 0]
    private static var temp4: [Float] = [0, 0]
    private static var temp5: [Float] = [0, 0]
    private static var temp6: [Float] = [0, 0]
    private static var paramOutsideFlag: [Bool] = [false]

    var pivotManager: PivotManager?
    var affines: [AffineEnt]?

    override func getType() -> Int { Deformer.TYPE_ROTATION }

    override func read(_ br: BinaryReader) {
        super.read(br)
        pivotManager = br.readObject() as? PivotManager
        // readObject returns [Any?] for generic arrays (type 15); cast each element
        if let rawArray = br.readObject() as? [Any?] {
            affines = rawArray.compactMap { $0 as? AffineEnt }
        }
        readOpacity(br)
    }

    override func initContext(_ mc: ModelContext) -> DeformerContext {
        let rctx = RotationContext(self)
        rctx.interpolatedAffine = AffineEnt()
        if needTransform() {
            rctx.transformedAffine = AffineEnt()
        }
        return rctx
    }

    override func setupInterpolate(_ mc: ModelContext, _ dc: DeformerContext) {
        guard let rctx = dc as? RotationContext else { return }
        guard let pm = pivotManager, let affs = affines else { return }

        if !pm.checkParamUpdated(mc) { return }

        var success = RotationDeformer.paramOutsideFlag
        success[0] = false
        let numInterp = pm.calcPivotValues(mc, &success)
        rctx.setOutsideParam(success[0])
        interpolateOpacity(mc, pm, rctx, &success)

        var indices = mc.getTempPivotTableIndices()
        var tArr = mc.getTempT()
        pm.calcPivotIndices(&indices, &tArr, numInterp)
        mc.setTempPivotTableIndices(indices)
        mc.setTempT(tArr)

        guard let interpAffine = rctx.interpolatedAffine else { return }

        if numInterp <= 0 {
            interpAffine.initFrom(affs[Int(indices[0])])
        } else if numInterp == 1 {
            let a = affs[Int(indices[0])]
            let b = affs[Int(indices[1])]
            let t = tArr[0]
            interpAffine.originX = a.originX + (b.originX - a.originX) * t
            interpAffine.originY = a.originY + (b.originY - a.originY) * t
            interpAffine.scaleX = a.scaleX + (b.scaleX - a.scaleX) * t
            interpAffine.scaleY = a.scaleY + (b.scaleY - a.scaleY) * t
            interpAffine.rotationDeg = a.rotationDeg + (b.rotationDeg - a.rotationDeg) * t
        } else if numInterp == 2 {
            let a = affs[Int(indices[0])]; let b = affs[Int(indices[1])]
            let c = affs[Int(indices[2])]; let d = affs[Int(indices[3])]
            let t0 = tArr[0]; let t1 = tArr[1]
            func lerp2(_ v00: Float, _ v10: Float, _ v01: Float, _ v11: Float) -> Float {
                let top = v00 + (v10 - v00) * t0
                let bot = v01 + (v11 - v01) * t0
                return top + (bot - top) * t1
            }
            interpAffine.originX = lerp2(a.originX, b.originX, c.originX, d.originX)
            interpAffine.originY = lerp2(a.originY, b.originY, c.originY, d.originY)
            interpAffine.scaleX = lerp2(a.scaleX, b.scaleX, c.scaleX, d.scaleX)
            interpAffine.scaleY = lerp2(a.scaleY, b.scaleY, c.scaleY, d.scaleY)
            interpAffine.rotationDeg = lerp2(a.rotationDeg, b.rotationDeg, c.rotationDeg, d.rotationDeg)
        } else {
            // Generic N-level interpolation for 3+ params
            let count = 1 << numInterp
            var weights = [Float](repeating: 0, count: count)
            for i in 0..<count {
                var idx = Float(i); var w: Float = 1
                for l in 0..<numInterp {
                    w *= (Int(idx) % 2 == 0) ? (1 - tArr[l]) : tArr[l]
                    idx /= 2
                }
                weights[i] = w
            }
            var ox: Float = 0, oy: Float = 0, sx: Float = 0, sy: Float = 0, rot: Float = 0
            for i in 0..<count {
                let af = affs[Int(indices[i])]
                ox += weights[i] * af.originX
                oy += weights[i] * af.originY
                sx += weights[i] * af.scaleX
                sy += weights[i] * af.scaleY
                rot += weights[i] * af.rotationDeg
            }
            interpAffine.originX = ox; interpAffine.originY = oy
            interpAffine.scaleX = sx; interpAffine.scaleY = sy
            interpAffine.rotationDeg = rot
        }

        // Copy reflect from first affine
        let first = affs[Int(indices[0])]
        interpAffine.reflectX = first.reflectX
        interpAffine.reflectY = first.reflectY
    }

    override func setupTransform(_ mc: ModelContext, _ dc: DeformerContext) -> Bool {
        guard let rctx = dc as? RotationContext else { return false }

        rctx.setAvailable(true)
        if !needTransform() {
            rctx.setTotalScale_notForClient(rctx.interpolatedAffine?.scaleX ?? 1)
            rctx.setTotalOpacity(rctx.getInterpolatedOpacity())
        } else {
            guard let targetId = getTargetId() else { rctx.setAvailable(false); return false }
            if rctx.tmpDeformerIndex == Deformer.DEFORMER_INDEX_NOT_INIT {
                rctx.tmpDeformerIndex = mc.getDeformerIndex(targetId)
            }
            if rctx.tmpDeformerIndex < 0 {
                print("deformer is not reachable")
                rctx.setAvailable(false)
            } else {
                let deformer = mc.getDeformer(rctx.tmpDeformerIndex)
                let dctx = mc.getDeformerContext(rctx.tmpDeformerIndex)
                if let deformer = deformer {
                    var srcPt = RotationDeformer.temp1
                    srcPt[0] = rctx.interpolatedAffine?.originX ?? 0
                    srcPt[1] = rctx.interpolatedAffine?.originY ?? 0

                    var dirPt = RotationDeformer.temp2
                    dirPt[0] = 0
                    dirPt[1] = dctx.getDeformer().getType() == Deformer.TYPE_ROTATION ? -10 : -0.1

                    var retDir = RotationDeformer.temp3
                    RotationDeformer.getDirectionOnDst(mc, deformer, dctx, srcPt, dirPt, &retDir)
                    let angleP = UtMath.getAngleNotAbs(dirPt, retDir)

                    var transformedSrc = srcPt
                    deformer.transformPoints(mc, dctx, srcPt, &transformedSrc, 1, 0, 2)

                    rctx.transformedAffine?.originX = transformedSrc[0]
                    rctx.transformedAffine?.originY = transformedSrc[1]
                    rctx.transformedAffine?.scaleX = rctx.interpolatedAffine?.scaleX ?? 1
                    rctx.transformedAffine?.scaleY = rctx.interpolatedAffine?.scaleY ?? 1
                    rctx.transformedAffine?.rotationDeg = (rctx.interpolatedAffine?.rotationDeg ?? 0)
                        - angleP * UtMath.RAD_TO_DEG

                    let parentScale = dctx.getTotalScale()
                    rctx.setTotalScale_notForClient(parentScale * (rctx.transformedAffine?.scaleX ?? 1))
                    let parentOpacity = dctx.getTotalOpacity()
                    rctx.setTotalOpacity(parentOpacity * rctx.getInterpolatedOpacity())

                    rctx.transformedAffine?.reflectX = rctx.interpolatedAffine?.reflectX ?? false
                    rctx.transformedAffine?.reflectY = rctx.interpolatedAffine?.reflectY ?? false
                    rctx.setAvailable(dctx.isAvailable())
                } else {
                    rctx.setAvailable(false)
                }
            }
        }
        return true
    }

    override func transformPoints(_ mc: ModelContext, _ dc: DeformerContext,
                                  _ srcPoints: [Float], _ dstPoints: inout [Float],
                                  _ numPoint: Int, _ ptOffset: Int, _ ptStep: Int) {
        guard let rctx = dc as? RotationContext else { return }
        let affine = rctx.transformedAffine ?? rctx.interpolatedAffine!
        let sinVal = sin(UtMath.DEG_TO_RAD * affine.rotationDeg)
        let cosVal = cos(UtMath.DEG_TO_RAD * affine.rotationDeg)
        let scale = rctx.getTotalScale()
        let rx: Float = affine.reflectX ? -1 : 1
        let ry: Float = affine.reflectY ? -1 : 1
        let m00 = cosVal * scale * rx
        let m01 = -sinVal * scale * ry
        let m10 = sinVal * scale * rx
        let m11 = cosVal * scale * ry
        let tx = affine.originX
        let ty = affine.originY

        let end = numPoint * ptStep
        var k = ptOffset
        while k < end {
            let x = srcPoints[k]
            let y = srcPoints[k + 1]
            dstPoints[k] = m00 * x + m01 * y + tx
            dstPoints[k + 1] = m10 * x + m11 * y + ty
            k += ptStep
        }
    }

    static func getDirectionOnDst(_ mc: ModelContext, _ targetDeformer: Deformer,
                                  _ targetCtx: DeformerContext,
                                  _ srcOrigin: [Float], _ srcDir: [Float],
                                  _ retDir: inout [Float]) {
        var transformedOrigin = temp4
        transformedOrigin[0] = srcOrigin[0]
        transformedOrigin[1] = srcOrigin[1]
        targetDeformer.transformPoints(mc, targetCtx, transformedOrigin, &transformedOrigin, 1, 0, 2)

        var scale: Float = 1
        for _ in 0..<10 {
            var testPt = temp6
            testPt[0] = srcOrigin[0] + scale * srcDir[0]
            testPt[1] = srcOrigin[1] + scale * srcDir[1]
            var result = temp5
            targetDeformer.transformPoints(mc, targetCtx, testPt, &result, 1, 0, 2)
            result[0] -= transformedOrigin[0]
            result[1] -= transformedOrigin[1]
            if result[0] != 0 || result[1] != 0 {
                retDir[0] = result[0]
                retDir[1] = result[1]
                return
            }
            // Try opposite direction
            testPt[0] = srcOrigin[0] - scale * srcDir[0]
            testPt[1] = srcOrigin[1] - scale * srcDir[1]
            targetDeformer.transformPoints(mc, targetCtx, testPt, &result, 1, 0, 2)
            result[0] -= transformedOrigin[0]
            result[1] -= transformedOrigin[1]
            if result[0] != 0 || result[1] != 0 {
                retDir[0] = -result[0]
                retDir[1] = -result[1]
                return
            }
            scale *= 0.1
        }
        print("Invalid state - direction not found")
    }
}
