import Foundation

@MainActor
final class KanojosViewModel: ObservableObject {

    // MARK: - Tab Selection

    enum Tab: String, CaseIterable {
        case mine = "Mine"
        case friends = "Friends"
        case ranking = "Ranking"
    }

    @Published var selectedTab: Tab = .mine

    // MARK: - Mine

    @Published var kanojos: [Kanojo] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = true

    // MARK: - Friends

    @Published var friendKanojos: [Kanojo] = []
    @Published var isLoadingFriends = false
    @Published var isLoadingMoreFriends = false
    @Published var hasMoreFriends = true

    // MARK: - Ranking

    @Published var rankingKanojos: [Kanojo] = []
    @Published var isLoadingRanking = false
    @Published var isLoadingMoreRanking = false
    @Published var hasMoreRanking = true

    // MARK: - Shared

    @Published var error: String?
    @Published var searchText = ""

    private let api = BarcodeKanojoAPI.shared
    private let pageSize = 20
    private var userId: Int = 0

    // MARK: - Initial Load

    func load(userId: Int) async {
        self.userId = userId
        error = nil

        // Reset all three lists
        kanojos = []
        friendKanojos = []
        rankingKanojos = []
        hasMore = true
        hasMoreFriends = true
        hasMoreRanking = true

        // Fetch all three concurrently
        isLoading = true
        isLoadingFriends = true
        isLoadingRanking = true

        async let mineTask: () = fetchMine(index: 0, reset: true)
        async let friendsTask: () = fetchFriends(index: 0, reset: true)
        async let rankingTask: () = fetchRanking(index: 0, reset: true)

        _ = await (mineTask, friendsTask, rankingTask)
    }

    // MARK: - Pagination

    func loadMoreMine() async {
        guard hasMore, !isLoadingMore else { return }
        await fetchMine(index: kanojos.count, reset: false)
    }

    func loadMoreFriends() async {
        guard hasMoreFriends, !isLoadingMoreFriends else { return }
        await fetchFriends(index: friendKanojos.count, reset: false)
    }

    func loadMoreRanking() async {
        guard hasMoreRanking, !isLoadingMoreRanking else { return }
        await fetchRanking(index: rankingKanojos.count, reset: false)
    }

    /// Load more for the currently selected tab.
    func loadMore() async {
        switch selectedTab {
        case .mine: await loadMoreMine()
        case .friends: await loadMoreFriends()
        case .ranking: await loadMoreRanking()
        }
    }

    // MARK: - Search (mine tab only)

    func search() async {
        kanojos = []
        hasMore = true
        await fetchMine(index: 0, reset: true)
    }

    // MARK: - Private Fetch

    private func fetchMine(index: Int, reset: Bool) async {
        if reset { isLoading = true } else { isLoadingMore = true }
        print("[KanojosVM] fetchMine(index=\(index), reset=\(reset), userId=\(userId))")
        do {
            let response = try await api.currentKanojos(
                userId: userId,
                index: index,
                limit: pageSize,
                search: searchText.isEmpty ? nil : searchText
            )
            let page = response.currentKanojos ?? []
            print("[KanojosVM] Got \(page.count) mine kanojos")
            if reset { kanojos = page } else { kanojos.append(contentsOf: page) }
            hasMore = page.count == pageSize
        } catch {
            print("❌ [KanojosVM] fetchMine failed: \(error)")
            if reset { self.error = error.localizedDescription }
        }
        isLoading = false
        isLoadingMore = false
    }

    private func fetchFriends(index: Int, reset: Bool) async {
        if reset { isLoadingFriends = true } else { isLoadingMoreFriends = true }
        print("[KanojosVM] fetchFriends(index=\(index), reset=\(reset), userId=\(userId))")
        do {
            let response = try await api.friendKanojos(
                userId: userId,
                index: index,
                limit: pageSize,
                search: searchText.isEmpty ? nil : searchText
            )
            let page = response.friendKanojos ?? []
            print("[KanojosVM] Got \(page.count) friend kanojos")
            if reset { friendKanojos = page } else { friendKanojos.append(contentsOf: page) }
            hasMoreFriends = page.count == pageSize
        } catch {
            print("❌ [KanojosVM] fetchFriends failed: \(error)")
        }
        isLoadingFriends = false
        isLoadingMoreFriends = false
    }

    private func fetchRanking(index: Int, reset: Bool) async {
        if reset { isLoadingRanking = true } else { isLoadingMoreRanking = true }
        print("[KanojosVM] fetchRanking(index=\(index), reset=\(reset))")
        do {
            let response = try await api.likeRanking(
                index: index,
                limit: pageSize
            )
            let page = response.likeRankingKanojos ?? []
            print("[KanojosVM] Got \(page.count) ranking kanojos")
            if reset { rankingKanojos = page } else { rankingKanojos.append(contentsOf: page) }
            hasMoreRanking = page.count == pageSize
        } catch {
            print("❌ [KanojosVM] fetchRanking failed: \(error)")
        }
        isLoadingRanking = false
        isLoadingMoreRanking = false
    }

    // MARK: - Convenience Accessors

    /// Kanojos for the currently selected tab.
    var currentList: [Kanojo] {
        switch selectedTab {
        case .mine: return kanojos
        case .friends: return friendKanojos
        case .ranking: return rankingKanojos
        }
    }

    var isCurrentLoading: Bool {
        switch selectedTab {
        case .mine: return isLoading
        case .friends: return isLoadingFriends
        case .ranking: return isLoadingRanking
        }
    }

    var isCurrentLoadingMore: Bool {
        switch selectedTab {
        case .mine: return isLoadingMore
        case .friends: return isLoadingMoreFriends
        case .ranking: return isLoadingMoreRanking
        }
    }
}
