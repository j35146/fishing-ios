import Foundation
import CoreLocation

// 钓点模型
struct Spot: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let latitude: Double
    let longitude: Double
    let spotType: String?
    let isPublic: Bool?
    let photoUrl: String?
    let photoKey: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, latitude, longitude
        case spotType = "spot_type"
        case isPublic = "is_public"
        case photoUrl = "photo_url"
        case photoKey = "photo_key"
        case createdAt = "created_at"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // 自定义解码：PostgreSQL DECIMAL 经 node-pg 可能序列化为 String
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(Int.self, forKey: .id)
        name        = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        spotType    = try c.decodeIfPresent(String.self, forKey: .spotType)
        isPublic    = try c.decodeIfPresent(Bool.self, forKey: .isPublic)
        photoUrl    = try c.decodeIfPresent(String.self, forKey: .photoUrl)
        photoKey    = try c.decodeIfPresent(String.self, forKey: .photoKey)
        createdAt   = try c.decodeIfPresent(String.self, forKey: .createdAt)
        // latitude / longitude 可能是 String（DECIMAL）或 Double
        latitude    = try Self.decodeFlexibleDouble(from: c, forKey: .latitude) ?? 0
        longitude   = try Self.decodeFlexibleDouble(from: c, forKey: .longitude) ?? 0
    }

    // 用于本地构造
    init(id: Int, name: String, description: String?, latitude: Double, longitude: Double,
         spotType: String?, isPublic: Bool?, photoUrl: String?, photoKey: String?, createdAt: String?) {
        self.id = id; self.name = name; self.description = description
        self.latitude = latitude; self.longitude = longitude
        self.spotType = spotType; self.isPublic = isPublic
        self.photoUrl = photoUrl; self.photoKey = photoKey; self.createdAt = createdAt
    }

    private static func decodeFlexibleDouble(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Double? {
        if let val = try? container.decode(Double.self, forKey: key) { return val }
        if let str = try? container.decode(String.self, forKey: key) { return Double(str) }
        return nil
    }
}

// 钓点类型枚举
enum SpotType: String, CaseIterable, Identifiable {
    case river, lake, reservoir, sea, other
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .river: "河流"
        case .lake: "湖泊"
        case .reservoir: "水库"
        case .sea: "海钓"
        case .other: "其他"
        }
    }
}

// 新建钓点请求
struct CreateSpotRequest: Encodable {
    let name: String
    let description: String?
    let latitude: Double
    let longitude: Double
    let spotType: String
    let isPublic: Bool
    let photoKey: String?

    enum CodingKeys: String, CodingKey {
        case name, description, latitude, longitude
        case spotType = "spot_type"
        case isPublic = "is_public"
        case photoKey = "photo_key"
    }
}
