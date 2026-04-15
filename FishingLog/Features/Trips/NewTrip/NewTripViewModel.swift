import Foundation
import UIKit
import Combine

// 媒体项（照片或视频）
struct TripMediaItem: Identifiable {
    let id = UUID()
    enum MediaType { case photo, video }
    let type: MediaType
    let thumbnail: UIImage   // 预览缩略图
    let data: Data?          // JPEG 数据（照片用）
    let videoURL: URL?       // 视频本地路径
    let mimeType: String     // "image/jpeg" 或 "video/mp4"
    let fileName: String
}

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
    // 地点坐标
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    // 天气加载状态
    @Published var isLoadingWeather = false

    // Step2 渔获
    @Published var catches: [NewCatchForm] = []

    // Step3 装备
    @Published var availableEquipments: [EquipmentEntity] = []
    @Published var selectedEquipmentIds: Set<String> = []

    // Step4 媒体数据（照片+视频）
    @Published var mediaItems: [TripMediaItem] = []

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

    // 自动获取天气
    func fetchWeather() async {
        guard latitude != 0, longitude != 0 else { return }
        isLoadingWeather = true
        defer { isLoadingWeather = false }

        if let result = await WeatherService.shared.fetchWeather(
            latitude: latitude, longitude: longitude, date: tripDate
        ) {
            weatherTemp = String(format: "%.0f", result.temperature)
            weatherCondition = result.condition
        }
    }

    func save() async -> Bool {
        isSaving = true
        defer { isSaving = false }

        let localId = UUID()
        let styleIds   = selectedStyleCodes.joined(separator: ",")
        let styleNames = selectedStyleCodes.map { $0 == "LURE" ? "路亚" : "台钓" }.joined(separator: ",")
        let companionList = companions.split(separator: "，").map(String.init)

        // 写入 CoreData（含坐标信息）
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
            notes: nil,
            latitude: latitude != 0 ? latitude : nil,
            longitude: longitude != 0 ? longitude : nil
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

        // 上传媒体（照片+视频，等待完成）
        if !mediaItems.isEmpty {
            var uploadItems: [(data: Data, mimeType: String, fileName: String, tripLocalId: UUID)] = []
            for item in mediaItems {
                switch item.type {
                case .photo:
                    if let data = item.data {
                        uploadItems.append((data, item.mimeType, item.fileName, localId))
                    }
                case .video:
                    if let url = item.videoURL, let data = try? Data(contentsOf: url) {
                        uploadItems.append((data, item.mimeType, item.fileName, localId))
                    }
                }
            }
            await MediaUploadManager.shared.uploadMediaItems(uploadItems)
            if let uploadError = MediaUploadManager.shared.lastError {
                errorMessage = "媒体上传失败: \(uploadError)"
                return false  // 不 dismiss，让用户看到错误
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
