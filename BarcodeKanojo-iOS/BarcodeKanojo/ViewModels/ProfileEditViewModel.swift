import Foundation
import UIKit

@MainActor
final class ProfileEditViewModel: ObservableObject {

    @Published var name: String = ""
    @Published var email: String = ""
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmNewPassword: String = ""
    @Published var birthMonth: Int = 1
    @Published var birthDay: Int = 1
    @Published var birthYear: Int = 2000
    @Published var profileImageData: Data?

    @Published var isSaving = false
    @Published var isDeleting = false
    @Published var saveError: String?
    @Published var saveSuccess = false

    private let api = BarcodeKanojoAPI.shared
    private let settings = AppSettings.shared

    // MARK: - Populate from existing user

    func populate(from user: User) {
        name = user.name ?? ""
        email = settings.userEmail
        birthMonth = user.birthMonth
        birthDay = user.birthDay
        birthYear = user.birthYear
    }

    // MARK: - Validation

    var canSave: Bool {
        !name.isEmpty && !email.isEmpty && !isSaving
    }

    var passwordError: String? {
        if !newPassword.isEmpty && newPassword != confirmNewPassword {
            return "Passwords don't match"
        }
        if !newPassword.isEmpty && currentPassword.isEmpty {
            return "Current password required"
        }
        return nil
    }

    // MARK: - Save

    func save() async -> User? {
        guard canSave, passwordError == nil else { return nil }
        isSaving = true
        saveError = nil

        let currentHash: String? = currentPassword.isEmpty ? nil : PasswordHasher.hash(password: currentPassword)
        let newHash: String? = newPassword.isEmpty ? nil : PasswordHasher.hash(password: newPassword)

        do {
            let response = try await api.accountUpdate(
                name: name,
                currentPasswordHash: currentHash,
                newPasswordHash: newHash,
                email: email,
                birthYear: birthYear,
                birthMonth: birthMonth,
                birthDay: birthDay,
                sex: nil,
                profileImageData: profileImageData
            )

            if response.isSuccess {
                // Update stored credentials if email or password changed
                settings.userEmail = email
                if let newHash {
                    settings.userPasswordHash = newHash
                }
                saveSuccess = true
                isSaving = false
                return response.user
            } else {
                saveError = response.message ?? "Update failed"
            }
        } catch {
            saveError = error.localizedDescription
        }

        isSaving = false
        return nil
    }

    // MARK: - Delete Account

    func deleteAccount(userId: Int) async -> Bool {
        isDeleting = true
        do {
            let response = try await api.accountDelete(userId: userId)
            isDeleting = false
            return response.isSuccess
        } catch {
            saveError = error.localizedDescription
            isDeleting = false
            return false
        }
    }
}
