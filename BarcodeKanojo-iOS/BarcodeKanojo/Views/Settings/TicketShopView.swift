import SwiftUI

/// Ticket shop for purchasing items with in-game tickets.
struct TicketShopView: View {
    @StateObject private var vm = TicketShopViewModel()
    @EnvironmentObject var auth: AuthViewModel
    @State private var selectedItem: KanojoItem?
    @State private var confirmPurchase = false

    var body: some View {
        Group {
            if vm.isLoading && vm.categories.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.categories.isEmpty {
                emptyState
            } else {
                itemList
            }
        }
        .navigationTitle("Ticket Shop")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Sync local user copy for balance tracking
            vm.currentUser = auth.currentUser
            await vm.load()
        }
        .alert(
            vm.purchaseResult?.success == true ? "Purchase Complete" : "Purchase Failed",
            isPresented: Binding(
                get: { vm.purchaseResult != nil },
                set: { if !$0 { vm.dismissPurchaseResult() } }
            )
        ) {
            Button("OK") { vm.dismissPurchaseResult() }
        } message: {
            Text(vm.purchaseResult?.message ?? "")
        }
        .confirmationDialog(
            "Confirm Purchase",
            isPresented: $confirmPurchase,
            presenting: selectedItem
        ) { item in
            Button("Buy for \(item.price ?? "?") tickets") {
                Task { await vm.purchase(item: item, user: auth.currentUser) }
            }
            Button("Cancel", role: .cancel) {
                selectedItem = nil
            }
        } message: { item in
            if let priceStr = item.price, let cost = Int(priceStr),
               let user = vm.currentUser ?? auth.currentUser,
               user.tickets < cost {
                Text("You need \(cost) tickets but only have \(user.tickets).")
            } else {
                Text(item.confirmPurchaseMessage ?? "Purchase \(item.title ?? "this item")?")
            }
        }
    }

    // MARK: - Item List

    private var itemList: some View {
        List {
            // User ticket balance header (uses VM's local copy for live updates)
            if let user = vm.currentUser ?? auth.currentUser {
                Section {
                    HStack {
                        Label("Your Tickets", systemImage: "ticket.fill")
                            .font(.headline)
                        Spacer()
                        Text("\(user.tickets)")
                            .font(.title2.bold())
                            .foregroundStyle(.purple)
                    }
                    .padding(.vertical, 4)
                }
            }

            ForEach(vm.categories, id: \.categoryId) { cat in
                Section(cat.title ?? "Items") {
                    ForEach(cat.items ?? [], id: \.itemId) { item in
                        TicketItemRow(item: item) {
                            selectedItem = item
                            confirmPurchase = true
                        }
                    }
                }
            }
        }
        .refreshable { await vm.load() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 56))
                .foregroundStyle(.purple.opacity(0.5))
            Text("No Items Available")
                .font(.title2.bold())
            Text("Check back later for ticket shop items.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Ticket Item Row

private struct TicketItemRow: View {
    let item: KanojoItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Item thumbnail
                AsyncCachedImage(url: item.imageThumbnailURL ?? "")
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title ?? "Item")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    if let desc = item.description, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if let level = item.purchasableLevel, !level.isEmpty {
                        Text("Requires Lv. \(level)")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                // Price badge
                if item.hasItem {
                    Text("Owned")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                } else if let price = item.price, !price.isEmpty {
                    VStack(spacing: 2) {
                        Image(systemName: "ticket.fill")
                            .font(.caption)
                        Text(price)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .disabled(item.hasItem)
    }
}
