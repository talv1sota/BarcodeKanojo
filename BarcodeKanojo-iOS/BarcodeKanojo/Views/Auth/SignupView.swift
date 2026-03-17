import SwiftUI

struct SignupView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthYear = Calendar.current.component(.year, from: Date()) - 20
    @State private var birthMonth = 1
    @State private var birthDay = 1

    private var isLoading: Bool {
        if case .loading = auth.state { return true }
        return false
    }

    private var errorMessage: String? {
        if case .error(let msg) = auth.state { return msg }
        return nil
    }

    private var passwordMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }

    private var canSubmit: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty &&
        password == confirmPassword && !isLoading
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Display Name", text: $name)
                        .textContentType(.name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Password") {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                    if passwordMismatch {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Birthday") {
                    Picker("Month", selection: $birthMonth) {
                        ForEach(1...12, id: \.self) { Text(monthName($0)).tag($0) }
                    }
                    Picker("Day", selection: $birthDay) {
                        ForEach(1...31, id: \.self) { Text("\($0)").tag($0) }
                    }
                    Picker("Year", selection: $birthYear) {
                        ForEach((1900...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) {
                            Text(String($0)).tag($0)
                        }
                    }
                }

                if let err = errorMessage {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task {
                            await auth.signup(
                                name: name,
                                email: email,
                                password: password,
                                birthYear: birthYear,
                                birthMonth: birthMonth,
                                birthDay: birthDay
                            )
                            if auth.isLoggedIn { dismiss() }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Create Account")
                                .font(.headline)
                                .foregroundStyle(canSubmit ? .pink : .secondary)
                            Spacer()
                        }
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .loadingOverlay(isLoading, message: "Creating account...")
        }
    }

    private func monthName(_ month: Int) -> String {
        DateFormatter().monthSymbols[month - 1]
    }
}
