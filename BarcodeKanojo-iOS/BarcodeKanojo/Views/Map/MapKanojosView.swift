import SwiftUI
import MapKit

/// Map view showing kanojos at their geo-tagged locations.
/// Uses SwiftUI Map with annotation items (iOS 16 compatible).
struct MapKanojosView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = MapViewModel()
    @State private var selectedKanojoId: Int?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.68, longitude: 139.76), // Tokyo default
        latitudinalMeters: 50000,
        longitudinalMeters: 50000
    )

    var body: some View {
        NavigationStack {
            ZStack {
                mapContent

                // Loading overlay
                if vm.isLoading {
                    VStack {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding(10)
                                .background(.regularMaterial, in: Circle())
                                .padding()
                        }
                        Spacer()
                    }
                }

                // Empty state
                if !vm.isLoading && vm.kanojos.isEmpty {
                    emptyState
                }

                // Selected kanojo card
                if let selected = vm.kanojos.first(where: { $0.id == selectedKanojoId }) {
                    VStack {
                        Spacer()
                        KanojoMapCard(kanojo: selected) {
                            selectedKanojoId = nil
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 16)
                        .padding(.horizontal)
                    }
                    .animation(.easeInOut, value: selectedKanojoId)
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.requestLocation()
                        if let loc = vm.userLocation {
                            withAnimation {
                                region = MKCoordinateRegion(
                                    center: loc,
                                    latitudinalMeters: 5000,
                                    longitudinalMeters: 5000
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .task(id: auth.currentUser?.id) {
                if let id = auth.currentUser?.id {
                    vm.requestLocation()
                    await vm.load(userId: id)
                    // Center on first kanojo or user location
                    if let first = vm.kanojos.first, let coord = first.geoCoordinate {
                        region = MKCoordinateRegion(
                            center: coord,
                            latitudinalMeters: 10000,
                            longitudinalMeters: 10000
                        )
                    } else if let loc = vm.userLocation {
                        region = MKCoordinateRegion(
                            center: loc,
                            latitudinalMeters: 10000,
                            longitudinalMeters: 10000
                        )
                    }
                }
            }
            .navigationDestination(for: Int.self) { kanojoId in
                KanojoRoomView(kanojoId: kanojoId)
            }
        }
    }

    // MARK: - Map (iOS 16 compatible)

    @ViewBuilder
    private var mapContent: some View {
        let geoKanojos = vm.kanojos.filter { $0.geoCoordinate != nil }

        Map(coordinateRegion: $region,
            showsUserLocation: true,
            annotationItems: geoKanojos
        ) { kanojo in
            MapAnnotation(coordinate: kanojo.geoCoordinate!) {
                KanojoPinView(
                    kanojo: kanojo,
                    isSelected: selectedKanojoId == kanojo.id
                )
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedKanojoId = kanojo.id
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Kanojos on Map")
                .font(.headline)
            Text("Kanojos with location data will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding()
    }
}

// MARK: - Kanojo Pin View

private struct KanojoPinView: View {
    let kanojo: Kanojo
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: pinColor.opacity(0.4), radius: 4, y: 2)

                KanojoThumbnailView(kanojo: kanojo)
                    .frame(width: isSelected ? 38 : 30, height: isSelected ? 38 : 30)
                    .clipShape(Circle())
            }

            // Pin tail
            Triangle()
                .fill(pinColor)
                .frame(width: 12, height: 8)
                .offset(y: -1)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
    }

    private var pinColor: Color {
        switch kanojo.relation {
        case .kanojo: return .pink
        case .friend: return .blue
        default: return .gray
        }
    }
}

// MARK: - Pin Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Selected Kanojo Map Card

private struct KanojoMapCard: View {
    let kanojo: Kanojo
    let onDismiss: () -> Void

    var body: some View {
        NavigationLink(value: kanojo.id) {
            HStack(spacing: 12) {
                KanojoThumbnailView(kanojo: kanojo)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(kanojo.name ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        if let rel = kanojo.relation {
                            Text(rel == .kanojo ? "Kanojo" : rel == .friend ? "Friend" : "Other")
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    (rel == .kanojo ? Color.pink : rel == .friend ? Color.blue : Color.gray)
                                        .opacity(0.2)
                                )
                                .clipShape(Capsule())
                        }

                        Label("\(kanojo.loveGauge)", systemImage: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                    }

                    if let location = kanojo.location, !location.isEmpty {
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}
