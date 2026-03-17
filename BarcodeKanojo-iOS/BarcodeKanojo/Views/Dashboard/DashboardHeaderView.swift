import SwiftUI

struct DashboardHeaderView: View {
    let user: User

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Avatar
                AsyncCachedImage(url: user.profileImageURL)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.pink, lineWidth: 2))

                // Name + level
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name ?? "Player")
                        .font(.headline)
                    Text("Level \(user.level)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()

            // Stats row
            HStack(spacing: 0) {
                StatCell(icon: "bolt.fill", label: "Stamina", value: "\(user.stamina)/\(user.staminaMax)")
                Divider().frame(height: 40)
                StatCell(icon: "yensign.circle.fill", label: "Money", value: "\(user.money)")
                Divider().frame(height: 40)
                StatCell(icon: "ticket.fill", label: "Tickets", value: "\(user.tickets)")
                Divider().frame(height: 40)
                StatCell(icon: "heart.fill", label: "Kanojos", value: "\(user.kanojoCount)")
            }
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
}

private struct StatCell: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.pink)
            Text(value)
                .font(.caption.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
