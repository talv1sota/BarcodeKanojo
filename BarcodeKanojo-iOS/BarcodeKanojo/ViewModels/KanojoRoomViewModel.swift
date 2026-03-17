import Foundation

/// Stamina cost per action type.
private enum StaminaCost {
    static let date = 10
    static let gift = 5
    static let touch = 1
}

@MainActor
final class KanojoRoomViewModel: ObservableObject {

    @Published var kanojo: Kanojo?
    @Published var ownerUser: User?
    @Published var loveIncrement: LoveIncrement?
    @Published var kanojoMessage: KanojoMessage?
    @Published var isLoading = true
    @Published var error: String?
    /// Set to true after a date/gift action completes to trigger dialogue display
    @Published var showDialogue = false
    /// Time-of-day greeting message shown on room entry
    @Published var greetingMessage: String?
    /// Set when user tries to date/gift with insufficient stamina or money
    @Published var staminaError: String?
    /// True while the kanojo is on a date (brief animated state).
    @Published var isOnDate = false
    /// Cost of the last item action for display (e.g. "Cost: 200").
    @Published var lastItemCost: Int?
    /// Set when user tries to use an item they can't afford
    @Published var moneyError: String?

    private let api = BarcodeKanojoAPI.shared
    private var dateTimer: Task<Void, Never>?

    func load(kanojoId: Int) async {
        isLoading = true
        error = nil
        print("[KanojoRoomVM] load(kanojoId=\(kanojoId))")
        do {
            // Load kanojo and greeting concurrently
            async let kanojoResponse = api.kanojoShow(kanojoId: kanojoId, screen: true)
            async let greetingResponse = api.showDialog(action: 0)

            let response = try await kanojoResponse
            kanojo = response.kanojo
            ownerUser = response.ownerUser ?? response.user

            // Load greeting (non-critical — don't fail the whole load)
            if let greetResponse = try? await greetingResponse,
               let msg = greetResponse.kanojoMessage,
               !msg.messages.isEmpty {
                greetingMessage = msg.messages.first
            }

            if let k = kanojo {
                print("[KanojoRoomVM] Loaded kanojo '\(k.name ?? "?")' body=\(k.bodyType) eye=\(k.eyeType) hair=\(k.hairType)")
            } else {
                print("[KanojoRoomVM] ⚠ response.kanojo is nil (code=\(response.code), msg=\(response.message ?? "nil"))")
                self.error = "Kanojo data not found (code \(response.code))."
            }
        } catch {
            print("❌ [KanojoRoomVM] load failed: \(error)")
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func dismissGreeting() {
        greetingMessage = nil
    }

    func dismissStaminaError() {
        staminaError = nil
    }

    /// Check whether the user has enough stamina for a date/gift action.
    var hasStamina: Bool {
        guard let user = ownerUser else { return true }
        return user.stamina > 0
    }

    func dismissMoneyError() {
        moneyError = nil
    }

    // MARK: - Date Actions

    func doDate(basicItemId: Int, itemCost: Int = 0) async {
        guard let kanojoId = kanojo?.id else { return }
        guard consumeStamina(StaminaCost.date, action: "date") else { return }
        guard consumeMoney(itemCost, action: "date") else {
            refundStamina(StaminaCost.date)
            return
        }

        lastItemCost = itemCost > 0 ? itemCost : nil

        // Set on-date state with a duration
        beginDate()

        do {
            let response = try await api.doDate(kanojoId: kanojoId, basicItemId: basicItemId)
            handleActionResponse(response)
        } catch {
            // Refund stamina + money on failure
            refundStamina(StaminaCost.date)
            refundMoney(itemCost)
            endDate()
            self.error = error.localizedDescription
        }
    }

    func doExtendDate(extendItemId: Int, itemCost: Int = 0) async {
        guard let kanojoId = kanojo?.id else { return }
        guard consumeStamina(StaminaCost.date, action: "extend date") else { return }
        guard consumeMoney(itemCost, action: "extend date") else {
            refundStamina(StaminaCost.date)
            return
        }

        do {
            let response = try await api.doExtendDate(kanojoId: kanojoId, extendItemId: extendItemId)
            handleActionResponse(response)
        } catch {
            refundStamina(StaminaCost.date)
            refundMoney(itemCost)
            self.error = error.localizedDescription
        }
    }

    // MARK: - Gift Actions

    func doGift(basicItemId: Int, itemCost: Int = 0) async {
        guard let kanojoId = kanojo?.id else { return }
        guard consumeStamina(StaminaCost.gift, action: "gift") else { return }
        guard consumeMoney(itemCost, action: "gift") else {
            refundStamina(StaminaCost.gift)
            return
        }

        lastItemCost = itemCost > 0 ? itemCost : nil

        do {
            let response = try await api.doGift(kanojoId: kanojoId, basicItemId: basicItemId)
            handleActionResponse(response)
        } catch {
            refundStamina(StaminaCost.gift)
            refundMoney(itemCost)
            self.error = error.localizedDescription
        }
    }

    func doExtendGift(extendItemId: Int, itemCost: Int = 0) async {
        guard let kanojoId = kanojo?.id else { return }
        guard consumeStamina(StaminaCost.gift, action: "extend gift") else { return }
        guard consumeMoney(itemCost, action: "extend gift") else {
            refundStamina(StaminaCost.gift)
            return
        }

        do {
            let response = try await api.doExtendGift(kanojoId: kanojoId, extendItemId: extendItemId)
            handleActionResponse(response)
        } catch {
            refundStamina(StaminaCost.gift)
            refundMoney(itemCost)
            self.error = error.localizedDescription
        }
    }

    // MARK: - Live2D Touch (body-part interaction)

    /// Called when user taps on the Live2D model. Sends the touch action to the server
    /// to earn +1 love point. Throttled to avoid spamming.
    private var lastPlayTime: Date = .distantPast

    func playOnLive2d(region: TouchRegion) async {
        guard let kanojoId = kanojo?.id else { return }

        // Throttle: at most once every 2 seconds
        let now = Date()
        guard now.timeIntervalSince(lastPlayTime) >= 2.0 else { return }
        lastPlayTime = now

        // Deduct stamina for touch (silent — don't block on insufficient)
        _ = consumeStamina(StaminaCost.touch, action: nil)

        do {
            let response = try await api.playOnLive2d(kanojoId: kanojoId, actions: region.actionName)
            // Update kanojo with any love increment from server
            if let updatedKanojo = response.kanojo {
                kanojo = updatedKanojo
            }
            if let inc = response.loveIncrement, inc.increaseLove != "0" {
                loveIncrement = inc
                // Brief love notification (no dialogue, just the increment)
                kanojoMessage = response.kanojoMessage
                showDialogue = true
            }
        } catch {
            print("[KanojoRoomVM] playOnLive2d failed: \(error)")
            // Don't show error to user for touch interactions — silent fail
        }
    }

    // MARK: - Like

    func voteLike() async {
        guard var k = kanojo else { return }
        let wasLiked = k.votedLike
        let newLiked = !wasLiked

        // Optimistic update — toggle immediately so the UI responds
        k.votedLike = newLiked
        if newLiked {
            k.likeRate += 1
        } else {
            k.likeRate = max(0, k.likeRate - 1)
        }
        kanojo = k

        do {
            let response = try await api.voteLike(kanojoId: k.id, like: newLiked)
            // Server response takes precedence if available
            if let serverKanojo = response.kanojo {
                kanojo = serverKanojo
            }
        } catch {
            // Revert optimistic update on failure
            k.votedLike = wasLiked
            if wasLiked {
                k.likeRate += 1
            } else {
                k.likeRate = max(0, k.likeRate - 1)
            }
            kanojo = k
            self.error = error.localizedDescription
        }
    }

    // MARK: - Stamina Management

    /// Deduct stamina locally. Returns true if enough stamina was available.
    /// If `action` is non-nil, shows a staminaError alert on failure.
    @discardableResult
    private func consumeStamina(_ amount: Int, action: String?) -> Bool {
        guard var user = ownerUser else { return true } // No user info → allow (server will validate)
        guard user.stamina >= amount else {
            if let action {
                staminaError = "Not enough stamina for \(action)! Need \(amount), have \(user.stamina). Wait for it to recharge."
            }
            return false
        }
        user.stamina -= amount
        ownerUser = user
        return true
    }

    /// Restore stamina (e.g. on API failure / refund).
    private func refundStamina(_ amount: Int) {
        guard var user = ownerUser else { return }
        user.stamina = min(user.staminaMax, user.stamina + amount)
        ownerUser = user
    }

    // MARK: - Money Management

    /// Deduct money locally. Returns true if enough money was available.
    /// Owned items (cost 0) always pass. If `action` is non-nil, shows moneyError on failure.
    @discardableResult
    private func consumeMoney(_ amount: Int, action: String?) -> Bool {
        guard amount > 0 else { return true } // Free or owned items always pass
        guard var user = ownerUser else { return true } // No user info → allow (server validates)
        guard user.money >= amount else {
            if let action {
                moneyError = "Not enough money for \(action)! Need \(amount), have \(user.money)."
            }
            return false
        }
        user.money -= amount
        ownerUser = user
        return true
    }

    /// Restore money (e.g. on API failure / refund).
    private func refundMoney(_ amount: Int) {
        guard amount > 0 else { return }
        guard var user = ownerUser else { return }
        user.money += amount
        ownerUser = user
    }

    // MARK: - Date Duration

    /// Start the "on date" state — lasts a few seconds to give visual feedback.
    private func beginDate() {
        isOnDate = true
        kanojo?.onDate = true
        dateTimer?.cancel()
        dateTimer = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            endDate()
        }
    }

    /// End the "on date" state.
    private func endDate() {
        isOnDate = false
        kanojo?.onDate = false
        dateTimer?.cancel()
        dateTimer = nil
    }

    // MARK: - Helpers

    private func handleActionResponse(_ response: APIResponse) {
        // Server data takes precedence
        if let serverKanojo = response.kanojo {
            kanojo = serverKanojo
        }
        loveIncrement = response.loveIncrement

        // Capture dialogue messages if server sent them
        if let msg = response.kanojoMessage, !msg.messages.isEmpty {
            kanojoMessage = msg
            showDialogue = true
        } else if let inc = response.loveIncrement, inc.increaseLove != "0" {
            // No message but there is a love increment — still show dialogue
            kanojoMessage = nil
            showDialogue = true
        }

        // Update user balance if returned (server is authoritative)
        if let updatedUser = response.user {
            ownerUser = updatedUser
        } else if let updatedOwner = response.ownerUser {
            ownerUser = updatedOwner
        }

        // End date state after response arrives
        if isOnDate {
            // Let the timer keep going for visual feedback, but server response is done
        }
    }

    func dismissDialogue() {
        showDialogue = false
    }
}
