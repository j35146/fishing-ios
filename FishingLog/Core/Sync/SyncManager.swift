import Foundation
import Network
import Combine

@MainActor
final class SyncManager: ObservableObject {
    static let shared = SyncManager()
    @Published var isSyncing = false

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.jiangfeng.fishinglog.network")
    private var wasConnected = false

    private init() {
        // 监测网络变化
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            Task { @MainActor in
                if isConnected && !(self?.wasConnected ?? true) {
                    // 网络从断开变为连接，触发同步
                    self?.syncIfNeeded()
                    // 重试失败的媒体上传
                    Task { await MediaUploadManager.shared.retryFailed() }
                }
                self?.wasConnected = isConnected
            }
        }
        monitor.start(queue: monitorQueue)
    }

    func syncIfNeeded() {
        guard AuthManager.shared.isLoggedIn else { return }
        let pending = CoreDataManager.shared.fetchPendingTrips()
        guard !pending.isEmpty else { return }
        Task { await sync(trips: pending) }
    }

    // 将 style code（TRADITIONAL/LURE）或数字 id 转为 Int 数组
    private static func styleCodeToIds(_ raw: String?) -> [Int] {
        guard let raw, !raw.isEmpty else { return [] }
        return raw.split(separator: ",").compactMap { part in
            let s = part.trimmingCharacters(in: .whitespaces)
            if let id = Int(s) { return id }
            switch s {
            case "TRADITIONAL": return 1
            case "LURE":        return 2
            default:            return nil
            }
        }
    }

    private func sync(trips: [TripEntity]) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        // 构建同步请求体
        let items: [[String: Any]] = trips.compactMap { trip in
            guard let date = trip.tripDate else { return nil }
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            return [
                "local_id"      : trip.localId?.uuidString ?? UUID().uuidString,
                "trip_date"     : fmt.string(from: date),
                "location_name" : trip.locationName as Any,
                "title"         : trip.title as Any,
                "notes"         : trip.notes as Any,
                "style_ids"     : Self.styleCodeToIds(trip.styleIds),
                "updated_at"    : ISO8601DateFormatter().string(from: trip.updatedAt ?? Date()),
                "latitude"      : trip.latitude != 0 ? trip.latitude : NSNull(),
                "longitude"     : trip.longitude != 0 ? trip.longitude : NSNull()
            ]
        }

        do {
            let results = try await APIClient.shared.syncTrips(items)
            // 更新同步状态
            for result in results {
                guard let localIdStr = result["local_id"] as? String,
                      let serverId   = result["id"] as? String else { continue }
                let req = TripEntity.fetchRequest()
                req.predicate = NSPredicate(format: "localId == %@",
                                            UUID(uuidString: localIdStr) as CVarArg? ?? "" as CVarArg)
                if let entity = try? CoreDataManager.shared.context.fetch(req).first {
                    entity.id         = serverId
                    entity.syncStatus = "synced"
                }
            }
            CoreDataManager.shared.saveContext()
        } catch {
            // 标记为 failed，下次重试
            trips.forEach { $0.syncStatus = "failed" }
            CoreDataManager.shared.saveContext()
        }
    }
}
