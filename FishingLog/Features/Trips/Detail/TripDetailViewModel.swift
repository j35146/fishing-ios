import Foundation

@MainActor
final class TripDetailViewModel: ObservableObject {
    @Published var trip: TripEntity
    @Published var catches: [CatchEntity] = []
    @Published var isDeleting = false

    init(trip: TripEntity) {
        self.trip = trip
        catches = CoreDataManager.shared.fetchCatches(for: trip)
    }

    func deleteTrip() async throws {
        isDeleting = true
        defer { isDeleting = false }
        // 如果已同步到服务器，尝试调 API 删除（失败不阻塞本地删除）
        if trip.syncStatus == "synced", let id = trip.id {
            try? await APIClient.shared.deleteTrip(id: id)
        }
        CoreDataManager.shared.deleteTrip(trip)
    }
}
