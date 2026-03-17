// MotionPlayer.swift — Plays Live2D .mtn motion files
// Ported from kanojo_app-master/.../live2d/motion/ classes
// .mtn format: comment lines (#), $fps=N, PARAM_NAME=val0,val1,val2,...

import Foundation

final class MotionPlayer {
    /// A parsed motion: parameter tracks with keyframe values at a fixed fps.
    struct Motion {
        let fps: Float
        let tracks: [(paramName: String, values: [Float])]
        let frameCount: Int
    }

    private var currentMotion: Motion?
    private var currentFrame: Float = 0
    private var isPlaying = false

    /// Whether a motion is currently playing.
    var playing: Bool { isPlaying }

    // MARK: - Parse .mtn file

    static func loadMotion(from url: URL) -> Motion? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("[MotionPlayer] Failed to read \(url.lastPathComponent)")
            return nil
        }

        var fps: Float = 30
        var tracks: [(String, [Float])] = []
        var maxFrames = 0

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            if trimmed.hasPrefix("$fps=") {
                fps = Float(trimmed.dropFirst(5)) ?? 30
                continue
            }

            // PARAM_NAME=val0,val1,val2,...
            if let eqIdx = trimmed.firstIndex(of: "=") {
                let paramName = String(trimmed[trimmed.startIndex..<eqIdx])
                let valuesStr = String(trimmed[trimmed.index(after: eqIdx)...])
                let values = valuesStr.split(separator: ",").compactMap { Float($0) }
                if !values.isEmpty {
                    tracks.append((paramName, values))
                    maxFrames = max(maxFrames, values.count)
                }
            }
        }

        guard maxFrames > 0 else { return nil }
        return Motion(fps: fps, tracks: tracks, frameCount: maxFrames)
    }

    // MARK: - Playback

    func startMotion(_ motion: Motion) {
        currentMotion = motion
        currentFrame = 0
        isPlaying = true
    }

    func stop() {
        isPlaying = false
        currentMotion = nil
    }

    /// Advance the motion and apply parameter values to the model.
    /// Call this during the animation update loop.
    /// Returns true while the motion is still playing.
    func update(_ model: ALive2DModel, deltaMs: Double) -> Bool {
        guard isPlaying, let motion = currentMotion else { return false }

        let frameIndex = Int(currentFrame)
        if frameIndex >= motion.frameCount {
            isPlaying = false
            currentMotion = nil
            return false
        }

        // Apply each track's value at the current frame
        for (paramName, values) in motion.tracks {
            let idx = min(frameIndex, values.count - 1)
            let value = values[idx]
            // Use setParamFloat with the param name string
            model.setParamFloat(paramName, value)
        }

        // Advance frame based on delta time and fps
        currentFrame += Float(deltaMs / 1000.0) * motion.fps

        return true
    }
}
