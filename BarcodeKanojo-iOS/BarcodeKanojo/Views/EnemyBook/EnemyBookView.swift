import SwiftUI

/// Enemy book — tracks rival players who have stolen kanojos or been marked as enemies.
struct EnemyBookView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = EnemyBookViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.enemies.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.enemies.isEmpty {
                    emptyState
                } else {
                    enemyList
                }
            }
            .navigationTitle("Enemy Book")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: auth.currentUser?.id) {
                if let id = auth.currentUser?.id {
                    await vm.load(userId: id)
                }
            }
            .refreshable {
                if let id = auth.currentUser?.id {
                    await vm.load(userId: id)
                }
            }
        }
    }

    // MARK: - Enemy List

    private var enemyList: some View {
        List {
            ForEach(vm.enemies) { enemy in
                EnemyRowView(enemy: enemy)
            }

            // Load more
            if vm.hasMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .task {
                    if let id = auth.currentUser?.id {
                        await vm.loadMore(userId: id)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No Enemies Yet")
                .font(.title2.bold())
            Text("When other players steal your kanojos (or you steal theirs), they'll appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Enemy Row

private struct EnemyRowView: View {
    let enemy: Enemy

    var body: some View {
        HStack(spacing: 12) {
            // User avatar
            AsyncCachedImage(url: enemy.user.profileImageURL)
                .frame(width: 48, height: 48)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(enemy.user.name ?? "Unknown Rival")
                    .font(.headline)

                HStack(spacing: 6) {
                    Image(systemName: reasonIcon)
                        .font(.caption)
                        .foregroundStyle(reasonColor)
                    Text(enemy.reason.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Kanojo involved
                if let kanojo = enemy.kanojo, let name = kanojo.name {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text(name)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Time
            Text(timeAgo)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var reasonIcon: String {
        switch enemy.reason {
        case .stolenByThem: return "exclamationmark.triangle.fill"
        case .stolenByYou: return "hand.raised.fill"
        case .addedAsEnemy: return "xmark.shield.fill"
        }
    }

    private var reasonColor: Color {
        switch enemy.reason {
        case .stolenByThem: return .red
        case .stolenByYou: return .orange
        case .addedAsEnemy: return .purple
        }
    }

    private var timeAgo: String {
        let date = Date(timeIntervalSince1970: TimeInterval(enemy.timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
