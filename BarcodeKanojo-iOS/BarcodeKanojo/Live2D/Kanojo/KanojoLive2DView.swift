// KanojoLive2DView.swift — SwiftUI view wrapping MTKView for Live2D rendering
// This replaces the AvatarPlaceholderView in KanojoRoomView.

import SwiftUI
import MetalKit

// MARK: - SwiftUI Wrapper

struct KanojoLive2DView: UIViewRepresentable {
    let kanojoData: [String: Any]
    let avatarDataDir: URL
    /// Optional callback when the kanojo is touched. Receives the detected TouchRegion.
    var onTouch: ((TouchRegion) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onTouch: onTouch)
    }

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.isOpaque = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 30
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.isUserInteractionEnabled = true

        let coordinator = context.coordinator
        coordinator.device = device
        coordinator.setup(kanojoData: kanojoData, avatarDataDir: avatarDataDir)
        mtkView.delegate = coordinator

        // Single-tap gesture for touch reaction (body-part aware)
        let singleTap = UITapGestureRecognizer(
            target: coordinator, action: #selector(Coordinator.handleSingleTap(_:))
        )
        singleTap.numberOfTapsRequired = 1
        mtkView.addGestureRecognizer(singleTap)

        // Double-tap gesture for head pat reaction
        let doubleTap = UITapGestureRecognizer(
            target: coordinator, action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        mtkView.addGestureRecognizer(doubleTap)

        // Single-tap must wait for double-tap to fail first
        singleTap.require(toFail: doubleTap)

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Update callback if it changed
        context.coordinator.onTouch = onTouch
    }

    static func dismantleUIView(_ uiView: MTKView, coordinator: Coordinator) {
        coordinator.stopMotion()
    }

    // MARK: - Coordinator (MTKViewDelegate)

    class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var kanojoModel: KanojoModel?
        var onTouch: ((TouchRegion) -> Void)?
        private var lastTime: Double = 0
        private let motionManager = DeviceMotionManager()

        init(onTouch: ((TouchRegion) -> Void)?) {
            self.onTouch = onTouch
        }

        func setup(kanojoData: [String: Any], avatarDataDir: URL) {
            guard let device = device else { return }
            commandQueue = device.makeCommandQueue()

            let model = KanojoModel(avatarDataDir: avatarDataDir)
            model.configure(from: kanojoData)

            // Load model on background thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                model.load(device: device)
                DispatchQueue.main.async {
                    self?.kanojoModel = model
                    self?.startMotion()
                }
            }
        }

        func startMotion() {
            // Start accelerometer for tilt + shake
            motionManager.onShake = { [weak self] in
                self?.kanojoModel?.triggerShake()
                // Shake is animation-only — does NOT call playOnLive2d (no love points)
            }
            motionManager.start()
        }

        func stopMotion() {
            motionManager.stop()
        }

        // MARK: - Tap Gesture Handlers

        @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended,
                  let model = kanojoModel,
                  let view = gesture.view else { return }

            // Get normalized tap coordinates
            let location = gesture.location(in: view)
            let normalizedX = location.x / view.bounds.width
            let normalizedY = location.y / view.bounds.height

            // Detect body region
            let region = TouchRegion.detect(normalizedX: normalizedX, normalizedY: normalizedY)

            // Trigger appropriate animation
            model.triggerRegionTouch(region)
            print("[Live2DView] Single tap at (\(String(format: "%.2f", normalizedX)), \(String(format: "%.2f", normalizedY))) → \(region.rawValue) reaction")

            // Notify parent view for API call
            onTouch?(region)
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended, let model = kanojoModel else { return }
            model.triggerDoubleTap()
            print("[Live2DView] Double tap → head pat reaction")
            onTouch?(.head)
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Projection will be recalculated each frame
        }

        func draw(in view: MTKView) {
            guard let model = kanojoModel,
                  let device = device,
                  let commandQueue = commandQueue,
                  let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

            // Feed accelerometer data to model
            model.setAcceleration(
                motionManager.accelerationX,
                motionManager.accelerationY,
                motionManager.accelerationZ
            )

            // Calculate delta time
            let now = UtSystem.getTimeMSec()
            let dt = lastTime == 0 ? 0 : Float((now - lastTime) / 1000.0)
            lastTime = now

            // Update
            model.update(deltaTime: dt)

            // Draw — pass renderPassDescriptor so model can do multi-pass rendering
            // (offscreen clip mask pass + main screen pass)
            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

            let drawableSize = view.drawableSize
            model.draw(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor,
                       viewWidth: Float(drawableSize.width),
                       viewHeight: Float(drawableSize.height))

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct KanojoLive2DView_Previews: PreviewProvider {
    static var previews: some View {
        KanojoLive2DView(
            kanojoData: ["hair_type": 1, "eye_type": 1, "skin_color": 1],
            avatarDataDir: Bundle.main.resourceURL!.appendingPathComponent("avatar_data")
        )
        .frame(width: 300, height: 400)
        .background(Color.pink.opacity(0.3))
    }
}
#endif
