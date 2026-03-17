import SwiftUI

struct KanojosListView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = KanojosViewModel()

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab segmented picker
                Picker("", selection: $vm.selectedTab) {
                    ForEach(KanojosViewModel.Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Content for selected tab
                Group {
                    if vm.isCurrentLoading && vm.currentList.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let err = vm.error, vm.selectedTab == .mine {
                        errorView(err)
                    } else if vm.currentList.isEmpty {
                        emptyView
                    } else {
                        listContent
                    }
                }
            }
            .navigationTitle("Kanojos")
            .searchable(text: $vm.searchText, prompt: "Search kanojos")
            .onSubmit(of: .search) {
                Task { await vm.search() }
            }
            .onChange(of: vm.searchText) { new in
                if new.isEmpty { Task { await vm.search() } }
            }
            .task(id: auth.currentUser?.id) {
                if let id = auth.currentUser?.id {
                    if vm.kanojos.isEmpty {
                        print("[KanojosListView] .task loading kanojos for userId=\(id)")
                        await vm.load(userId: id)
                    }
                } else {
                    print("[KanojosListView] .task skipped: auth.currentUser is nil")
                }
            }
        }
    }

    // MARK: - List Grid

    private var listContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(vm.currentList.enumerated()), id: \.element.id) { index, kanojo in
                    NavigationLink(destination: KanojoRoomView(kanojoId: kanojo.id)) {
                        if vm.selectedTab == .ranking {
                            KanojoRankedGridCell(kanojo: kanojo, rank: index + 1)
                        } else {
                            KanojoGridCell(kanojo: kanojo)
                        }
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if kanojo.id == vm.currentList.last?.id {
                            Task { await vm.loadMore() }
                        }
                    }
                }
            }
            .padding()

            if vm.isCurrentLoadingMore {
                ProgressView().padding()
            }
        }
        .refreshable {
            KanojoThumbnailRenderer.shared.clearCache()
            if let id = auth.currentUser?.id {
                await vm.load(userId: id)
            }
        }
    }

    // MARK: - Empty State

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: emptyIcon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(emptyTitle)
                .font(.headline)
            Text(emptySubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyIcon: String {
        switch vm.selectedTab {
        case .mine: return "heart.slash"
        case .friends: return "person.2.slash"
        case .ranking: return "chart.bar"
        }
    }

    private var emptyTitle: String {
        switch vm.selectedTab {
        case .mine: return "No Kanojos"
        case .friends: return "No Friends' Kanojos"
        case .ranking: return "No Rankings"
        }
    }

    private var emptySubtitle: String {
        switch vm.selectedTab {
        case .mine: return "Scan a barcode to generate your first kanojo!"
        case .friends: return "Add friends to see their kanojos here."
        case .ranking: return "Rankings will appear here once kanojos are liked."
        }
    }

    // MARK: - Error State

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
                Task {
                    if let id = auth.currentUser?.id {
                        await vm.load(userId: id)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Grid Cells

private struct KanojoGridCell: View {
    let kanojo: Kanojo

    var body: some View {
        VStack(spacing: 6) {
            KanojoThumbnailView(kanojo: kanojo)
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(relationColor, lineWidth: 2)
                )

            Text(kanojo.name ?? "??")
                .font(.caption.bold())
                .lineLimit(1)

            LoveGaugeView(value: kanojo.loveGauge, showLabel: false)
                .frame(height: 6)
        }
    }

    private var relationColor: Color {
        switch kanojo.relation {
        case .kanojo: return .pink
        case .friend: return .blue
        default: return .gray.opacity(0.3)
        }
    }
}

/// Ranking tab cell — shows rank badge overlay.
private struct KanojoRankedGridCell: View {
    let kanojo: Kanojo
    let rank: Int

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topLeading) {
                KanojoThumbnailView(kanojo: kanojo)
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(rankColor, lineWidth: 2)
                    )

                // Rank badge
                Text("#\(rank)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(rankColor, in: Capsule())
                    .offset(x: -4, y: -4)
            }

            Text(kanojo.name ?? "??")
                .font(.caption.bold())
                .lineLimit(1)

            // Like count instead of love gauge for ranking
            HStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.pink)
                Text("\(kanojo.likeRate)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .pink.opacity(0.6)
        }
    }
}

/// Renders a kanojo Live2D model offscreen and displays the result as a static thumbnail.
/// Falls back to server-provided icon if Live2D rendering fails.
struct KanojoThumbnailView: View {
    let kanojo: Kanojo

    @State private var image: UIImage?
    @State private var triedLive2D = false

    private var avatarDataURL: URL? {
        Bundle.main.resourceURL?.appendingPathComponent("avatar_data")
    }

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                // Placeholder while rendering
                ZStack {
                    Color.pink.opacity(0.1)
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary.opacity(0.3))
                        .padding(20)
                }
            }
        }
        .task(id: kanojo.id) {
            guard image == nil else { return }

            // Try Live2D offscreen render first
            if let avatarDir = avatarDataURL {
                let rendered = await KanojoThumbnailRenderer.shared.thumbnail(
                    for: kanojo,
                    avatarDataDir: avatarDir
                )
                if let rendered {
                    image = rendered
                    return
                }
            }

            // Fallback: download server icon
            print("[KanojoThumb] Live2D render failed for \(kanojo.id), falling back to server icon")
            image = await ImageDownloader.shared.image(relativePath: kanojo.profileImageIconURL)
        }
    }
}
