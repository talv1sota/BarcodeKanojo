// UtInterpolate.swift — Multi-level interpolation for pivot values
// Ported from live2d-v2/live2d/core/util/ut_interpolate.py

import Foundation

final class UtInterpolate {

    // MARK: - Int interpolation

    static func interpolateInt(_ mdc: ModelContext, _ pivotMgr: PivotManager,
                               _ ret: inout [Bool], _ pivotValue: [Int32]) -> Int32 {
        let numInterp = pivotMgr.calcPivotValues(mdc, &ret)
        var indices = mdc.getTempPivotTableIndices()
        var tArr = mdc.getTempT()
        pivotMgr.calcPivotIndices(&indices, &tArr, numInterp)
        mdc.setTempPivotTableIndices(indices)
        mdc.setTempT(tArr)

        if numInterp <= 0 {
            return pivotValue[Int(indices[0])]
        } else if numInterp == 1 {
            let v0 = Float(pivotValue[Int(indices[0])])
            let v1 = Float(pivotValue[Int(indices[1])])
            let t = tArr[0]
            return Int32(v0 + (v1 - v0) * t)
        } else if numInterp == 2 {
            let v0 = Float(pivotValue[Int(indices[0])])
            let v1 = Float(pivotValue[Int(indices[1])])
            let v2 = Float(pivotValue[Int(indices[2])])
            let v3 = Float(pivotValue[Int(indices[3])])
            let t0 = tArr[0]
            let t1 = tArr[1]
            let a = Int32(v0 + (v1 - v0) * t0)
            let b = Int32(v2 + (v3 - v2) * t0)
            return Int32(Float(a) + Float(b - a) * t1)
        } else if numInterp == 3 {
            let t0 = tArr[0]; let t1 = tArr[1]; let t2 = tArr[2]
            let p = [0,1,2,3,4,5,6,7].map { Float(pivotValue[Int(indices[$0])]) }
            let a0 = Int32(p[0] + (p[1] - p[0]) * t0)
            let a1 = Int32(p[2] + (p[3] - p[2]) * t0)
            let a2 = Int32(p[4] + (p[5] - p[4]) * t0)
            let a3 = Int32(p[6] + (p[7] - p[6]) * t0)
            let b0 = Int32(Float(a0) + Float(a1 - a0) * t1)
            let b1 = Int32(Float(a2) + Float(a3 - a2) * t1)
            return Int32(Float(b0) + Float(b1 - b0) * t2)
        } else if numInterp == 4 {
            let t0 = tArr[0]; let t1 = tArr[1]; let t2 = tArr[2]; let t3 = tArr[3]
            let p = (0..<16).map { Float(pivotValue[Int(indices[$0])]) }
            var a = [Int32](repeating: 0, count: 8)
            for i in 0..<8 {
                let lo = p[i * 2]
                let hi = p[i * 2 + 1]
                a[i] = Int32(lo + (hi - lo) * t0)
            }
            var b = [Int32](repeating: 0, count: 4)
            for i in 0..<4 {
                let lo = Float(a[i * 2])
                let hi = Float(a[i * 2 + 1])
                b[i] = Int32(lo + (hi - lo) * t1)
            }
            var c = [Int32](repeating: 0, count: 2)
            for i in 0..<2 {
                let lo = Float(b[i * 2])
                let hi = Float(b[i * 2 + 1])
                c[i] = Int32(lo + (hi - lo) * t2)
            }
            return Int32(Float(c[0]) + Float(c[1] - c[0]) * t3)
        } else {
            // Generic N-level interpolation
            let count = 1 << numInterp
            var weights = [Float](repeating: 0, count: count)
            for i in 0..<count {
                var idx = Float(i)
                var w: Float = 1
                for l in 0..<numInterp {
                    w *= (Int(idx) % 2 == 0) ? (1 - tArr[l]) : tArr[l]
                    idx /= 2
                }
                weights[i] = w
            }
            var result: Float = 0
            for i in 0..<count {
                result += weights[i] * Float(pivotValue[Int(indices[i])])
            }
            return Int32(result + 0.5)
        }
    }

    // MARK: - Float interpolation

    static func interpolateFloat(_ mdc: ModelContext, _ pivotMgr: PivotManager,
                                 _ ret: inout [Bool], _ pivotValue: [Float]) -> Float {
        let numInterp = pivotMgr.calcPivotValues(mdc, &ret)
        var indices = mdc.getTempPivotTableIndices()
        var tArr = mdc.getTempT()
        pivotMgr.calcPivotIndices(&indices, &tArr, numInterp)
        mdc.setTempPivotTableIndices(indices)
        mdc.setTempT(tArr)

        if numInterp <= 0 {
            return pivotValue[Int(indices[0])]
        } else if numInterp == 1 {
            let v0 = pivotValue[Int(indices[0])]
            let v1 = pivotValue[Int(indices[1])]
            return v0 + (v1 - v0) * tArr[0]
        } else if numInterp == 2 {
            let v0 = pivotValue[Int(indices[0])]; let v1 = pivotValue[Int(indices[1])]
            let v2 = pivotValue[Int(indices[2])]; let v3 = pivotValue[Int(indices[3])]
            let t0 = tArr[0]; let t1 = tArr[1]
            return (1 - t1) * (v0 + (v1 - v0) * t0) + t1 * (v2 + (v3 - v2) * t0)
        } else if numInterp == 3 {
            let t0 = tArr[0]; let t1 = tArr[1]; let t2 = tArr[2]
            let p = (0..<8).map { pivotValue[Int(indices[$0])] }
            return (1 - t2) * ((1 - t1) * (p[0] + (p[1] - p[0]) * t0) + t1 * (p[2] + (p[3] - p[2]) * t0))
                 + t2 * ((1 - t1) * (p[4] + (p[5] - p[4]) * t0) + t1 * (p[6] + (p[7] - p[6]) * t0))
        } else if numInterp == 4 {
            let t0 = tArr[0]; let t1 = tArr[1]; let t2 = tArr[2]; let t3 = tArr[3]
            let p = (0..<16).map { pivotValue[Int(indices[$0])] }
            let layer0 = (1 - t1) * (p[0] + (p[1] - p[0]) * t0) + t1 * (p[2] + (p[3] - p[2]) * t0)
            let layer1 = (1 - t1) * (p[4] + (p[5] - p[4]) * t0) + t1 * (p[6] + (p[7] - p[6]) * t0)
            let layer2 = (1 - t1) * (p[8] + (p[9] - p[8]) * t0) + t1 * (p[10] + (p[11] - p[10]) * t0)
            let layer3 = (1 - t1) * (p[12] + (p[13] - p[12]) * t0) + t1 * (p[14] + (p[15] - p[14]) * t0)
            return (1 - t3) * ((1 - t2) * layer0 + t2 * layer1) + t3 * ((1 - t2) * layer2 + t2 * layer3)
        } else {
            let count = 1 << numInterp
            var weights = [Float](repeating: 0, count: count)
            for i in 0..<count {
                var idx = Float(i)
                var w: Float = 1
                for l in 0..<numInterp {
                    w *= (Int(idx) % 2 == 0) ? (1 - tArr[l]) : tArr[l]
                    idx /= 2
                }
                weights[i] = w
            }
            var result: Float = 0
            for i in 0..<count {
                result += weights[i] * pivotValue[Int(indices[i])]
            }
            return result
        }
    }

    // MARK: - Points interpolation

    static func interpolatePoints(_ mdc: ModelContext, _ pivotMgr: PivotManager,
                                  _ retParamOut: inout [Bool], _ numPts: Int,
                                  _ pivotPoints: [Any?], _ dstPoints: inout [Float],
                                  _ ptOffset: Int, _ ptStep: Int) {
        let numInterp = pivotMgr.calcPivotValues(mdc, &retParamOut)
        var indices = mdc.getTempPivotTableIndices()
        var tArr = mdc.getTempT()
        pivotMgr.calcPivotIndices(&indices, &tArr, numInterp)
        mdc.setTempPivotTableIndices(indices)
        mdc.setTempT(tArr)

        let totalCoords = numPts * 2
        var dstIdx = ptOffset

        if numInterp <= 0 {
            guard let src = pivotPoints[Int(indices[0])] as? [Float] else { return }
            if ptStep == 2 && ptOffset == 0 {
                UtSystem.arraycopy(src, 0, &dstPoints, 0, totalCoords)
            } else {
                var si = 0
                while si < totalCoords {
                    dstPoints[dstIdx] = src[si]; si += 1
                    dstPoints[dstIdx + 1] = src[si]; si += 1
                    dstIdx += ptStep
                }
            }
        } else if numInterp == 1 {
            guard let s0 = pivotPoints[Int(indices[0])] as? [Float],
                  let s1 = pivotPoints[Int(indices[1])] as? [Float] else { return }
            let t = tArr[0]; let oneMinusT = 1 - t
            var si = 0
            while si < totalCoords {
                dstPoints[dstIdx] = s0[si] * oneMinusT + s1[si] * t; si += 1
                dstPoints[dstIdx + 1] = s0[si] * oneMinusT + s1[si] * t; si += 1
                dstIdx += ptStep
            }
        } else if numInterp == 2 {
            guard let s0 = pivotPoints[Int(indices[0])] as? [Float],
                  let s1 = pivotPoints[Int(indices[1])] as? [Float],
                  let s2 = pivotPoints[Int(indices[2])] as? [Float],
                  let s3 = pivotPoints[Int(indices[3])] as? [Float] else { return }
            let t0 = tArr[0]; let t1 = tArr[1]
            let w00 = (1 - t1) * (1 - t0); let w10 = (1 - t1) * t0
            let w01 = t1 * (1 - t0); let w11 = t1 * t0
            var si = 0
            while si < totalCoords {
                dstPoints[dstIdx] = w00 * s0[si] + w10 * s1[si] + w01 * s2[si] + w11 * s3[si]; si += 1
                dstPoints[dstIdx + 1] = w00 * s0[si] + w10 * s1[si] + w01 * s2[si] + w11 * s3[si]; si += 1
                dstIdx += ptStep
            }
        } else if numInterp == 3 {
            let srcs = (0..<8).map { pivotPoints[Int(indices[$0])] as! [Float] }
            let t0 = tArr[0]; let t1 = tArr[1]; let t2 = tArr[2]
            let _1t0 = 1 - t0; let _1t1 = 1 - t1; let _1t2 = 1 - t2
            let w = [_1t2*_1t1*_1t0, _1t2*_1t1*t0, _1t2*t1*_1t0, _1t2*t1*t0,
                     t2*_1t1*_1t0, t2*_1t1*t0, t2*t1*_1t0, t2*t1*t0]
            var si = 0
            while si < totalCoords {
                var x: Float = 0; var y: Float = 0
                for j in 0..<8 { x += w[j] * srcs[j][si] }
                si += 1
                for j in 0..<8 { y += w[j] * srcs[j][si] }
                si += 1
                dstPoints[dstIdx] = x
                dstPoints[dstIdx + 1] = y
                dstIdx += ptStep
            }
        } else if numInterp == 4 {
            let srcs = (0..<16).map { pivotPoints[Int(indices[$0])] as! [Float] }
            let t0 = tArr[0]; let t1 = tArr[1]; let t2 = tArr[2]; let t3 = tArr[3]
            let _1t0 = 1 - t0; let _1t1 = 1 - t1; let _1t2 = 1 - t2; let _1t3 = 1 - t3
            let w: [Float] = [
                _1t3*_1t2*_1t1*_1t0, _1t3*_1t2*_1t1*t0, _1t3*_1t2*t1*_1t0, _1t3*_1t2*t1*t0,
                _1t3*t2*_1t1*_1t0, _1t3*t2*_1t1*t0, _1t3*t2*t1*_1t0, _1t3*t2*t1*t0,
                t3*_1t2*_1t1*_1t0, t3*_1t2*_1t1*t0, t3*_1t2*t1*_1t0, t3*_1t2*t1*t0,
                t3*t2*_1t1*_1t0, t3*t2*_1t1*t0, t3*t2*t1*_1t0, t3*t2*t1*t0
            ]
            var si = 0
            while si < totalCoords {
                var x: Float = 0; var y: Float = 0
                for j in 0..<16 { x += w[j] * srcs[j][si] }
                si += 1
                for j in 0..<16 { y += w[j] * srcs[j][si] }
                si += 1
                dstPoints[dstIdx] = x
                dstPoints[dstIdx + 1] = y
                dstIdx += ptStep
            }
        } else {
            // Generic N-level
            let count = 1 << numInterp
            var weights = [Float](repeating: 0, count: count)
            for i in 0..<count {
                var idx = Float(i)
                var w: Float = 1
                for l in 0..<numInterp {
                    w *= (Int(idx) % 2 == 0) ? (1 - tArr[l]) : tArr[l]
                    idx /= 2
                }
                weights[i] = w
            }
            let srcs = (0..<count).map { pivotPoints[Int(indices[$0])] as! [Float] }
            var si = 0
            while si < totalCoords {
                var x: Float = 0; var y: Float = 0
                for j in 0..<count { x += weights[j] * srcs[j][si] }
                si += 1
                for j in 0..<count { y += weights[j] * srcs[j][si] }
                si += 1
                dstPoints[dstIdx] = x
                dstPoints[dstIdx + 1] = y
                dstIdx += ptStep
            }
        }
    }
}
