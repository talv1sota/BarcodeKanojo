import SwiftUI
import AVFoundation

/// Camera-based barcode scanner using AVFoundation.
struct BarcodeScannerView: View {
    @StateObject private var vm = ScanViewModel()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // Camera preview
                CameraPreviewView(onScan: { barcode, format in
                    Task { await vm.handleScannedBarcode(barcode, format: format) }
                })
                .ignoresSafeArea()

                // Overlay
                ScannerOverlayView()

                // State-based UI
                VStack {
                    Spacer()
                    scanStateView
                        .padding(.bottom, 40)
                }

                // Scan result overlay for existing kanojos
                if case .existingKanojo(let result) = vm.state {
                    ScanResultView(
                        result: result,
                        onVisitRoom: {
                            vm.reset()
                            path.append(result.kanojo)
                        },
                        onDismiss: {
                            vm.reset()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: vm.state)
            .navigationDestination(for: Kanojo.self) { kanojo in
                KanojoRoomView(kanojoId: kanojo.id)
            }
            .onChange(of: vm.state) { state in
                switch state {
                case .generated(let kanojo):
                    path.append(kanojo)
                default:
                    break
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .task { await vm.loadCategories() }
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Simulate: Known barcode (4902102104326)") {
                            Task { await vm.handleScannedBarcode("4902102104326", format: "EAN_13") }
                        }
                        Button("Simulate: New barcode (9999999999999)") {
                            Task { await vm.handleScannedBarcode("9999999999999", format: "EAN_13") }
                        }
                    } label: {
                        Image(systemName: "ladybug")
                    }
                }
            }
            #endif
        }
    }

    @ViewBuilder
    private var scanStateView: some View {
        switch vm.state {
        case .idle, .scanning:
            Text("Point camera at a barcode")
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(10)
                .background(.black.opacity(0.5), in: Capsule())

        case .querying:
            HStack(spacing: 8) {
                ProgressView().tint(.white)
                Text("Looking up barcode...").foregroundStyle(.white)
            }
            .padding(10)
            .background(.black.opacity(0.5), in: Capsule())

        case .generating:
            HStack(spacing: 8) {
                ProgressView().tint(.white)
                Text("Generating kanojo...").foregroundStyle(.white)
            }
            .padding(10)
            .background(.black.opacity(0.5), in: Capsule())

        case .newBarcode(let barcode):
            GenerateKanojoPrompt(
                barcode: barcode,
                categories: vm.categories,
                onGenerate: { name, productName, company, catId, comment in
                    Task {
                        await vm.generateKanojo(
                            barcode: barcode,
                            kanojoName: name,
                            productName: productName,
                            companyName: company,
                            categoryId: catId,
                            comment: comment,
                            geo: nil
                        )
                    }
                },
                onCancel: { vm.reset() }
            )
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding()

        case .error(let msg):
            VStack(spacing: 8) {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.white)
                Button("Try Again") { vm.reset() }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
            }
            .padding(12)
            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))

        case .generated:
            HStack(spacing: 8) {
                Image(systemName: "heart.fill").foregroundStyle(.pink)
                Text("Kanojo created!").foregroundStyle(.white)
            }
            .padding(10)
            .background(.black.opacity(0.5), in: Capsule())

        case .existingKanojo:
            // Handled by the ScanResultView overlay
            EmptyView()
        }
    }
}

// MARK: - Scanner Overlay

private struct ScannerOverlayView: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) * 0.65
            ZStack {
                Color.black.opacity(0.4)
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .frame(width: size, height: size)
                                    .blendMode(.destinationOut)
                            )
                    )
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pink, lineWidth: 2)
                    .frame(width: size, height: size)
            }
        }
    }
}

// MARK: - Generate Prompt

private struct GenerateKanojoPrompt: View {
    let barcode: String
    let categories: [Category]
    let onGenerate: (String, String, String, Int, String) -> Void
    let onCancel: () -> Void

    @State private var kanojoName = ""
    @State private var productName = ""
    @State private var company = ""
    @State private var comment = ""
    @State private var selectedCategory = 1

    var body: some View {
        VStack(spacing: 12) {
            Text("New Barcode!")
                .font(.headline)
            Text(barcode)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            TextField("Kanojo name (optional)", text: $kanojoName)
                .textFieldStyle(.roundedBorder)
            TextField("Product name", text: $productName)
                .textFieldStyle(.roundedBorder)
            TextField("Company name", text: $company)
                .textFieldStyle(.roundedBorder)

            if !categories.isEmpty {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories) { cat in
                        Text(cat.name).tag(cat.id)
                    }
                }
                .pickerStyle(.menu)
                .onAppear {
                    if let first = categories.first {
                        selectedCategory = first.id
                    }
                }
            }

            HStack {
                Button("Cancel", role: .cancel) { onCancel() }
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Generate") {
                    onGenerate(kanojoName, productName, company, selectedCategory, comment)
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            }
        }
    }
}

// MARK: - AVFoundation Camera

struct CameraPreviewView: UIViewRepresentable {
    let onScan: (String, String) -> Void

    func makeUIView(context: Context) -> CameraView {
        let view = CameraView()
        view.onScan = onScan
        return view
    }

    func updateUIView(_ uiView: CameraView, context: Context) {}
}

final class CameraView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String, String) -> Void)?

    private let session = AVCaptureSession()
    private var lastScanned: String?
    private var lastScanTime: Date = .distantPast

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let preview = layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            preview.frame = bounds
        }
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [
            .ean13, .ean8, .upce, .qr, .code128, .code39, .itf14, .pdf417
        ]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = bounds
        layer.insertSublayer(preview, at: 0)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    /// Map AVFoundation type to server-expected format strings (matching ZXing BarcodeFormat names).
    static func serverFormat(for type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .ean13:   return "EAN_13"
        case .ean8:    return "EAN_8"
        case .upce:    return "UPC_E"
        case .code128: return "CODE_128"
        case .code39:  return "CODE_39"
        case .itf14:   return "ITF"
        case .qr:      return "QR_CODE"
        case .pdf417:  return "PDF_417"
        default:       return type.rawValue
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }

        // Debounce: don't re-scan same barcode within 2 seconds
        let now = Date()
        guard value != lastScanned || now.timeIntervalSince(lastScanTime) > 2 else { return }

        lastScanned = value
        lastScanTime = now

        let format = Self.serverFormat(for: obj.type)
        onScan?(value, format)
    }
}
