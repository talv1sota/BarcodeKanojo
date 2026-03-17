import SwiftUI

@main
struct BarcodeKanojoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environmentObject(auth)
                .onAppear {
                    // Request push notification permission after first launch
                    PushNotificationManager.requestAuthorization()
                }
        }
    }
}
