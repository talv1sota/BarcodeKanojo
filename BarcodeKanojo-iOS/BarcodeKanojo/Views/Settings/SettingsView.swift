import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showServerConfig = false
    @State private var showLogoutConfirm = false

    var body: some View {
        Form {
            if let user = auth.currentUser {
                Section("Account") {
                    HStack(spacing: 12) {
                        AsyncCachedImage(url: user.profileImageURL)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(user.name ?? "Player")
                                .font(.headline)
                            Text(AppSettings.shared.userEmail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    LabeledContent("Level", value: "\(user.level)")
                    LabeledContent("Scans", value: "\(user.scanCount)")
                    LabeledContent("Kanojos", value: "\(user.kanojoCount)")

                    NavigationLink {
                        ProfileEditView()
                    } label: {
                        Label("Edit Profile", systemImage: "pencil.circle.fill")
                    }

                    NavigationLink {
                        TicketShopView()
                    } label: {
                        Label("Ticket Shop", systemImage: "ticket.fill")
                    }
                }
            }

            Section("Notifications") {
                NotificationStatusRow()
            }

            Section("Server") {
                Button("Server Configuration") {
                    showServerConfig = true
                }
                LabeledContent("URL", value: AppSettings.shared.baseURL)
                    .font(.caption)
            }

            Section {
                Button("Log Out", role: .destructive) {
                    showLogoutConfirm = true
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showServerConfig) {
            ServerConfigView()
        }
        .confirmationDialog("Log out?", isPresented: $showLogoutConfirm) {
            Button("Log Out", role: .destructive) {
                auth.logout()
            }
        }
    }
}

// MARK: - Notification Status Row

/// Shows push notification authorization status with an option to open Settings.
private struct NotificationStatusRow: View {
    @State private var status: UNAuthorizationStatus = .notDetermined

    var body: some View {
        HStack {
            Label("Push Notifications", systemImage: statusIcon)
            Spacer()
            Text(statusLabel)
                .font(.subheadline)
                .foregroundStyle(statusColor)
        }
        .task {
            PushNotificationManager.checkStatus { s in
                status = s
            }
        }

        if status == .denied {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.subheadline)
        } else if status == .notDetermined {
            Button("Enable Notifications") {
                PushNotificationManager.requestAuthorization()
                // Re-check after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    PushNotificationManager.checkStatus { s in
                        status = s
                    }
                }
            }
            .font(.subheadline)
        }
    }

    private var statusIcon: String {
        switch status {
        case .authorized, .provisional, .ephemeral: return "bell.badge.fill"
        case .denied: return "bell.slash.fill"
        case .notDetermined: return "bell.fill"
        @unknown default: return "bell.fill"
        }
    }

    private var statusLabel: String {
        switch status {
        case .authorized, .provisional, .ephemeral: return "Enabled"
        case .denied: return "Disabled"
        case .notDetermined: return "Not Set"
        @unknown default: return "Unknown"
        }
    }

    private var statusColor: Color {
        switch status {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        @unknown default: return .secondary
        }
    }
}
