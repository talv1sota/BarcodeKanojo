import SwiftUI

/// Main kanojo interaction screen.
/// Phase 6: Greeting bubble + stamina enforcement.
/// Phase 10: Tutorial overlay + visit mode for friend/other kanojos.
struct KanojoRoomView: View {
    let kanojoId: Int

    @StateObject private var vm = KanojoRoomViewModel()
    @State private var showDateMenu = false
    @State private var showGiftMenu = false
    @State private var showRadarChart = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false

    /// Whether this kanojo belongs to the current user.
    private var isOwnKanojo: Bool {
        vm.kanojo?.relation == .kanojo
    }

    /// Whether this kanojo belongs to a friend.
    private var isFriendKanojo: Bool {
        vm.kanojo?.relation == .friend
    }

    /// Whether user is visiting (not their own kanojo).
    private var isVisiting: Bool {
        guard let k = vm.kanojo else { return false }
        return k.relation != .kanojo
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let kanojo = vm.kanojo {
                ZStack {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Visit banner for non-owned kanojos
                            if isVisiting {
                                VisitBanner(
                                    ownerName: vm.ownerUser?.name,
                                    isFriend: isFriendKanojo
                                )
                            }

                            // Avatar area — Live2D if available, fallback to profile image
                            ZStack {
                                KanojoAvatarView(kanojo: kanojo) { region in
                                    Task { await vm.playOnLive2d(region: region) }
                                }

                                // On-date overlay
                                if vm.isOnDate {
                                    VStack {
                                        Spacer()
                                        OnDateBanner(cost: vm.lastItemCost)
                                            .padding(.bottom, 16)
                                    }
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
                            .frame(height: 400)
                            .animation(.easeInOut(duration: 0.4), value: vm.isOnDate)

                            // Info panel
                            VStack(spacing: 16) {
                                // Name + relation badge
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(kanojo.name ?? "Unknown")
                                            .font(.title2.bold())
                                        if let rel = kanojo.relation {
                                            RelationBadge(status: rel)
                                        }
                                    }
                                    Spacer()
                                    // Like button
                                    Button {
                                        Task { await vm.voteLike() }
                                    } label: {
                                        Image(systemName: kanojo.votedLike ? "heart.fill" : "heart")
                                            .font(.title2)
                                            .foregroundStyle(kanojo.votedLike ? .pink : .secondary)
                                    }
                                }

                                // Love gauge
                                LoveGaugeView(value: kanojo.loveGauge)

                                // Stamina bar (only for own kanojo)
                                if isOwnKanojo, let user = vm.ownerUser {
                                    StaminaBarView(current: user.stamina, max: user.staminaMax)
                                }

                                // Stats
                                HStack {
                                    StatPill(icon: "person.2.fill", value: "\(kanojo.followerCount)", label: "Followers")
                                    StatPill(icon: "heart.fill", value: "\(kanojo.likeRate)", label: "Likes")
                                }

                                // Radar chart (collapsible)
                                VStack(spacing: 0) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            showRadarChart.toggle()
                                        }
                                    } label: {
                                        HStack {
                                            Text("Stats")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.caption.bold())
                                                .foregroundStyle(.secondary)
                                                .rotationEffect(.degrees(showRadarChart ? 180 : 0))
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.plain)

                                    if showRadarChart {
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
                                        .frame(height: 200)
                                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                    }
                                }

                                // User balance (only for own kanojo)
                                if isOwnKanojo, let user = vm.ownerUser {
                                    HStack(spacing: 16) {
                                        Label("\(user.money)", systemImage: "yensign.circle.fill")
                                            .font(.caption.bold())
                                            .foregroundStyle(.orange)
                                        Label("\(user.tickets)", systemImage: "ticket.fill")
                                            .font(.caption.bold())
                                            .foregroundStyle(.purple)
                                    }
                                }

                                Divider()

                                // Action buttons — different for own vs visiting
                                if isOwnKanojo {
                                    // Own kanojo: Date + Gift (grayed out when no stamina or on date)
                                    HStack(spacing: 12) {
                                        ActionButton(
                                            icon: "calendar.badge.plus",
                                            label: vm.isOnDate ? "On Date..." : "Date",
                                            disabled: !vm.hasStamina || vm.isOnDate
                                        ) {
                                            showDateMenu = true
                                        }
                                        ActionButton(
                                            icon: "gift.fill",
                                            label: "Gift",
                                            disabled: !vm.hasStamina || vm.isOnDate
                                        ) {
                                            showGiftMenu = true
                                        }
                                    }
                                } else {
                                    // Visiting: Gift + Like only (no dating someone else's kanojo)
                                    HStack(spacing: 12) {
                                        ActionButton(
                                            icon: "gift.fill",
                                            label: "Gift",
                                            color: .blue,
                                            disabled: !vm.hasStamina || vm.isOnDate
                                        ) {
                                            showGiftMenu = true
                                        }
                                        ActionButton(
                                            icon: "heart.fill",
                                            label: kanojo.votedLike ? "Liked" : "Like",
                                            color: kanojo.votedLike ? .gray : .orange,
                                            disabled: kanojo.votedLike
                                        ) {
                                            Task { await vm.voteLike() }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }

                    // Greeting speech bubble overlay (auto-dismisses on tap or after 3s)
                    if let greeting = vm.greetingMessage {
                        GreetingBubble(
                            kanojoName: kanojo.name ?? "Kanojo",
                            message: greeting
                        ) {
                            vm.dismissGreeting()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Dialogue overlay — shown after date/gift action
                    if vm.showDialogue {
                        DialogueOverlay(
                            kanojoName: kanojo.name ?? "Kanojo",
                            messages: vm.kanojoMessage?.messages ?? [],
                            loveIncrement: vm.loveIncrement
                        ) {
                            vm.dismissDialogue()
                        }
                    }

                    // Tutorial overlay (first room visit)
                    if showTutorial {
                        TutorialOverlayView {
                            withAnimation {
                                showTutorial = false
                                hasSeenTutorial = true
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: vm.greetingMessage != nil)
                .animation(.easeInOut(duration: 0.3), value: showTutorial)
            } else if let err = vm.error {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Couldn't Load")
                        .font(.headline)
                    Text(err)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(vm.kanojo?.name ?? "Kanojo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: KanojoInfoView(kanojoId: kanojoId)) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.pink)
                }
            }
        }
        .task {
            await vm.load(kanojoId: kanojoId)
            // Show tutorial on first-ever room entry
            if !hasSeenTutorial && vm.kanojo != nil {
                showTutorial = true
            }
        }
        .sheet(isPresented: $showDateMenu) {
            DateGiftMenuView(kanojoId: kanojoId, mode: .date) { item in
                let cost = Int(item.price ?? "0") ?? 0
                Task { await vm.doDate(basicItemId: item.itemId, itemCost: cost) }
            }
        }
        .sheet(isPresented: $showGiftMenu) {
            DateGiftMenuView(kanojoId: kanojoId, mode: .gift) { item in
                let cost = Int(item.price ?? "0") ?? 0
                Task { await vm.doGift(basicItemId: item.itemId, itemCost: cost) }
            }
        }
        .alert("Not Enough Stamina", isPresented: Binding(
            get: { vm.staminaError != nil },
            set: { if !$0 { vm.dismissStaminaError() } }
        )) {
            Button("OK") { vm.dismissStaminaError() }
        } message: {
            Text(vm.staminaError ?? "")
        }
        .alert("Not Enough Money", isPresented: Binding(
            get: { vm.moneyError != nil },
            set: { if !$0 { vm.dismissMoneyError() } }
        )) {
            Button("OK") { vm.dismissMoneyError() }
        } message: {
            Text(vm.moneyError ?? "")
        }
    }
}

// MARK: - Dialogue Overlay

/// Full-screen overlay showing kanojo dialogue messages after a date/gift action.
/// Tap to advance through messages, then dismiss.
private struct DialogueOverlay: View {
    let kanojoName: String
    let messages: [String]
    let loveIncrement: LoveIncrement?
    let onDismiss: () -> Void

    @State private var currentIndex = 0

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { advance() }

            VStack(spacing: 16) {
                Spacer()

                // Love increment banner
                if let inc = loveIncrement, inc.increaseLove != "0" {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                        Text("+\(inc.increaseLove) love")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.pink.opacity(0.8), in: Capsule())
                }

                // Speech bubble
                if !messages.isEmpty, currentIndex < messages.count {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(kanojoName)
                            .font(.caption.bold())
                            .foregroundStyle(.pink)

                        Text(messages[currentIndex])
                            .font(.body)
                            .foregroundStyle(.primary)

                        HStack {
                            Spacer()
                            if currentIndex < messages.count - 1 {
                                Text("Tap to continue ▸")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Tap to close")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .onTapGesture { advance() }
                } else {
                    // No messages, just love display — tap to dismiss
                    Text("Tap to close")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()
                    .frame(height: 60)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentIndex)
    }

    private func advance() {
        if currentIndex < messages.count - 1 {
            currentIndex += 1
        } else {
            onDismiss()
        }
    }
}

// MARK: - Avatar View (Live2D or fallback)

private struct KanojoAvatarView: View {
    let kanojo: Kanojo
    var onTouch: ((TouchRegion) -> Void)?

    private var avatarDataURL: URL? {
        Bundle.main.resourceURL?.appendingPathComponent("avatar_data")
    }

    private var hasAvatarData: Bool {
        guard let url = avatarDataURL else { return false }
        return FileManager.default.fileExists(atPath: url.appendingPathComponent("kanojoBaseModel.moc").path)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.pink.opacity(0.2), Color.purple.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )

            if hasAvatarData, let avatarURL = avatarDataURL {
                KanojoLive2DView(
                    kanojoData: kanojo.toLive2DDict(),
                    avatarDataDir: avatarURL,
                    onTouch: onTouch
                )
            } else {
                AsyncCachedImage(
                    url: kanojo.profileImageURL,
                    placeholder: Image(systemName: "person.fill")
                )
                .frame(width: 240, height: 280)
                .scaledToFit()
            }
        }
    }
}

// MARK: - Kanojo Live2D data extension

extension Kanojo {
    func toLive2DDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["hair_type"] = hairType
        dict["face_type"] = faceType
        dict["eye_type"] = eyeType
        dict["brow_type"] = browType
        dict["mouth_type"] = mouthType
        dict["nose_type"] = noseType
        dict["ear_type"] = earType
        dict["fringe_type"] = fringeType
        dict["body_type"] = bodyType
        dict["clothes_type"] = clothesType
        dict["glasses_type"] = glassesType
        dict["accessory_type"] = accessoryType
        dict["skin_color"] = skinColor
        dict["hair_color"] = hairColor
        dict["eye_color"] = eyeColor
        dict["eye_position"] = eyePosition
        dict["brow_position"] = browPosition
        dict["mouth_position"] = mouthPosition
        dict["love_gauge"] = Double(loveGauge)
        dict["relation_status"] = relationStatus
        return dict
    }
}

// MARK: - Sub-views

private struct RelationBadge: View {
    let status: RelationStatus

    var body: some View {
        Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .kanojo: return "Kanojo"
        case .friend: return "Friend"
        case .other: return "Other"
        }
    }

    private var color: Color {
        switch status {
        case .kanojo: return .pink
        case .friend: return .blue
        case .other: return .gray
        }
    }
}

private struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(.pink)
            Text(value).font(.caption.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6), in: Capsule())
    }
}

private struct ActionButton: View {
    let icon: String
    let label: String
    var color: Color = .pink
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(disabled ? Color.gray.opacity(0.1) : color.opacity(0.1))
            .foregroundStyle(disabled ? .gray : color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(disabled)
    }
}

// MARK: - On Date Banner

/// Animated banner shown while the kanojo is on a date.
private struct OnDateBanner: View {
    let cost: Int?

    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.circle.fill")
                .font(.title3)
                .scaleEffect(heartScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        heartScale = 1.25
                    }
                }
            Text("On a Date...")
                .font(.headline.bold())
            if let cost, cost > 0 {
                Text("(-\(cost)¥)")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.pink, in: Capsule())
        .shadow(color: .pink.opacity(0.4), radius: 8, y: 2)
    }
}

// MARK: - Visit Banner

/// Banner shown when visiting a friend's or other player's kanojo room.
private struct VisitBanner: View {
    let ownerName: String?
    let isFriend: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isFriend ? "person.2.fill" : "eye.fill")
                .font(.caption)
            Text(bannerText)
                .font(.caption.bold())
            Spacer()
            if isFriend {
                Text("Friend")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.25), in: Capsule())
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isFriend ? Color.blue : Color.secondary)
    }

    private var bannerText: String {
        if let name = ownerName {
            return "Visiting \(name)'s kanojo"
        }
        return "Visiting another player's kanojo"
    }
}

// MARK: - Stamina Bar

private struct StaminaBarView: View {
    let current: Int
    let max: Int

    private var fraction: Double {
        guard max > 0 else { return 0 }
        return Double(current) / Double(max)
    }

    private var barColor: Color {
        if fraction > 0.5 { return .green }
        if fraction > 0.2 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Label("Stamina", systemImage: "bolt.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(current)/\(max)")
                    .font(.caption.bold())
                    .foregroundStyle(barColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Greeting Bubble

private struct GreetingBubble: View {
    let kanojoName: String
    let message: String
    let onDismiss: () -> Void

    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "bubble.left.fill")
                    .font(.caption)
                    .foregroundStyle(.pink)

                VStack(alignment: .leading, spacing: 2) {
                    Text(kanojoName)
                        .font(.caption.bold())
                        .foregroundStyle(.pink)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Button {
                    autoDismissTask?.cancel()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
        .onTapGesture {
            autoDismissTask?.cancel()
            onDismiss()
        }
        .onAppear {
            autoDismissTask = Task {
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                await MainActor.run { onDismiss() }
            }
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }
}

// MARK: - Date/Gift Menu Sheet

struct DateGiftMenuView: View {
    enum Mode { case date, gift }

    /// Source tab for gift mode
    enum SourceTab: String, CaseIterable {
        case store = "Store"
        case owned = "Owned"
    }

    let kanojoId: Int
    let mode: Mode
    let onSelect: (KanojoItem) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var categories: [KanojoItemCategory] = []
    @State private var isLoading = true
    @State private var selectedItem: KanojoItem?
    @State private var sourceTab: SourceTab = .store

    /// Navigation path for category drill-down
    @State private var navigationPath = NavigationPath()

    private let api = BarcodeKanojoAPI.shared

    /// Show store/owned tabs only for gift mode
    private var showTabs: Bool { mode == .gift }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Store / Owned tabs for gift mode
                if showTabs {
                    Picker("Source", selection: $sourceTab) {
                        ForEach(SourceTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Item list
                Group {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if categories.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No Items").font(.headline)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(categories, id: \.categoryId) { cat in
                                Section(cat.title ?? "") {
                                    ForEach(cat.items ?? [], id: \.itemId) { item in
                                        if item.category {
                                            // Category item — navigate to sub-items
                                            Button {
                                                navigationPath.append(item)
                                            } label: {
                                                HStack {
                                                    ItemRow(item: item)
                                                    Image(systemName: "chevron.right")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .foregroundStyle(.primary)
                                        } else {
                                            // Regular item — show detail
                                            Button {
                                                selectedItem = item
                                            } label: {
                                                ItemRow(item: item)
                                            }
                                            .foregroundStyle(.primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(mode == .date ? "Go on a Date" : "Give a Gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task(id: sourceTab) { await loadItems() }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item, mode: mode) {
                    selectedItem = nil
                    onSelect(item)
                    dismiss()
                }
            }
            .navigationDestination(for: KanojoItem.self) { categoryItem in
                CategorySubItemsView(
                    parentItem: categoryItem,
                    mode: mode,
                    sourceTab: sourceTab
                ) { item in
                    onSelect(item)
                    dismiss()
                }
            }
        }
    }

    private func loadItems() async {
        isLoading = true
        do {
            if sourceTab == .owned && showTabs {
                // Load owned items (gift class = 1)
                let response = try await api.hasItems(itemClass: 1, itemCategoryId: 0)
                categories = response.itemCategories ?? []
            } else {
                // Load store items
                let response = mode == .date
                    ? try await api.dateMenu(kanojoId: kanojoId)
                    : try await api.giftMenu(kanojoId: kanojoId)
                categories = response.itemCategories ?? []
            }
        } catch {
            print("[DateGiftMenu] Load failed: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Category Sub-Items View

/// Drill-down view for a category item — loads sub-items from the API.
private struct CategorySubItemsView: View {
    let parentItem: KanojoItem
    let mode: DateGiftMenuView.Mode
    let sourceTab: DateGiftMenuView.SourceTab
    let onSelect: (KanojoItem) -> Void

    @State private var categories: [KanojoItemCategory] = []
    @State private var isLoading = true
    @State private var selectedItem: KanojoItem?

    private let api = BarcodeKanojoAPI.shared

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if categories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Items").font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(categories, id: \.categoryId) { cat in
                        Section(cat.title ?? "") {
                            ForEach(cat.items ?? [], id: \.itemId) { item in
                                Button {
                                    selectedItem = item
                                } label: {
                                    ItemRow(item: item)
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(parentItem.title ?? "Items")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadSubItems() }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item, mode: mode) {
                selectedItem = nil
                onSelect(item)
            }
        }
    }

    private func loadSubItems() async {
        isLoading = true
        do {
            let itemClass = parentItem.itemClass
            let catId = parentItem.itemCategoryId

            let response: APIResponse
            if parentItem.expandFlag && sourceTab == .store {
                // Expandable store categories → permanent items
                response = try await api.permanentItems(itemClass: itemClass, itemCategoryId: catId)
            } else if parentItem.hasItem {
                // User owns items in this category
                response = try await api.hasItems(itemClass: itemClass, itemCategoryId: catId)
            } else {
                // Store items for this category
                response = try await api.storeItems(itemClass: itemClass, itemCategoryId: catId)
            }
            categories = response.itemCategories ?? []
        } catch {
            print("[CategorySubItems] Load failed: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Item Row

private struct ItemRow: View {
    let item: KanojoItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncCachedImage(url: item.imageThumbnailURL ?? "")
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title ?? "Item")
                    .font(.subheadline.bold())
                if let desc = item.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Price or owned badge
            if item.hasItem {
                Text("Owned")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            } else if let price = item.price, !price.isEmpty {
                Text(price)
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }
        }
    }
}

// MARK: - Item Detail View

private struct ItemDetailView: View {
    let item: KanojoItem
    let mode: DateGiftMenuView.Mode
    let onConfirm: () -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Item image
                    AsyncCachedImage(
                        url: item.imageURL ?? item.imageThumbnailURL ?? "",
                        placeholder: Image(systemName: "photo")
                    )
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Title
                    Text(item.title ?? "Item")
                        .font(.title3.bold())

                    // Description
                    if let desc = item.description, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Price info
                    if item.hasItem {
                        Label("You own this item", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    } else if let price = item.price, !price.isEmpty {
                        Label(price, systemImage: "ticket.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                    }

                    // Confirmation message
                    if let msg = item.confirmUseMessage, !msg.isEmpty {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer().frame(height: 10)

                    // Confirm button
                    Button {
                        onConfirm()
                    } label: {
                        Text(confirmButtonLabel)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.pink, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }
            }
        }
    }

    private var confirmButtonLabel: String {
        mode == .date ? "Go on Date" : "Give Gift"
    }
}

// MARK: - KanojoItem Identifiable for sheet(item:)

extension KanojoItem {
    // Already Identifiable via var id: Int { itemId }
}
