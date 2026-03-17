import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {

    enum State {
        case idle
        case loading
        case error(String)
    }

    @Published var state: State = .idle
    @Published var isLoggedIn = false
    @Published var currentUser: User?

    private let api = BarcodeKanojoAPI.shared
    private let settings = AppSettings.shared

    // MARK: - Auto Login

    func tryAutoLogin() async {
        guard settings.hasCredentials else { return }
        state = .loading
        do {
            let response = try await api.verify(
                uuid: settings.deviceUUID,
                email: settings.userEmail,
                passwordHash: settings.userPasswordHash
            )
            if response.isSuccess {
                currentUser = response.user
                isLoggedIn = true
            } else {
                state = .error(response.message ?? "Auto-login failed.")
            }
        } catch {
            state = .error(error.localizedDescription)
        }
        if case .loading = state { state = .idle }
    }

    // MARK: - Login

    func login(email: String, password: String) async {
        state = .loading
        let hash = PasswordHasher.hash(password: password)
        do {
            let response = try await api.verify(
                uuid: settings.deviceUUID,
                email: email,
                passwordHash: hash
            )
            if response.isSuccess, let user = response.user {
                settings.userEmail = email
                settings.userPasswordHash = hash
                currentUser = user
                isLoggedIn = true
                state = .idle
            } else {
                state = .error(response.message ?? "Login failed.")
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Signup

    func signup(
        name: String,
        email: String,
        password: String,
        birthYear: Int,
        birthMonth: Int,
        birthDay: Int
    ) async {
        state = .loading
        let hash = PasswordHasher.hash(password: password)
        do {
            let response = try await api.signup(
                uuid: settings.deviceUUID,
                name: name,
                passwordHash: hash,
                email: email,
                birthYear: birthYear,
                birthMonth: birthMonth,
                birthDay: birthDay,
                sex: nil
            )
            if response.isSuccess, let user = response.user {
                settings.userEmail = email
                settings.userPasswordHash = hash
                currentUser = user
                isLoggedIn = true
                state = .idle
            } else {
                state = .error(response.message ?? "Signup failed.")
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Logout

    func logout() {
        settings.logout()
        currentUser = nil
        isLoggedIn = false
        state = .idle
    }
}
