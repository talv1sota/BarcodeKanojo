import SwiftUI

/// Kanojo detail / info screen showing product info, stats, and activity timeline.
/// Accessible via the ⓘ button in KanojoRoomView.
struct KanojoInfoView: View {
    let kanojoId: Int

    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = KanojoInfoViewModel()
    @State private var showProductEdit = false

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = vm.error, vm.kanojo == nil {
                errorView(err)
            } else if let kanojo = vm.kanojo {
                ScrollView {
                    VStack(spacing: 20) {
                        productSection
                        kanojoDetailsSection(kanojo)
                        radarChartSection(kanojo)
                        activitySection
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle(vm.kanojo?.name ?? "Info")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(kanojoId: kanojoId) }
        .sheet(isPresented: $showProductEdit) {
            if let product = vm.product, let barcode = product.barcode ?? vm.kanojo?.barcode {
                ProductEditView(
                    product: product,
                    barcode: barcode,
                    categories: vm.categories
                ) { name, company, catId, comment, imageData in
                    Task {
                        let success = await vm.updateProduct(
                            barcode: barcode,
                            productName: name,
                            companyName: company,
                            categoryId: catId,
                            comment: comment,
                            imageData: imageData
                        )
                        if success { showProductEdit = false }
                    }
                }
            }
        }
    }

    // MARK: - Product Section

    private var productSection: some View {
        VStack(spacing: 12) {
            // Product image
            if let product = vm.product, let imgURL = product.productImageURL {
                AsyncCachedImage(
                    url: imgURL,
                    placeholder: Image(systemName: "shippingbox.fill")
                )
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Product details
            if let product = vm.product {
                VStack(spacing: 6) {
                    if let name = product.name, !name.isEmpty {
                        Text(name)
                            .font(.headline)
                    }
                    if let company = product.companyName, !company.isEmpty {
                        Text(company)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 16) {
                        if let cat = product.category, !cat.isEmpty {
                            Label(cat, systemImage: "tag.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if product.scanCount > 0 {
                            Label("\(product.scanCount) scans", systemImage: "barcode.viewfinder")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let barcode = product.barcode ?? vm.kanojo?.barcode {
                        Text(barcode)
                            .font(.caption.monospaced())
                            .foregroundStyle(.tertiary)
                    }

                    if let comment = product.comment, !comment.isEmpty {
                        Text(comment)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }

            // Edit button (only if user is the owner)
            if isOwner {
                Button {
                    showProductEdit = true
                } label: {
                    Label("Edit Product", systemImage: "pencil")
                        .font(.subheadline.bold())
                        .foregroundStyle(.pink)
                }
                .buttonStyle(.bordered)
                .tint(.pink)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Kanojo Details

    private func kanojoDetailsSection(_ kanojo: Kanojo) -> some View {
        VStack(spacing: 12) {
            Text("Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                detailCell(icon: "heart.fill", label: "Love", value: "\(kanojo.loveGauge)")
                detailCell(icon: "person.2.fill", label: "Followers", value: "\(kanojo.followerCount)")
                detailCell(icon: "hand.thumbsup.fill", label: "Likes", value: "\(kanojo.likeRate)")
                detailCell(icon: "face.smiling", label: "Emotion", value: emotionLabel(kanojo.emotionStatus))

                if kanojo.birthMonth > 0 && kanojo.birthDay > 0 {
                    detailCell(icon: "birthday.cake.fill", label: "Birthday", value: "\(kanojo.birthMonth)/\(kanojo.birthDay)")
                }

                if let location = kanojo.location, !location.isEmpty {
                    detailCell(icon: "mappin.circle.fill", label: "Location", value: location)
                }

                if let nationality = kanojo.nationality, !nationality.isEmpty {
                    detailCell(icon: "globe", label: "Origin", value: nationality)
                }
            }
        }
        .padding(.horizontal)
    }

    private func detailCell(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.pink)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.bold())
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Radar Chart

    private func radarChartSection(_ kanojo: Kanojo) -> some View {
        VStack(spacing: 8) {
            Text("Stats")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            RadarChartView(
                values: [
                    CGFloat(kanojo.flirtable),
                    CGFloat(kanojo.consumption),
                    CGFloat(kanojo.possession),
                    CGFloat(kanojo.recognition),
                    CGFloat(kanojo.sexual)
                ],
                labels: ["Flirt", "Consume", "Possess", "Recog", "Sexual"]
            )
            .frame(height: 220)
        }
        .padding(.horizontal)
    }

    // MARK: - Activity Timeline

    private var activitySection: some View {
        VStack(spacing: 12) {
            Text("Activity")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if vm.activities.isEmpty {
                Text("No activity yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(vm.activities) { activity in
                        ActivityRowView(activity: activity)
                            .padding(.vertical, 4)
                            .onAppear {
                                if activity.id == vm.activities.last?.id {
                                    Task { await vm.loadMoreActivities() }
                                }
                            }
                        if activity.id != vm.activities.last?.id {
                            Divider()
                        }
                    }
                }

                if vm.isLoadingMoreActivities {
                    ProgressView()
                        .padding()
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Error View

    private func errorView(_ err: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Failed to Load")
                .font(.headline)
            Text(err)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await vm.load(kanojoId: kanojoId) }
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var isOwner: Bool {
        guard let ownerUser = vm.ownerUser, let currentUser = auth.currentUser else { return false }
        return ownerUser.id == currentUser.id
    }

    private func emotionLabel(_ status: Int) -> String {
        switch status {
        case 0: return "Normal"
        case 1: return "Happy"
        case 2: return "Sad"
        case 3: return "Angry"
        case 4: return "Surprised"
        default: return "Unknown"
        }
    }
}
