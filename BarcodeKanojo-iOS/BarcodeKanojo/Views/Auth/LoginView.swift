import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var showServerConfig = false

    private var isLoading: Bool {
        if case .loading = auth.state { return true }
        return false
    }

    private var errorMessage: String? {
        if case .error(let msg) = auth.state { return msg }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo / Title
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.pink)
                        Text("Barcode Kanojo")
                            .font(.largeTitle.bold())
                        Text("Scan. Collect. Connect.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Error
                    if let err = errorMessage {
                        ErrorBanner(message: err) {
                            auth.state = .idle
                        }
                    }

                    // Fields
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(12)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding(12)
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)

                    // Login Button
                    Button {
                        Task { await auth.login(email: email, password: password) }
                    } label: {
                        Text("Log In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(email.isEmpty || password.isEmpty ? Color.gray : Color.pink)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    .padding(.horizontal)

                    // Divider
                    HStack {
                        Divider()
                        Text("or").foregroundStyle(.secondary).font(.caption)
                        Divider()
                    }
                    .padding(.horizontal)

                    // Signup
                    Button {
                        showSignup = true
                    } label: {
                        Text("Create Account")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // Server config link
                    Button("Server Settings") {
                        showServerConfig = true
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)
                }
            }
            .loadingOverlay(isLoading, message: "Logging in...")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSignup) {
                SignupView()
            }
            .sheet(isPresented: $showServerConfig) {
                ServerConfigView()
            }
        }
    }
}
