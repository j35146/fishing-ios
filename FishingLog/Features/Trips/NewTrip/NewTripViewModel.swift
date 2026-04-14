import Foundation
import Combine

@MainActor
final class NewTripViewModel: ObservableObject {
    // 步骤控制
    @Published var currentStep = 0

    // Step1 数据
    @Published var tripDate = Date()
    @Published var selectedStyleCodes: Set<String> = []   // "TRADITIONAL" / "LURE"
    @Published var locationName = ""
    @Published var title = ""
    @Published var weatherTemp = ""
    @Published var weatherCondition = ""
    @Published var companions = ""

    // Step2 渔获
    @Published var catches: [NewCatchForm] = []

    // Step3 装备
    @Published var availableEquipments: [EquipmentEntity] = []
    @Published var selectedEquipmentIds: Set<String> = []

    // Step4 照片数据
    @Published var photoDataArray: [Data] = []

    // 状态
    @Published var isSaving = false
    @Published var errorMessage: String?

    var step1Valid: Bool { !selectedStyleCodes.isEmpty }

    func loadEquipments() async {
        // 先从缓存读，再从网络更新
        availableEquipments = CoreDataManager.shared.fetchEquipments()
        do {
            let remote = try await APIClient.shared.fetchEquipment()
            CoreDataManager.shared.upsertEquipments(remote)
            availableEquipments = CoreDataManager.shared.fetchEquipments()
        } catch { /* 缓存数据已可用，忽略网络错误 */ }
    }

    func save() async -> Bool {
        isSaving = true
        defer { isSaving = false }

        let localId = UUID()
        let styleIds   = selectedStyleCodes.joined(separator: ",")
        let styleNames = selectedStyleCodes.map { $0 == "LURE" ? "路亚" : "台钓" }.joined(separator: ",")
        let companionList = companions.split(separator: "，").map(String.init)

        // 写入 CoreData
        let tripEntity = CoreDataManager.shared.createTrip(
            localId: localId,
            date: tripDate,
            locationName: locationName.isEmpty ? nil : locationName,
            title: title.isEmpty ? nil : title,
            styleIds: styleIds,
            styleNames: styleNames,
            weatherTemp: Double(weatherTemp),
            weatherCondition: weatherCondition.isEmpty ? nil : weatherCondition,
            companions: companionList,
            notes: nil
        )

        // 保存渔获
        catches.forEach {
            _ = CoreDataManager.shared.createCatch(
                trip: tripEntity, species: $0.species,
                weightG: $0.weightG, lengthCm: $0.lengthCm,
                count: $0.count, isReleased: $0.isReleased,
                styleCode: $0.styleCode, notes: nil
            )
        }

        // 触发同步
        SyncManager.shared.syncIfNeeded()

        // 上传照片
        if !photoDataArray.isEmpty {
            Task {
                await MediaUploadManager.shared.uploadImages(
                    photoDataArray.map { ($0, localId) }
                )
            }
        }

        return true
    }
}

// 渔获表单临时模型
struct NewCatchForm: Identifiable {
    let id = UUID()
    var species = ""
    var weightG = 0
    var lengthCm = 0.0
    var count = 1
    var isReleased = false
    var styleCode: String? = nil
}
