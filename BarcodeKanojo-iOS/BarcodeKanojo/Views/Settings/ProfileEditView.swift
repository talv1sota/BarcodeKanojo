import SwiftUI
import PhotosUI

/// Profile editing form — name, email, password, birthday, profile photo.
/// Matches Android's UserModifyActivity.
struct ProfileEditView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = ProfileEditViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showDeleteConfirm = false

    var body: some View {
        Form {
            // Profile photo
            Section("Profile Photo") {
                HStack {
                    if let data = vm.profileImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    } else if let user = auth.currentUser {
                        AsyncCachedImage(url: user.profileImageURL)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    }

                    Spacer()

                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Change Photo", systemImage: "camera.fill")
                            .font(.subheadline)
                    }
                }
            }

            // Basic info
            Section("Basic Info") {
                TextField("Display Name", text: $vm.name)
                    .textContentType(.name)
                TextField("Email", text: $vm.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }

            // Birthday
            Section("Birthday") {
                HStack(spacing: 12) {
                    Picker("Month", selection: $vm.birthMonth) {
                        ForEach(1...12, id: \.self) { m in
                            Text(monthName(m)).tag(m)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Day", selection: $vm.birthDay) {
                        ForEach(1...31, id: \.self) { d in
                            Text("\(d)").tag(d)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Year", selection: $vm.birthYear) {
                        ForEach((1950...2015).reversed(), id: \.self) { y in
                            Text("\(y)").tag(y)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Change password
            Section("Change Password") {
                SecureField("Current Password", text: $vm.currentPassword)
                    .textContentType(.password)
                SecureField("New Password", text: $vm.newPassword)
                    .textContentType(.newPassword)
                SecureField("Confirm New Password", text: $vm.confirmNewPassword)
                    .textContentType(.newPassword)

                if let err = vm.passwordError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Error display
            if let err = vm.saveError {
                Section {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Delete account
            Section {
                Button("Delete Account", role: .destructive) {
                    showDeleteConfirm = true
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        if let updatedUser = await vm.save() {
                            auth.currentUser = updatedUser
                            dismiss()
                        }
                    }
                }
                .disabled(!vm.canSave || vm.isSaving)
            }
        }
        .onAppear {
            if let user = auth.currentUser {
                vm.populate(from: user)
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    vm.profileImageData = data
                }
            }
        }
        .confirmationDialog(
            "Delete your account? This cannot be undone.",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Task {
                    if let userId = auth.currentUser?.id {
                        let success = await vm.deleteAccount(userId: userId)
                        if success {
                            auth.logout()
                        }
                    }
                }
            }
        }
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var components = DateComponents()
        components.month = month
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(month)"
    }
}
