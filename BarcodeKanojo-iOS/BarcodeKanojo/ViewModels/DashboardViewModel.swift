import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var user: User?
    @Published var activities: [Activity] = []
    @Published var isLoading = false
    @Published var error: String?

    private let api = BarcodeKanojoAPI.shared

    func load(userId: Int) async {
        isLoading = true
        error = nil
        do {
            async let userResp = api.accountShow()
            async let timelineResp = api.userTimeline(userId: userId)
            let (u, t) = try await (userResp, timelineResp)
            user = u.user
            activities = t.activities ?? []
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func refresh(userId: Int) async {
        await load(userId: userId)
    }
}
