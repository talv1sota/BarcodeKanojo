// ColorConvertUtil.swift — CPU-side HSL color tinting for Live2D textures
// Ported from kanojo_app-master/.../live2d/model/ColorConvertUtil.java
// This is Cybird's custom HSL conversion with the "shusendo" coefficient.

import Foundation
import UIKit
import CoreGraphics

final class ColorConvertUtil {

    /// Apply HSL color conversion to a CGImage, returning a new tinted CGImage
    static func convertColor(_ image: CGImage, _ cc: ColorConvert) -> CGImage {
        let width = image.width
        let height = image.height

        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return image }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return image }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                let off = (y * width + x) * 4
                let r = pixels[off]
                let g = pixels[off + 1]
                let b = pixels[off + 2]
                let a = pixels[off + 3]

                guard a >= 26 else { continue }

                // Unpremultiply alpha to get true RGB values
                let aFloat = Float(a) / 255.0
                let sr = Float(r) / (255.0 * aFloat)
                let sg = Float(g) / (255.0 * aFloat)
                let sb = Float(b) / (255.0 * aFloat)

                guard r != g || r != b else { continue } // Skip gray pixels

                let cmax = max(sr, max(sg, sb))
                let cmin = min(sr, min(sg, sb))
                var hslH: Float
                var hslS: Float
                var hslL = (cmax + cmin) / 2.0
                let chroma = cmax - cmin

                let shusendo = -6.6666666 * hslL - 1.6666666

                guard shusendo <= 1.0 else { continue }

                // RGB to Hue
                if sr == cmax {
                    hslH = 60.0 * ((sg - sb) / chroma)
                } else if sg == cmax {
                    hslH = 60.0 * (2.0 + (sb - sr) / chroma)
                } else {
                    hslH = 60.0 * (4.0 + (sr - sg) / chroma)
                }

                // RGB to Sat
                if hslL <= 0.5 {
                    hslS = chroma / (cmax + cmin)
                } else {
                    hslS = chroma / (2.0 - (cmax + cmin))
                }
                hslS *= 1.0 - abs(2.0 * hslL - 1)

                // Apply color convert
                // Note: Android's ColorConvert constructor halves luminance (this.lum = l/2)
                // so we halve it here to match the original behavior
                hslH += cc.hue
                hslS += cc.sat
                hslL += cc.lum / 2.0

                // Sat correction
                let div = 1.0 - abs(2.0 * hslL - 1)
                if div != 0 { hslS /= div }
                hslS = max(0, min(1, hslS))

                // Lum correction
                hslL = max(0, min(1, hslL))

                // Hue correction
                hslH = hslH.truncatingRemainder(dividingBy: 360)
                if hslH < 0 { hslH += 360 }

                // HSL to RGB
                var cMax2: Float, cMin2: Float
                if hslL <= 0.5 {
                    cMin2 = hslL * (1.0 - hslS)
                    cMax2 = 2.0 * hslL - cMin2
                } else {
                    cMax2 = hslL * (1.0 - hslS) + hslS
                    cMin2 = 2.0 * hslL - cMax2
                }

                // Red
                var tmph = (hslH + 120).truncatingRemainder(dividingBy: 360)
                let dr: Float
                if tmph < 60 { dr = cMin2 + (cMax2 - cMin2) * tmph / 60 }
                else if tmph < 180 { dr = cMax2 }
                else if tmph < 240 { dr = cMin2 + (cMax2 - cMin2) * (240 - tmph) / 60 }
                else { dr = cMin2 }

                // Green
                let dg: Float
                if hslH < 60 { dg = cMin2 + (cMax2 - cMin2) * hslH / 60 }
                else if hslH < 180 { dg = cMax2 }
                else if hslH < 240 { dg = cMin2 + (cMax2 - cMin2) * (240 - hslH) / 60 }
                else { dg = cMin2 }

                // Blue
                tmph = hslH - 120
                if tmph < 0 { tmph += 360 }
                let db: Float
                if tmph < 60 { db = cMin2 + (cMax2 - cMin2) * tmph / 60 }
                else if tmph < 180 { db = cMax2 }
                else if tmph < 240 { db = cMin2 + (cMax2 - cMin2) * (240 - tmph) / 60 }
                else { db = cMin2 }

                // Apply shusendo blending
                var finalR: Float, finalG: Float, finalB: Float
                if shusendo < 0 {
                    finalR = dr
                    finalG = dg
                    finalB = db
                } else {
                    finalR = sr * shusendo + dr * (1 - shusendo)
                    finalG = sg * shusendo + dg * (1 - shusendo)
                    finalB = sb * shusendo + db * (1 - shusendo)
                }

                // Re-premultiply by alpha for premultipliedLast CGContext format.
                // The loadTexture() method will un-premultiply ALL premultiplied
                // CGImages before uploading to Metal, ensuring the shader (which does
                // color.rgb *= color.a) always receives straight alpha texture data.
                pixels[off] = UInt8(min(255, max(0, Int(finalR * aFloat * 255.0))))
                pixels[off + 1] = UInt8(min(255, max(0, Int(finalG * aFloat * 255.0))))
                pixels[off + 2] = UInt8(min(255, max(0, Int(finalB * aFloat * 255.0))))
            }
        }

        return context.makeImage() ?? image
    }
}
