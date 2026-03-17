import Foundation

@MainActor
final class ScanViewModel: ObservableObject {

    /// Result context returned after a barcode query, capturing all server data.
    struct ScanResult: Equatable {
        var kanojo: Kanojo
        var product: Product?
        var ownerUser: User?
        var scanHistory: ScanHistory?

        /// Whether the current user owns this kanojo (relation == .kanojo).
        var isOwn: Bool {
            kanojo.relation == .kanojo
        }

        /// Whether this is a friend's kanojo (relation == .friend).
        var isFriend: Bool {
            kanojo.relation == .friend
        }
    }

    enum ScanState: Equatable {
        case idle
        case scanning
        case querying
        /// An existing kanojo was found for this barcode (own, friend, or other).
        case existingKanojo(ScanResult)
        /// No kanojo exists for this barcode — show generation form.
        case newBarcode(String)
        case generating
        /// A kanojo was just generated from the barcode.
        case generated(Kanojo)
        case error(String)
    }

    @Published var state: ScanState = .idle
    @Published var categories: [Category] = []

    private let api = BarcodeKanojoAPI.shared

    // MARK: - Barcode Query

    func handleScannedBarcode(_ barcode: String, format: String) async {
        state = .querying
        do {
            let response = try await api.barcodeQuery(barcode: barcode, format: format, extension: "")
            if let kanojo = response.kanojo {
                let result = ScanResult(
                    kanojo: kanojo,
                    product: response.product,
                    ownerUser: response.ownerUser,
                    scanHistory: response.scanHistory
                )
                state = .existingKanojo(result)
            } else {
                state = .newBarcode(barcode)
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Generate New Kanojo

    func generateKanojo(
        barcode: String,
        kanojoName: String,
        productName: String,
        companyName: String,
        categoryId: Int,
        comment: String,
        geo: String?
    ) async {
        state = .generating
        do {
            let response = try await api.barcodeScanAndGenerate(
                barcode: barcode,
                companyName: companyName.isEmpty ? nil : companyName,
                kanojoName: kanojoName.isEmpty ? nil : kanojoName,
                productName: productName.isEmpty ? nil : productName,
                productCategoryId: categoryId,
                productComment: comment.isEmpty ? nil : comment,
                productGeo: geo
            )
            if let kanojo = response.kanojo {
                state = .generated(kanojo)
            } else {
                state = .error(response.message ?? "Generation failed.")
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Categories

    func loadCategories() async {
        guard categories.isEmpty else { return }
        do {
            let response = try await api.productCategoryList()
            categories = response.categories ?? []
        } catch {}
    }

    func reset() {
        state = .idle
    }
}
