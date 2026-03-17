import Foundation

/// Represents an enemy user derived from rivalry activities.
struct Enemy: Identifiable, Hashable {
    let id: Int  // user id
    let user: User
    let reason: EnemyReason
    let kanojo: Kanojo?
    let timestamp: Int

    enum EnemyReason: String {
        case stolenByThem = "Stole your kanojo"
        case stolenByYou = "You stole their kanojo"
        case addedAsEnemy = "Marked as enemy"
    }
}

@MainActor
final class EnemyBookViewModel: ObservableObject {

    @Published var enemies: [Enemy] = []
    @Published var isLoading = false
    @Published var hasMore = true
    @Published var error: String?

    private let api = BarcodeKanojoAPI.shared
    private let pageSize = 50
    private var currentIndex = 0

    /// Enemy activity types we want to filter for
    private let enemyTypes: Set<Int> = [
        ActivityType.meStolenKanojo.rawValue,   // 8 — I stole someone's kanojo
        ActivityType.myKanojoStolen.rawValue,    // 9 — Someone stole my kanojo
        ActivityType.addAsEnemy.rawValue         // 103 — Added as enemy
    ]

    func load(userId: Int) async {
        isLoading = true
        error = nil
        currentIndex = 0
        enemies = []

        do {
            // Load a large chunk of timeline to find enemy activities
            let response = try await api.userTimeline(userId: userId, index: 0, limit: pageSize)
            let activities = response.activities ?? []
            let enemyActivities = activities.filter { enemyTypes.contains($0.activityType) }
            enemies = deduplicateEnemies(from: enemyActivities)
            currentIndex = activities.count
            hasMore = activities.count == pageSize
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadMore(userId: Int) async {
        guard hasMore, !isLoading else { return }
        isLoading = true

        do {
            let response = try await api.userTimeline(userId: userId, index: currentIndex, limit: pageSize)
            let activities = response.activities ?? []
            let enemyActivities = activities.filter { enemyTypes.contains($0.activityType) }
            let newEnemies = deduplicateEnemies(from: enemyActivities)

            // Merge with existing, keeping unique by user id
            let existingIds = Set(enemies.map(\.id))
            enemies.append(contentsOf: newEnemies.filter { !existingIds.contains($0.id) })

            currentIndex += activities.count
            hasMore = activities.count == pageSize
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// Deduplicate activities into unique enemy users (keep the most recent encounter per user).
    private func deduplicateEnemies(from activities: [Activity]) -> [Enemy] {
        var seen: [Int: Enemy] = [:]

        for activity in activities {
            // Determine the enemy user: for "my kanojo stolen" it's the other user;
            // for "I stole kanojo" it's the other user
            guard let enemyUser = activity.otherUser ?? activity.user else { continue }
            let userId = enemyUser.id

            let reason: Enemy.EnemyReason
            switch activity.type {
            case .myKanojoStolen:
                reason = .stolenByThem
            case .meStolenKanojo:
                reason = .stolenByYou
            case .addAsEnemy:
                reason = .addedAsEnemy
            default:
                continue
            }

            // Keep the most recent entry per enemy
            if let existing = seen[userId] {
                if activity.createdTimestamp > existing.timestamp {
                    seen[userId] = Enemy(
                        id: userId,
                        user: enemyUser,
                        reason: reason,
                        kanojo: activity.kanojo,
                        timestamp: activity.createdTimestamp
                    )
                }
            } else {
                seen[userId] = Enemy(
                    id: userId,
                    user: enemyUser,
                    reason: reason,
                    kanojo: activity.kanojo,
                    timestamp: activity.createdTimestamp
                )
            }
        }

        return Array(seen.values).sorted { $0.timestamp > $1.timestamp }
    }
}
