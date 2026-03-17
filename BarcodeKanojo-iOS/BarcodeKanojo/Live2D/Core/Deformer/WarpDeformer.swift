// WarpDeformer.swift — Grid-based warp deformer
// Ported from live2d-v2/live2d/core/deformer/warp_deformer.py

import Foundation

final class WarpDeformer: Deformer {
    private static var paramOutsideFlag: [Bool] = [false]

    var row: Int = 0
    var col: Int = 0
    var pivotMgr: PivotManager?
    var pivotPoints: [Any?]?

    override func read(_ br: BinaryReader) {
        super.read(br)
        col = Int(br.readInt32())
        row = Int(br.readInt32())
        pivotMgr = br.readObject() as? PivotManager
        pivotPoints = br.readObject() as? [Any?]
        readOpacity(br)
    }

    override func initContext(_ mc: ModelContext) -> DeformerContext {
        let ctx = WarpContext(self)
        let pointCount = (row + 1) * (col + 1)
        ctx.interpolatedPoints = [Float](repeating: 0, count: pointCount * 2)
        if needTransform() {
            ctx.transformedPoints = [Float](repeating: 0, count: pointCount * 2)
        }
        return ctx
    }

    override func setupInterpolate(_ mc: ModelContext, _ dc: DeformerContext) {
        guard let wctx = dc as? WarpContext, let pm = pivotMgr else { return }
        if !pm.checkParamUpdated(mc) { return }

        let ptCount = getPointCount()
        var outsideFlag = WarpDeformer.paramOutsideFlag
        outsideFlag[0] = false

        guard var interpPts = wctx.interpolatedPoints else { return }
        UtInterpolate.interpolatePoints(mc, pm, &outsideFlag, ptCount,
                                        pivotPoints ?? [], &interpPts, 0, 2)
        wctx.interpolatedPoints = interpPts
        dc.setOutsideParam(outsideFlag[0])
        interpolateOpacity(mc, pm, dc, &outsideFlag)
    }

    override func setupTransform(_ mc: ModelContext, _ dc: DeformerContext) -> Bool {
        guard let wctx = dc as? WarpContext else { return false }
        wctx.setAvailable(true)

        if !needTransform() {
            wctx.setTotalOpacity(wctx.getInterpolatedOpacity())
        } else {
            guard let tid = getTargetId() else { wctx.setAvailable(false); return false }
            if wctx.tmpDeformerIndex == Deformer.DEFORMER_INDEX_NOT_INIT {
                wctx.tmpDeformerIndex = mc.getDeformerIndex(tid)
            }
            if wctx.tmpDeformerIndex < 0 {
                print("deformer is not reachable")
                wctx.setAvailable(false)
            } else {
                let parentDfm = mc.getDeformer(wctx.tmpDeformerIndex)
                let parentCtx = mc.getDeformerContext(wctx.tmpDeformerIndex)
                if let parentDfm = parentDfm, parentCtx.isAvailable() {
                    let parentScale = parentCtx.getTotalScale()
                    wctx.setTotalScale_notForClient(parentScale)
                    let parentOp = parentCtx.getTotalOpacity()
                    wctx.setTotalOpacity(parentOp * wctx.getInterpolatedOpacity())

                    guard let src = wctx.interpolatedPoints else { return false }
                    var dst = wctx.transformedPoints ?? [Float](repeating: 0, count: src.count)
                    parentDfm.transformPoints(mc, parentCtx, src, &dst, getPointCount(), 0, 2)
                    wctx.transformedPoints = dst
                    wctx.setAvailable(true)
                } else {
                    wctx.setAvailable(false)
                }
            }
        }
        return true
    }

    override func transformPoints(_ mc: ModelContext, _ dc: DeformerContext,
                                  _ srcPoints: [Float], _ dstPoints: inout [Float],
                                  _ numPoint: Int, _ ptOffset: Int, _ ptStep: Int) {
        guard let wctx = dc as? WarpContext else { return }
        let grid = wctx.transformedPoints ?? wctx.interpolatedPoints!
        WarpDeformer.transformPoints_sdk2(srcPoints, &dstPoints, numPoint, ptOffset, ptStep,
                                          grid, row, col)
    }

    func getPointCount() -> Int {
        return (row + 1) * (col + 1)
    }

    override func getType() -> Int { Deformer.TYPE_WARP }

    // MARK: - SDK2 grid transform with full 9-region boundary extrapolation

    static func transformPoints_sdk2(_ src: [Float], _ dst: inout [Float],
                                     _ pointCount: Int, _ srcOffset: Int, _ srcStep: Int,
                                     _ grid: [Float], _ row: Int, _ col: Int) {
        let totalStride = pointCount * srcStep
        let rp1 = row + 1 // rowPlus1

        // Boundary basis vectors (computed once on first outside point)
        var cX: Float = 0, cY: Float = 0   // adjusted center
        var bX: Float = 0, bXY: Float = 0  // row-direction basis (x, y components)
        var bY: Float = 0, bYY: Float = 0  // col-direction basis (x, y components)
        var boundaryReady = false

        // Grid point accessors: grid[(r + c * rp1) * 2] = x, +1 = y
        @inline(__always) func gx(_ r: Int, _ c: Int) -> Float { grid[(r + c * rp1) * 2] }
        @inline(__always) func gy(_ r: Int, _ c: Int) -> Float { grid[(r + c * rp1) * 2 + 1] }

        var ba = srcOffset
        while ba < totalStride {
            let nX = src[ba]        // normX: 0..1 in row direction
            let nY = src[ba + 1]    // normY: 0..1 in col direction
            let gXf = nX * Float(row)  // grid-space X
            let gYf = nY * Float(col)  // grid-space Y

            if gXf < 0 || gYf < 0 || Float(row) <= gXf || Float(col) <= gYf {
                // ── Outside grid ──
                if !boundaryReady {
                    boundaryReady = true
                    cX = 0.25 * (gx(0,0) + gx(row,0) + gx(0,col) + gx(row,col))
                    cY = 0.25 * (gy(0,0) + gy(row,0) + gy(0,col) + gy(row,col))
                    let diagX = gx(row,col) - gx(0,0)
                    let diagY = gy(row,col) - gy(0,0)
                    let antiX = gx(row,0) - gx(0,col)
                    let antiY = gy(row,0) - gy(0,col)
                    bX  = (diagX + antiX) * 0.5
                    bXY = (diagY + antiY) * 0.5
                    bY  = (diagX - antiX) * 0.5
                    bYY = (diagY - antiY) * 0.5
                    cX -= 0.5 * (bX + bY)
                    cY -= 0.5 * (bXY + bYY)
                }

                if nX > -2 && nX < 3 && nY > -2 && nY < 3 {
                    // ── Extended boundary: 9-region extrapolation ──
                    // Each region constructs a virtual quad (q00..q11) and uses
                    // triangle-split bilinear interpolation, matching the SDK2
                    // reference implementation exactly.
                    var q00x: Float = 0, q00y: Float = 0 // quad corner at (bj=0, bi=0)
                    var q10x: Float = 0, q10y: Float = 0 // quad corner at (bj=1, bi=0)
                    var q01x: Float = 0, q01y: Float = 0 // quad corner at (bj=0, bi=1)
                    var q11x: Float = 0, q11y: Float = 0 // quad corner at (bj=1, bi=1)
                    var bj: Float = 0, bi: Float = 0

                    if nX <= 0 {
                        if nY <= 0 {
                            // Region 1: bottom-left corner
                            q11x = gx(0,0);               q11y = gy(0,0)
                            q01x = cX - 2*bX;             q01y = cY - 2*bXY
                            q10x = cX - 2*bY;             q10y = cY - 2*bYY
                            q00x = cX - 2*bX - 2*bY;     q00y = cY - 2*bXY - 2*bYY
                            bj = 0.5 * (nX + 2)
                            bi = 0.5 * (nY + 2)
                        } else if nY >= 1 {
                            // Region 2: top-left corner
                            q10x = gx(0,col);             q10y = gy(0,col)
                            q00x = cX - 2*bX + bY;       q00y = cY - 2*bXY + bYY
                            q11x = cX + 3*bY;             q11y = cY + 3*bYY
                            q01x = cX - 2*bX + 3*bY;     q01y = cY - 2*bXY + 3*bYY
                            bj = 0.5 * (nX + 2)
                            bi = 0.5 * (nY - 1)
                        } else {
                            // Region 3: left edge (follows boundary curvature)
                            var ci = Int(gYf)
                            if ci == col { ci = col - 1 }
                            let nc0 = Float(ci) / Float(col)
                            let nc1 = Float(ci + 1) / Float(col)
                            q10x = gx(0, ci);                   q10y = gy(0, ci)
                            q11x = gx(0, ci+1);                 q11y = gy(0, ci+1)
                            q00x = cX - 2*bX + nc0*bY;          q00y = cY - 2*bXY + nc0*bYY
                            q01x = cX - 2*bX + nc1*bY;          q01y = cY - 2*bXY + nc1*bYY
                            bj = 0.5 * (nX + 2)
                            bi = gYf - Float(ci)
                        }
                    } else if nX >= 1 {
                        if nY <= 0 {
                            // Region 4: bottom-right corner
                            q01x = gx(row, 0);            q01y = gy(row, 0)
                            q11x = cX + 3*bX;             q11y = cY + 3*bXY
                            q00x = cX + bX - 2*bY;        q00y = cY + bXY - 2*bYY
                            q10x = cX + 3*bX - 2*bY;      q10y = cY + 3*bXY - 2*bYY
                            bj = 0.5 * (nX - 1)
                            bi = 0.5 * (nY + 2)
                        } else if nY >= 1 {
                            // Region 5: top-right corner
                            q00x = gx(row, col);           q00y = gy(row, col)
                            q10x = cX + 3*bX + bY;        q10y = cY + 3*bXY + bYY
                            q01x = cX + bX + 3*bY;        q01y = cY + bXY + 3*bYY
                            q11x = cX + 3*bX + 3*bY;      q11y = cY + 3*bXY + 3*bYY
                            bj = 0.5 * (nX - 1)
                            bi = 0.5 * (nY - 1)
                        } else {
                            // Region 6: right edge (follows boundary curvature)
                            var ci = Int(gYf)
                            if ci == col { ci = col - 1 }
                            let nc0 = Float(ci) / Float(col)
                            let nc1 = Float(ci + 1) / Float(col)
                            q00x = gx(row, ci);                  q00y = gy(row, ci)
                            q01x = gx(row, ci+1);                q01y = gy(row, ci+1)
                            q10x = cX + 3*bX + nc0*bY;           q10y = cY + 3*bXY + nc0*bYY
                            q11x = cX + 3*bX + nc1*bY;           q11y = cY + 3*bXY + nc1*bYY
                            bj = 0.5 * (nX - 1)
                            bi = gYf - Float(ci)
                        }
                    } else {
                        // 0 < nX < 1: edge regions along top/bottom
                        if nY <= 0 {
                            // Region 7: bottom edge (follows boundary curvature)
                            var ri = Int(gXf)
                            if ri == row { ri = row - 1 }
                            let nr0 = Float(ri) / Float(row)
                            let nr1 = Float(ri + 1) / Float(row)
                            q01x = gx(ri, 0);                    q01y = gy(ri, 0)
                            q11x = gx(ri+1, 0);                  q11y = gy(ri+1, 0)
                            q00x = cX + nr0*bX - 2*bY;           q00y = cY + nr0*bXY - 2*bYY
                            q10x = cX + nr1*bX - 2*bY;           q10y = cY + nr1*bXY - 2*bYY
                            bj = gXf - Float(ri)
                            bi = 0.5 * (nY + 2)
                        } else if nY >= 1 {
                            // Region 8: top edge (follows boundary curvature)
                            var ri = Int(gXf)
                            if ri == row { ri = row - 1 }
                            let nr0 = Float(ri) / Float(row)
                            let nr1 = Float(ri + 1) / Float(row)
                            q00x = gx(ri, col);                  q00y = gy(ri, col)
                            q10x = gx(ri+1, col);                q10y = gy(ri+1, col)
                            q01x = cX + nr0*bX + 3*bY;           q01y = cY + nr0*bXY + 3*bYY
                            q11x = cX + nr1*bX + 3*bY;           q11y = cY + nr1*bXY + 3*bYY
                            bj = gXf - Float(ri)
                            bi = 0.5 * (nY - 1)
                        } else {
                            // Should not reach here (inside grid)
                            dst[ba]     = cX + nX * bX + nY * bY
                            dst[ba + 1] = cY + nX * bXY + nY * bYY
                            ba += srcStep
                            continue
                        }
                    }

                    // Triangle-split bilinear interpolation on virtual quad
                    if bj + bi <= 1 {
                        dst[ba]     = q00x + (q10x - q00x) * bj + (q01x - q00x) * bi
                        dst[ba + 1] = q00y + (q10y - q00y) * bj + (q01y - q00y) * bi
                    } else {
                        dst[ba]     = q11x + (q01x - q11x) * (1 - bj) + (q10x - q11x) * (1 - bi)
                        dst[ba + 1] = q11y + (q01y - q11y) * (1 - bj) + (q10y - q11y) * (1 - bi)
                    }
                } else {
                    // Far outside extended boundary — simple affine fallback
                    dst[ba]     = cX + nX * bX + nY * bY
                    dst[ba + 1] = cY + nX * bXY + nY * bYY
                }
            } else {
                // ── Inside grid — bilinear interpolation on triangle ──
                let fracX = gXf - Float(Int(gXf))
                let fracY = gYf - Float(Int(gYf))
                let baseIdx = 2 * (Int(gXf) + Int(gYf) * rp1)

                if fracX + fracY < 1 {
                    dst[ba] = grid[baseIdx] * (1 - fracX - fracY)
                        + grid[baseIdx + 2] * fracX
                        + grid[baseIdx + 2 * rp1] * fracY
                    dst[ba + 1] = grid[baseIdx + 1] * (1 - fracX - fracY)
                        + grid[baseIdx + 3] * fracX
                        + grid[baseIdx + 2 * rp1 + 1] * fracY
                } else {
                    dst[ba] = grid[baseIdx + 2 * rp1 + 2] * (fracX - 1 + fracY)
                        + grid[baseIdx + 2 * rp1] * (1 - fracX)
                        + grid[baseIdx + 2] * (1 - fracY)
                    dst[ba + 1] = grid[baseIdx + 2 * rp1 + 3] * (fracX - 1 + fracY)
                        + grid[baseIdx + 2 * rp1 + 1] * (1 - fracX)
                        + grid[baseIdx + 3] * (1 - fracY)
                }
            }

            ba += srcStep
        }
    }
}
