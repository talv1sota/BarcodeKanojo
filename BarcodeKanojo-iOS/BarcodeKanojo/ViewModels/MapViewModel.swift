import Foundation
import CoreLocation

@MainActor
final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var kanojos: [Kanojo] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var userLocation: CLLocationCoordinate2D?

    private let api = BarcodeKanojoAPI.shared
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Load kanojos with geo data

    func load(userId: Int) async {
        isLoading = true
        error = nil

        do {
            // Fetch own kanojos and friend kanojos concurrently
            async let ownResponse = api.currentKanojos(userId: userId, index: 0, limit: 200)
            async let friendResponse = api.friendKanojos(userId: userId, index: 0, limit: 200)

            let own = (try await ownResponse).currentKanojos ?? []
            let friends = (try await friendResponse).friendKanojos ?? []

            // Combine and filter to only those with valid geo coordinates
            let all = own + friends
            kanojos = all.filter { $0.geoCoordinate != nil }
            print("[MapVM] Loaded \(kanojos.count) geotagged kanojos out of \(all.count) total")
        } catch {
            self.error = error.localizedDescription
            print("[MapVM] Load failed: \(error)")
        }

        isLoading = false
    }

    // MARK: - Location

    func requestLocation() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.userLocation = location.coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[MapVM] Location error: \(error)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
