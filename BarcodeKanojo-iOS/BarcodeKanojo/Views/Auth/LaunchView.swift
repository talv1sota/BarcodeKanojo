import SwiftUI

/// Boot screen — attempts auto-login then routes to Dashboard or Login.
struct LaunchView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            await auth.tryAutoLogin()
        }
    }
}
