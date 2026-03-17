// TouchRegion.swift — Body-part specific touch detection for Live2D kanojo
// Maps normalized tap coordinates (0-1) to body regions.
// Based on original Cybird game: face = kiss, chest = breast touch,
// head = headpat, default = general touch.

import Foundation

enum TouchRegion: String {
    case head       // Top of head area — headpat (double-tap behavior)
    case face       // Face area — kiss reaction
    case chest      // Chest area — breast touch reaction (surprised/angry)
    case body       // General body — standard touch reaction

    /// Action string sent to the server via playOnLive2d API.
    var actionName: String {
        switch self {
        case .head: return "headpat"
        case .face: return "kiss"
        case .chest: return "breast_touch"
        case .body: return "touch"
        }
    }

    /// Detect which body region a normalized tap coordinate falls in.
    /// - Parameters:
    ///   - normalizedX: 0 (left) to 1 (right)
    ///   - normalizedY: 0 (top) to 1 (bottom)
    /// - Returns: The detected body region.
    ///
    /// Region layout (approximate for Live2D kanojo model):
    /// ```
    ///   Y: 0.00 - 0.12  →  Head (top of head / hair)
    ///   Y: 0.12 - 0.35  →  Face (eyes, nose, mouth)
    ///   Y: 0.35 - 0.55  →  Chest (upper body)
    ///   Y: 0.55 - 1.00  →  Body (lower body / default)
    ///   X outside 0.25-0.75 at any Y → Body (arms/sides)
    /// ```
    static func detect(normalizedX: CGFloat, normalizedY: CGFloat) -> TouchRegion {
        // Only consider center-of-body taps for face/chest (X between 25% - 75%)
        let isCentered = normalizedX >= 0.25 && normalizedX <= 0.75

        if normalizedY < 0.12 {
            return .head
        } else if normalizedY < 0.35 && isCentered {
            return .face
        } else if normalizedY < 0.55 && isCentered {
            return .chest
        } else {
            return .body
        }
    }
}
