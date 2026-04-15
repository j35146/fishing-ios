import Foundation
import Combine

@MainActor
final class MediaUploadManager: ObservableObject {
    static let shared = MediaUploadManager()
    private init() {}

    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var lastError: String?

    // 上传媒体文件（图片或视频），关联本地出行 ID
    func uploadMedia(_ data: Data, mimeType: String, fileName: String, tripLocalId: UUID) async {
        isUploading = true
        uploadProgress = 0
        lastError = nil

        do {
            let result = try await APIClient.shared.uploadMedia(
                data: data, mimeType: mimeType, fileName: fileName
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
            // 写入失败状态，保存本地数据以便重试
            CoreDataManager.shared.upsertMedia(MediaSaveRequest(
                key: fileName,
                url: "",
                type: mimeType.hasPrefix("video") ? "video" : "image",
                tripLocalId: tripLocalId,
                syncStatus: "failed",
                localImageData: data
            ))
        }
        isUploading = false
    }

    // 保持向后兼容：上传单张图片
    func uploadImage(_ imageData: Data, tripLocalId: UUID) async {
        let fileName = "photo-\(UUID().uuidString).jpg"
        await uploadMedia(imageData, mimeType: "image/jpeg", fileName: fileName, tripLocalId: tripLocalId)
    }

    // 批量上传媒体项
    func uploadMediaItems(_ items: [(data: Data, mimeType: String, fileName: String, tripLocalId: UUID)]) async {
        for (index, item) in items.enumerated() {
            await uploadMedia(item.data, mimeType: item.mimeType, fileName: item.fileName, tripLocalId: item.tripLocalId)
            uploadProgress = Double(index + 1) / Double(items.count)
        }
    }

    // 保持向后兼容：批量上传图片
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
            // 重新上传（根据文件名判断类型）
            let isVideo = item.key?.hasPrefix("video-") ?? false
            let mimeType = isVideo ? "video/mp4" : "image/jpeg"
            let fileName = item.key ?? "photo-\(UUID().uuidString).jpg"
            await uploadMedia(imageData, mimeType: mimeType, fileName: fileName, tripLocalId: tripLocalId)
        }
    }
}
