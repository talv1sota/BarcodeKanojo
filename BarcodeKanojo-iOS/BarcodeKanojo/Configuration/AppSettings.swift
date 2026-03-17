import Foundation

/// Persistent application settings backed by UserDefaults.
/// Source: ApplicationSetting.kt + Preferences.kt
final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let serverHTTPS = "server_https"
        static let serverURL = "server_url"
        static let serverPort = "server_port"
        static let deviceUUID = "device_uuid"
        static let userEmail = "user_email"
        static let userPasswordHash = "user_password_hash"
        static let deviceToken = "device_token"
    }

    // MARK: - Server Configuration

    @Published var serverHTTPS: Bool {
        didSet { defaults.set(serverHTTPS, forKey: Keys.serverHTTPS) }
    }

    @Published var serverURL: String {
        didSet { defaults.set(serverURL, forKey: Keys.serverURL) }
    }

    @Published var serverPort: Int {
        didSet { defaults.set(serverPort, forKey: Keys.serverPort) }
    }

    // MARK: - Device Identity

    /// Auto-generated UUID on first access if not already set.
    var deviceUUID: String {
        get {
            if let uuid = defaults.string(forKey: Keys.deviceUUID), !uuid.isEmpty {
                return uuid
            }
            let newUUID = UUID().uuidString
            defaults.set(newUUID, forKey: Keys.deviceUUID)
            return newUUID
        }
        set {
            defaults.set(newValue, forKey: Keys.deviceUUID)
        }
    }

    // MARK: - Credentials

    /// Email is trimmed and lowercased on set (matches Android ApplicationSetting.kt behavior).
    var userEmail: String {
        get { defaults.string(forKey: Keys.userEmail) ?? "" }
        set {
            let cleaned = newValue.trimmingCharacters(in: .whitespaces).lowercased()
            defaults.set(cleaned, forKey: Keys.userEmail)
        }
    }

    var userPasswordHash: String {
        get { defaults.string(forKey: Keys.userPasswordHash) ?? "" }
        set { defaults.set(newValue, forKey: Keys.userPasswordHash) }
    }

    // MARK: - Push Notifications

    var deviceToken: String? {
        get { defaults.string(forKey: Keys.deviceToken) }
        set { defaults.set(newValue, forKey: Keys.deviceToken) }
    }

    // MARK: - Computed Properties

    /// Whether saved credentials exist for auto-login.
    var hasCredentials: Bool {
        !userEmail.isEmpty && !userPasswordHash.isEmpty
    }

    /// Full base URL for API requests.
    var baseURL: String {
        let scheme = serverHTTPS ? "https" : "http"
        let host = serverURL.isEmpty ? Constants.defaultServerHost : serverURL
        let port = serverPort > 0 ? serverPort : Constants.defaultServerPort
        return "\(scheme)://\(host):\(port)"
    }

    // MARK: - Init

    private init() {
        serverHTTPS = defaults.object(forKey: Keys.serverHTTPS) as? Bool ?? Constants.defaultUseHTTPS
        serverURL = defaults.string(forKey: Keys.serverURL) ?? ""
        serverPort = defaults.object(forKey: Keys.serverPort) as? Int ?? 0
    }

    // MARK: - Methods

    /// Clear credentials on logout (keep server config and UUID).
    func logout() {
        defaults.removeObject(forKey: Keys.userEmail)
        defaults.removeObject(forKey: Keys.userPasswordHash)
    }

    /// Reset all settings to defaults.
    func reset() {
        defaults.removeObject(forKey: Keys.serverHTTPS)
        defaults.removeObject(forKey: Keys.serverURL)
        defaults.removeObject(forKey: Keys.serverPort)
        defaults.removeObject(forKey: Keys.deviceUUID)
        defaults.removeObject(forKey: Keys.userEmail)
        defaults.removeObject(forKey: Keys.userPasswordHash)
        defaults.removeObject(forKey: Keys.deviceToken)

        serverHTTPS = false
        serverURL = ""
        serverPort = 0
    }
}
