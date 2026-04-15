import CoreData
import Foundation

@MainActor
final class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()

    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FishingLog")
        // 轻量级迁移
        let desc = NSPersistentStoreDescription()
        desc.shouldMigrateStoreAutomatically = true
        desc.shouldInferMappingModelAutomatically = true
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            desc.url = storeURL
        }
        container.persistentStoreDescriptions = [desc]
        container.loadPersistentStores { _, error in
            if let error { fatalError("Core Data 加载失败：\(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext { container.viewContext }

    // MARK: - 保存
    func saveContext() {
        guard context.hasChanges else { return }
        try? context.save()
    }

    // MARK: - Trip CRUD
    func fetchTrips() -> [TripEntity] {
        let req = TripEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "tripDate", ascending: false)]
        return (try? context.fetch(req)) ?? []
    }

    func fetchPendingTrips() -> [TripEntity] {
        let req = TripEntity.fetchRequest()
        req.predicate = NSPredicate(format: "syncStatus == %@", "pending")
        return (try? context.fetch(req)) ?? []
    }

    func upsertTrip(from trip: Trip) {
        // 先按服务端 id 查找，找不到再按 localId 查找，避免创建重复记录
        let byId = TripEntity.fetchRequest()
        byId.predicate = NSPredicate(format: "id == %@", trip.id)
        var found = (try? context.fetch(byId))?.first

        if found == nil, let lid = trip.localId, !lid.isEmpty,
           let uuid = UUID(uuidString: lid) {
            let byLocal = TripEntity.fetchRequest()
            byLocal.predicate = NSPredicate(format: "localId == %@", uuid as CVarArg)
            found = (try? context.fetch(byLocal))?.first
        }

        let entity = found ?? TripEntity(context: context)
        entity.id           = trip.id
        // 只在服务端返回了 local_id 时才更新，避免覆盖为 nil
        if let newLocalId = trip.localId.flatMap({ UUID(uuidString: $0) }) {
            entity.localId = newLocalId
        }
        entity.title        = trip.title
        entity.locationName = trip.locationName
        entity.syncStatus   = "synced"
        entity.notes        = trip.notes
        if let dateStr = trip.tripDate as String? {
            // 服务端可能返回 "2026-04-14T00:00:00.000Z" 或 "2026-04-14"
            let isoFmt = ISO8601DateFormatter()
            isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            entity.tripDate = isoFmt.date(from: dateStr)
                           ?? ISO8601DateFormatter().date(from: dateStr)
                           ?? ISO8601DateFormatter().date(from: dateStr + "T00:00:00Z")
                           ?? parseDateString(dateStr)
        }
        entity.styleNames = trip.styles?.map(\.name).joined(separator: ",")
        entity.styleIds   = trip.styles?.map { String($0.id) }.joined(separator: ",")
        // 服务端坐标回写（仅在有值时更新，保留本地已有坐标）
        if let lat = trip.latitude { entity.latitude = lat }
        if let lng = trip.longitude { entity.longitude = lng }
        saveContext()
    }

    func createTrip(localId: UUID, date: Date, locationName: String?,
                    title: String?, styleIds: String, styleNames: String,
                    weatherTemp: Double?, weatherCondition: String?,
                    companions: [String], notes: String?,
                    latitude: Double? = nil, longitude: Double? = nil,
                    spotId: String? = nil) -> TripEntity {
        let entity = TripEntity(context: context)
        entity.id           = localId.uuidString
        entity.localId      = localId
        entity.tripDate     = date
        entity.locationName = locationName
        entity.title        = title
        entity.styleIds     = styleIds
        entity.styleNames   = styleNames
        entity.weatherTemp  = weatherTemp ?? 0
        entity.weatherCondition = weatherCondition
        entity.companions   = companions
        entity.notes        = notes
        // 地图坐标与钓点关联
        entity.latitude     = latitude ?? 0
        entity.longitude    = longitude ?? 0
        entity.spotId       = spotId
        entity.syncStatus   = "pending"
        entity.createdAt    = Date()
        entity.updatedAt    = Date()
        saveContext()
        return entity
    }

    func deleteTrip(_ entity: TripEntity) {
        context.delete(entity)
        saveContext()
    }

    // MARK: - Catch CRUD
    func fetchCatches(for trip: TripEntity) -> [CatchEntity] {
        let req = CatchEntity.fetchRequest()
        req.predicate = NSPredicate(format: "trip == %@", trip)
        return (try? context.fetch(req)) ?? []
    }

    func fetchAllCatches() -> [CatchEntity] {
        let req = CatchEntity.fetchRequest()
        return (try? context.fetch(req)) ?? []
    }

    func createCatch(trip: TripEntity, species: String, weightG: Int,
                     lengthCm: Double, count: Int, isReleased: Bool,
                     styleCode: String?, notes: String?) -> CatchEntity {
        let entity = CatchEntity(context: context)
        entity.id         = UUID().uuidString
        entity.localId    = UUID()
        entity.species    = species
        entity.weightG    = Int32(weightG)
        entity.lengthCm   = lengthCm
        entity.count      = Int16(count)
        entity.isReleased = isReleased
        entity.styleCode  = styleCode
        entity.notes      = notes
        entity.createdAt  = Date()
        entity.trip       = trip
        saveContext()
        return entity
    }

    func deleteCatch(_ entity: CatchEntity) {
        context.delete(entity)
        saveContext()
    }

    // MARK: - Equipment CRUD
    func upsertEquipments(_ equipments: [Equipment]) {
        equipments.forEach { eq in
            let req = EquipmentEntity.fetchRequest()
            req.predicate = NSPredicate(format: "id == %@", eq.id)
            let entity = (try? context.fetch(req))?.first ?? EquipmentEntity(context: context)
            entity.id           = eq.id
            entity.name         = eq.name
            entity.brand        = eq.brand
            entity.model        = eq.model
            entity.categoryName = eq.categoryName
            entity.categoryId   = Int32(eq.categoryId ?? 0)
            entity.status       = eq.status ?? "active"
            entity.purchasePrice = eq.purchasePrice ?? 0
            entity.notes        = eq.notes
            entity.styleTags    = eq.styleTags
            if let dateStr = eq.purchaseDate {
                entity.purchaseDate = parseDateString(dateStr)
            }
        }
        saveContext()
    }

    func fetchEquipments() -> [EquipmentEntity] {
        let req = EquipmentEntity.fetchRequest()
        req.predicate = NSPredicate(format: "status == %@ OR status == nil", "active")
        req.sortDescriptors = [NSSortDescriptor(key: "categoryName", ascending: true),
                               NSSortDescriptor(key: "name", ascending: true)]
        return (try? context.fetch(req)) ?? []
    }

    func fetchAllEquipments() -> [EquipmentEntity] {
        let req = EquipmentEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return (try? context.fetch(req)) ?? []
    }

    func insertEquipment(_ eq: Equipment) {
        let entity = EquipmentEntity(context: context)
        entity.id           = eq.id
        entity.name         = eq.name
        entity.brand        = eq.brand
        entity.model        = eq.model
        entity.categoryName = eq.categoryName
        entity.categoryId   = Int32(eq.categoryId ?? 0)
        entity.status       = eq.status ?? "active"
        entity.purchasePrice = eq.purchasePrice ?? 0
        entity.notes        = eq.notes
        entity.styleTags    = eq.styleTags
        if let dateStr = eq.purchaseDate {
            entity.purchaseDate = parseDateString(dateStr)
        }
        saveContext()
    }

    func updateEquipmentEntity(id: String, from eq: Equipment) {
        let req = EquipmentEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id)
        guard let entity = (try? context.fetch(req))?.first else { return }
        entity.name         = eq.name
        entity.brand        = eq.brand
        entity.model        = eq.model
        entity.categoryName = eq.categoryName
        entity.categoryId   = Int32(eq.categoryId ?? 0)
        entity.status       = eq.status ?? "active"
        entity.purchasePrice = eq.purchasePrice ?? 0
        entity.notes        = eq.notes
        entity.styleTags    = eq.styleTags
        if let dateStr = eq.purchaseDate {
            entity.purchaseDate = parseDateString(dateStr)
        }
        saveContext()
    }

    func deleteEquipmentById(id: String) {
        let req = EquipmentEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id)
        if let entity = (try? context.fetch(req))?.first {
            context.delete(entity)
            saveContext()
        }
    }

    // MARK: - Media CRUD
    func upsertMedia(_ request: MediaSaveRequest) {
        let req = MediaEntity.fetchRequest()
        req.predicate = NSPredicate(format: "key == %@", request.key)
        let entity = (try? context.fetch(req))?.first ?? MediaEntity(context: context)
        entity.id         = request.key
        entity.localId    = UUID()
        entity.key        = request.key
        entity.url        = request.url
        entity.type       = request.type
        entity.tripLocalId = request.tripLocalId
        entity.syncStatus = request.syncStatus
        entity.createdAt  = Date()
        if let imageData = request.localImageData {
            entity.localImageData = imageData
        }
        // 关联 TripEntity
        let tripReq = TripEntity.fetchRequest()
        tripReq.predicate = NSPredicate(format: "localId == %@", request.tripLocalId as CVarArg)
        if let tripEntity = (try? context.fetch(tripReq))?.first {
            entity.trip = tripEntity
        }
        saveContext()
    }

    func fetchMedia(for tripLocalId: UUID) -> [MediaEntity] {
        let req = MediaEntity.fetchRequest()
        req.predicate = NSPredicate(format: "tripLocalId == %@", tripLocalId as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return (try? context.fetch(req)) ?? []
    }

    func fetchFailedMedia() -> [MediaEntity] {
        let req = MediaEntity.fetchRequest()
        req.predicate = NSPredicate(format: "syncStatus == %@", "failed")
        return (try? context.fetch(req)) ?? []
    }

    func deleteMediaById(id: String) {
        let req = MediaEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id)
        if let entity = (try? context.fetch(req))?.first {
            context.delete(entity)
            saveContext()
        }
    }

    // MARK: - Spot CRUD
    func upsertSpots(_ spots: [Spot]) {
        spots.forEach { spot in
            let req = SpotEntity.fetchRequest()
            req.predicate = NSPredicate(format: "id == %d", spot.id)
            let entity = (try? context.fetch(req))?.first ?? SpotEntity(context: context)
            entity.id              = Int32(spot.id)
            entity.name            = spot.name
            entity.spotDescription = spot.description
            entity.latitude        = spot.latitude
            entity.longitude       = spot.longitude
            entity.spotType        = spot.spotType
            entity.isPublic        = spot.isPublic ?? true
            entity.photoUrl        = spot.photoUrl
            if let dateStr = spot.createdAt {
                entity.createdAt = ISO8601DateFormatter().date(from: dateStr)
            }
        }
        saveContext()
    }

    func fetchSpots() -> [SpotEntity] {
        let req = SpotEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(req)) ?? []
    }

    func fetchSpot(id: Int) -> SpotEntity? {
        let req = SpotEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %d", id)
        return (try? context.fetch(req))?.first
    }

    func deleteSpotById(id: Int) {
        let req = SpotEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %d", id)
        if let entity = (try? context.fetch(req))?.first {
            context.delete(entity)
            saveContext()
        }
    }

    // MARK: - 工具方法
    private func parseDateString(_ str: String) -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: str)
    }
}
