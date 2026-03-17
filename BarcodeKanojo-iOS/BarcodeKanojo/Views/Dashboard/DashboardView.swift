import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = DashboardViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.activities.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // User header
                        if let user = vm.user ?? auth.currentUser {
                            Section {
                                DashboardHeaderView(user: user)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                            }
                        }

                        // Activity timeline
                        Section("Recent Activity") {
                            if vm.activities.isEmpty {
                                Text("No activity yet.")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            } else {
                                ForEach(vm.activities) { activity in
                                    ActivityRowView(activity: activity)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        if let id = auth.currentUser?.id {
                            await vm.refresh(userId: id)
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task {
                if let id = auth.currentUser?.id {
                    await vm.load(userId: id)
                }
            }
        }
    }
}
