import SwiftUI

/// Differentiated result screen shown after a barcode scan finds an existing kanojo.
/// Displays different UI based on whether the kanojo belongs to the current user,
/// a friend, or another player.
struct ScanResultView: View {
    let result: ScanViewModel.ScanResult
    let onVisitRoom: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            headerBar

            ScrollView {
                VStack(spacing: 20) {
                    // Kanojo card
                    kanojoCard

                    // Product info
                    if let product = result.product {
                        productSection(product)
                    }

                    // Scan stats
                    if let history = result.scanHistory {
                        scanStatsSection(history)
                    }

                    // Action buttons
                    actionButtons
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            relationBadge

            Spacer()

            // Balance spacer for xmark
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .hidden()
        }
        .padding()
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var relationBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: relationIcon)
                .foregroundStyle(relationColor)
            Text(relationLabel)
                .font(.headline)
        }
    }

    // MARK: - Kanojo Card

    private var kanojoCard: some View {
        VStack(spacing: 12) {
            // Thumbnail
            KanojoThumbnailView(kanojo: result.kanojo)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

            // Name
            Text(result.kanojo.name ?? "Unknown Kanojo")
                .font(.title2.bold())

            // Owner info
            if let owner = result.ownerUser {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text("Owner: \(owner.name ?? "Unknown")")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }

            // Love gauge + relation
            HStack(spacing: 16) {
                // Love gauge
                VStack(spacing: 2) {
                    Text("\(result.kanojo.loveGauge)")
                        .font(.title3.bold())
                        .foregroundStyle(.pink)
                    Text("Love")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider().frame(height: 30)

                // Followers
                VStack(spacing: 2) {
                    Text("\(result.kanojo.followerCount)")
                        .font(.title3.bold())
                    Text("Followers")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider().frame(height: 30)

                // Like rate
                VStack(spacing: 2) {
                    Text("\(result.kanojo.likeRate)")
                        .font(.title3.bold())
                    Text("Likes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Product Section

    private func productSection(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Product Info", systemImage: "barcode")
                .font(.headline)

            VStack(spacing: 6) {
                if let name = product.name, !name.isEmpty {
                    infoRow(label: "Product", value: name)
                }
                if let company = product.companyName, !company.isEmpty {
                    infoRow(label: "Company", value: company)
                }
                if let category = product.category, !category.isEmpty {
                    infoRow(label: "Category", value: category)
                }
                if let barcode = product.barcode {
                    infoRow(label: "Barcode", value: barcode, monospaced: true)
                }
                if let country = product.country, !country.isEmpty {
                    infoRow(label: "Country", value: country)
                }
                if product.scanCount > 0 {
                    infoRow(label: "Total Scans", value: "\(product.scanCount)")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func infoRow(label: String, value: String, monospaced: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(monospaced ? .subheadline.monospaced() : .subheadline)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Scan Stats

    private func scanStatsSection(_ history: ScanHistory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Scan History", systemImage: "chart.bar")
                .font(.headline)

            HStack(spacing: 0) {
                statBubble(value: history.totalCount, label: "Total Scans", color: .blue)
                statBubble(value: history.kanojoCount, label: "Your Scans", color: .pink)
                statBubble(value: history.friendCount, label: "Friend Scans", color: .orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statBubble(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary action
            Button(action: onVisitRoom) {
                HStack {
                    Image(systemName: primaryButtonIcon)
                    Text(primaryButtonLabel)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)

            // Secondary: scan again
            Button(action: onDismiss) {
                HStack {
                    Image(systemName: "barcode.viewfinder")
                    Text("Scan Another")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Helpers

    private var relationLabel: String {
        if result.isOwn { return "Your Kanojo" }
        if result.isFriend { return "Friend's Kanojo" }
        return "Someone's Kanojo"
    }

    private var relationIcon: String {
        if result.isOwn { return "heart.fill" }
        if result.isFriend { return "person.2.fill" }
        return "person.fill"
    }

    private var relationColor: Color {
        if result.isOwn { return .pink }
        if result.isFriend { return .orange }
        return .secondary
    }

    private var primaryButtonLabel: String {
        if result.isOwn { return "Visit Room" }
        if result.isFriend { return "Visit Friend's Kanojo" }
        return "View Kanojo"
    }

    private var primaryButtonIcon: String {
        if result.isOwn { return "house.fill" }
        if result.isFriend { return "figure.walk" }
        return "eye.fill"
    }
}
