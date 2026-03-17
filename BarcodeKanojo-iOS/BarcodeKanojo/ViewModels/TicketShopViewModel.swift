import Foundation

@MainActor
final class TicketShopViewModel: ObservableObject {

    @Published var categories: [KanojoItemCategory] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var purchaseResult: PurchaseResult?
    /// Local copy of user for balance tracking
    @Published var currentUser: User?

    struct PurchaseResult: Equatable {
        var success: Bool
        var message: String
    }

    private let api = BarcodeKanojoAPI.shared

    // MARK: - Load ticket items

    func load() async {
        isLoading = true
        error = nil
        do {
            // itemClass 3 = TICKET items, categoryId 0 = all categories
            let response = try await api.storeItems(itemClass: 3, itemCategoryId: 0)
            categories = response.itemCategories ?? []
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Purchase with tickets

    func purchase(item: KanojoItem, user: User?) async {
        guard let priceStr = item.price, let ticketCost = Int(priceStr) else {
            purchaseResult = PurchaseResult(success: false, message: "Invalid price.")
            return
        }

        // Client-side ticket balance check
        if let user = user ?? currentUser {
            guard user.tickets >= ticketCost else {
                purchaseResult = PurchaseResult(
                    success: false,
                    message: "Not enough tickets! Need \(ticketCost), have \(user.tickets)."
                )
                return
            }
        }

        // Optimistic local deduction
        if var u = currentUser ?? user {
            u.tickets -= ticketCost
            currentUser = u
        }

        do {
            // Step 1: Compare price (validation)
            let compareResponse = try await api.comparePrice(price: ticketCost, storeItemId: item.itemId)
            guard compareResponse.isSuccess else {
                // Refund local deduction
                refundTickets(ticketCost)
                purchaseResult = PurchaseResult(
                    success: false,
                    message: compareResponse.message ?? "Price validation failed."
                )
                return
            }

            // Step 2: Execute ticket purchase
            let ticketResponse = try await api.doTicket(storeItemId: item.itemId, useTickets: ticketCost)
            if ticketResponse.isSuccess {
                // Update local user from server response if available
                if let updatedUser = ticketResponse.user {
                    currentUser = updatedUser
                }
                purchaseResult = PurchaseResult(
                    success: true,
                    message: "Purchased \(item.title ?? "item") for \(ticketCost) tickets!"
                )
                // Reload to refresh inventory
                await load()
            } else {
                refundTickets(ticketCost)
                purchaseResult = PurchaseResult(
                    success: false,
                    message: ticketResponse.message ?? "Purchase failed."
                )
            }
        } catch {
            refundTickets(ticketCost)
            purchaseResult = PurchaseResult(success: false, message: error.localizedDescription)
        }
    }

    /// Refund tickets on failed purchase.
    private func refundTickets(_ amount: Int) {
        guard var user = currentUser else { return }
        user.tickets += amount
        currentUser = user
    }

    func dismissPurchaseResult() {
        purchaseResult = nil
    }
}
