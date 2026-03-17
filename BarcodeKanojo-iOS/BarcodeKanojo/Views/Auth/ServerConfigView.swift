import SwiftUI

struct ServerConfigView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings = AppSettings.shared

    @State private var host: String = ""
    @State private var port: String = ""
    @State private var useHTTPS: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Host", text: $host)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .placeholder(when: host.isEmpty) {
                            Text(Constants.defaultServerHost).foregroundStyle(.secondary)
                        }

                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                        .placeholder(when: port.isEmpty) {
                            Text(String(Constants.defaultServerPort)).foregroundStyle(.secondary)
                        }

                    Toggle("Use HTTPS", isOn: $useHTTPS)
                } header: {
                    Text("Server")
                } footer: {
                    Text("Default: \(Constants.defaultServerHost):\(Constants.defaultServerPort) (HTTPS)")
                        .font(.caption)
                }

                Section {
                    Text(previewURL)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Preview")
                }

                Section {
                    Button("Reset to Default") {
                        host = ""
                        port = ""
                        useHTTPS = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Server Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                }
            }
            .onAppear { loadCurrentSettings() }
        }
    }

    private var previewURL: String {
        let scheme = useHTTPS ? "https" : "http"
        let h = host.isEmpty ? Constants.defaultServerHost : host
        let p = Int(port) ?? Constants.defaultServerPort
        return "\(scheme)://\(h):\(p)"
    }

    private func loadCurrentSettings() {
        host = settings.serverURL
        port = settings.serverPort > 0 ? String(settings.serverPort) : ""
        useHTTPS = settings.serverHTTPS
    }

    private func save() {
        settings.serverURL = host
        settings.serverPort = Int(port) ?? 0
        settings.serverHTTPS = useHTTPS
    }
}

// MARK: - Placeholder helper

private extension View {
    func placeholder<Content: View>(when condition: Bool, @ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .leading) {
            if condition { content() }
            self
        }
    }
}
