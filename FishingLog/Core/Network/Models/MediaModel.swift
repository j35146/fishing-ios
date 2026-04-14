import Foundation

// 媒体项
struct MediaItem: Codable, Identifiable {
    var id: String { key }
    let key: String
    let url: String
    let type: String
    let size: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case key, url, type, size
        case createdAt = "created_at"
    }
}

// 上传结果
struct UploadResult: Codable {
    let key: String
    let url: String
    let type: String
    let size: Int
    let jobId: String?
}

// 媒体保存请求（内部使用，写入 CoreData）
struct MediaSaveRequest {
    let key: String
    let url: String
    let type: String
    let tripLocalId: UUID
    let syncStatus: String
    var localImageData: Data?
}
