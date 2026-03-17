import UIKit
import UserNotifications

/// UIApplicationDelegate for push notification registration.
/// Handles device token registration with the server and notification center setup.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - Push Notification Registration

    /// Called after successfully registering for remote notifications.
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert token to hex string
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("[Push] Registered device token: \(tokenString)")

        // Save locally
        AppSettings.shared.deviceToken = tokenString

        // Register with server
        Task { @MainActor in
            do {
                let uuid = AppSettings.shared.deviceUUID
                _ = try await BarcodeKanojoAPI.shared.registerDeviceToken(uuid: uuid, deviceToken: tokenString)
                print("[Push] Token registered with server")
            } catch {
                print("[Push] Failed to register token with server: \(error)")
            }
        }
    }

    /// Called when remote notification registration fails.
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[Push] Registration failed: \(error.localizedDescription)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notification when app is in foreground — show as banner.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap — navigate to relevant screen.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("[Push] Notification tapped with userInfo: \(userInfo)")

        // Post a notification for deep linking
        // The main app can observe this to navigate to the appropriate screen
        NotificationCenter.default.post(
            name: .pushNotificationTapped,
            object: nil,
            userInfo: userInfo
        )

        completionHandler()
    }
}

// MARK: - Push Notification Manager

/// Manages push notification permissions and registration.
enum PushNotificationManager {

    /// Request notification permission and register for remote notifications.
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error = error {
                print("[Push] Authorization error: \(error)")
                return
            }

            if granted {
                print("[Push] Authorization granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("[Push] Authorization denied")
            }
        }
    }

    /// Check current notification authorization status.
    static func checkStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    /// Posted when a push notification is tapped while the app is running.
    /// UserInfo contains the push payload for deep linking.
    static let pushNotificationTapped = Notification.Name("pushNotificationTapped")
}
