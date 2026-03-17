import Foundation

@MainActor
final class KanojoInfoViewModel: ObservableObject {

    @Published var kanojo: Kanojo?
    @Published var product: Product?
    @Published var ownerUser: User?
    @Published var activities: [Activity] = []
    @Published var categories: [Category] = []

    @Published var isLoading = true
    @Published var isLoadingMoreActivities = false
    @Published var hasMoreActivities = true
    @Published var error: String?

    private let api = BarcodeKanojoAPI.shared
    private let pageSize = 20

    // MARK: - Load

    func load(kanojoId: Int) async {
        isLoading = true
        error = nil

        do {
            // Fetch kanojo details + product
            async let kanojoTask = api.kanojoShow(kanojoId: kanojoId)
            // Fetch initial activity timeline
            async let timelineTask = api.kanojoTimeline(kanojoId: kanojoId, index: 0, limit: pageSize)
            // Fetch product categories (for edit screen)
            async let categoriesTask = api.productCategoryList()

            let kanojoResponse = try await kanojoTask
            let timelineResponse = try await timelineTask
            let categoriesResponse = try await categoriesTask

            kanojo = kanojoResponse.kanojo
            product = kanojoResponse.product
            ownerUser = kanojoResponse.ownerUser
            activities = timelineResponse.activities ?? []
            hasMoreActivities = (timelineResponse.activities ?? []).count == pageSize
            categories = categoriesResponse.categories ?? []

            if kanojo == nil {
                self.error = "Kanojo not found (code \(kanojoResponse.code))."
            }
        } catch {
            print("❌ [KanojoInfoVM] load failed: \(error)")
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Load More Activities

    func loadMoreActivities() async {
        guard hasMoreActivities, !isLoadingMoreActivities, let kanojoId = kanojo?.id else { return }
        isLoadingMoreActivities = true

        do {
            let response = try await api.kanojoTimeline(
                kanojoId: kanojoId,
                index: activities.count,
                limit: pageSize
            )
            let page = response.activities ?? []
            activities.append(contentsOf: page)
            hasMoreActivities = page.count == pageSize
        } catch {
            print("❌ [KanojoInfoVM] loadMoreActivities failed: \(error)")
        }

        isLoadingMoreActivities = false
    }

    // MARK: - Update Product

    func updateProduct(
        barcode: String,
        productName: String?,
        companyName: String?,
        categoryId: Int,
        comment: String?,
        imageData: Data? = nil
    ) async -> Bool {
        do {
            let response = try await api.barcodeUpdate(
                barcode: barcode,
                companyName: companyName,
                productName: productName,
                productCategoryId: categoryId,
                productComment: comment,
                productImageData: imageData
            )
            if response.isSuccess {
                // Refresh product data
                product = response.product ?? product
                return true
            } else {
                self.error = response.message ?? "Update failed"
                return false
            }
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
}
