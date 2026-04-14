import Foundation
import Combine

@MainActor
final class TripsListViewModel: ObservableObject {
    @Published var trips: [TripEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let coreData = CoreDataManager.shared

    func loadLocal() {
        trips = coreData.fetchTrips()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let remote = try await APIClient.shared.fetchTrips()
            remote.forEach { coreData.upsertTrip(from: $0) }
            trips = coreData.fetchTrips()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
