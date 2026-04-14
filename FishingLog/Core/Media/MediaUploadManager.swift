import Foundation
import Combine

@MainActor
final class MediaUploadManager: ObservableObject {
    static let shared = MediaUploadManager()
    private init() {}

    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var lastError: String?

    // 上传单张图片，关联本地出行 ID
    func uploadImage(_ imageData: Data, tripLocalId: UUID) async {
        isUploading = true
        uploadProgress = 0
        lastError = nil

        let fileName = "photo-\(UUID().uuidString).jpg"

        do {
            let result = try await APIClient.shared.uploadMedia(
                data: imageData, mimeType: "image/jpeg", fileName: fileName
            )
            // 写入 CoreData（已同步状态）
            CoreDataManager.shared.upsertMedia(MediaSaveRequest(
                key: result.key,
                url: result.url,
                type: result.type,
                tripLocalId: tripLocalId,
                syncStatus: "synced"
            ))
            uploadProgress = 1.0
        } catch {
            lastError = error.localizedDescription
            // 写入失败状态，保存本地图片数据以便重试
            CoreDataManager.shared.upsertMedia(MediaSaveRequest(
                key: fileName,
                url: "",
                type: "image",
                tripLocalId: tripLocalId,
                syncStatus: "failed",
                localImageData: imageData
            ))
        }
        isUploading = false
    }

    // 批量上传
    func uploadImages(_ items: [(data: Data, tripLocalId: UUID)]) async {
        for (index, item) in items.enumerated() {
            await uploadImage(item.data, tripLocalId: item.tripLocalId)
            uploadProgress = Double(index + 1) / Double(items.count)
        }
    }

    // 重试失败的媒体
    func retryFailed() async {
        let failedItems = CoreDataManager.shared.fetchFailedMedia()
        for item in failedItems {
            guard let imageData = item.localImageData,
                  let tripLocalId = item.tripLocalId else { continue }
            // 删除旧记录
            CoreDataManager.shared.deleteMediaById(id: item.id ?? "")
            // 重新上传
            await uploadImage(imageData, tripLocalId: tripLocalId)
        }
    }
}
