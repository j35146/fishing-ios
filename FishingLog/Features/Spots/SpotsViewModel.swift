import Foundation
import CoreLocation
import Combine

@MainActor
final class SpotsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var spots: [Spot] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var isLoading = false
    @Published var error: String?
    @Published var displayMode: DisplayMode = .map

    enum DisplayMode { case map, list }

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
    }

    func refresh() async {
        isLoading = true
        error = nil
        do {
            if let loc = userLocation {
                spots = try await APIClient.shared.fetchNearbySpots(
                    lat: loc.latitude, lng: loc.longitude, radius: 50
                )
            } else {
                spots = try await APIClient.shared.fetchSpots()
            }
            CoreDataManager.shared.upsertSpots(spots)
        } catch {
            self.error = error.localizedDescription
            // 降级到本地缓存
            spots = CoreDataManager.shared.fetchSpots().map { entity in
                Spot(id: Int(entity.id),
                     name: entity.name ?? "",
                     description: entity.spotDescription,
                     latitude: entity.latitude,
                     longitude: entity.longitude,
                     spotType: entity.spotType,
                     isPublic: entity.isPublic,
                     photoUrl: entity.photoUrl,
                     photoKey: nil,
                     createdAt: nil)
            }
        }
        isLoading = false
    }

    func addSpot(_ req: CreateSpotRequest) async {
        do {
            let spot = try await APIClient.shared.createSpot(req)
            spots.insert(spot, at: 0)
            CoreDataManager.shared.upsertSpots([spot])
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteSpot(id: Int) async {
        do {
            try await APIClient.shared.deleteSpot(id: id)
            spots.removeAll { $0.id == id }
            CoreDataManager.shared.deleteSpotById(id: id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - CLLocationManagerDelegate
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.userLocation = loc.coordinate
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {}
}
