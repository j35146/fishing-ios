import Foundation

struct Trip: Codable, Identifiable {
    let id: String
    let localId: String?
    let title: String?
    let tripDate: String        // "YYYY-MM-DD"
    let locationName: String?
    let weatherTemp: Double?
    let weatherWind: String?
    let weatherCondition: String?
    let companions: [String]?
    let notes: String?
    let syncStatus: String?
    let styles: [FishingStyle]?
    let catches: [FishCatch]?
    let catchCount: Int?
    let updatedAt: String?
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id, title, notes, styles, catches
        case localId = "local_id"
        case tripDate = "trip_date"
        case locationName = "location_name"
        case weatherTemp = "weather_temp"
        case weatherWind = "weather_wind"
        case weatherCondition = "weather_condition"
        case companions
        case syncStatus = "sync_status"
        case catchCount = "catch_count"
        case updatedAt = "updated_at"
        case latitude, longitude
    }

    // 自定义解码：weather_temp 是 DECIMAL(4,1)，node-pg 可能返回 String
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(String.self, forKey: .id)
        localId          = try c.decodeIfPresent(String.self, forKey: .localId)
        title            = try c.decodeIfPresent(String.self, forKey: .title)
        tripDate         = try c.decode(String.self, forKey: .tripDate)
        locationName     = try c.decodeIfPresent(String.self, forKey: .locationName)
        weatherWind      = try c.decodeIfPresent(String.self, forKey: .weatherWind)
        weatherCondition = try c.decodeIfPresent(String.self, forKey: .weatherCondition)
        companions       = try c.decodeIfPresent([String].self, forKey: .companions)
        notes            = try c.decodeIfPresent(String.self, forKey: .notes)
        syncStatus       = try c.decodeIfPresent(String.self, forKey: .syncStatus)
        styles           = try c.decodeIfPresent([FishingStyle].self, forKey: .styles)
        catches          = try c.decodeIfPresent([FishCatch].self, forKey: .catches)
        catchCount       = try c.decodeIfPresent(Int.self, forKey: .catchCount)
        updatedAt        = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        // weather_temp: PostgreSQL DECIMAL → 可能是 String
        if let str = try? c.decodeIfPresent(String.self, forKey: .weatherTemp) {
            weatherTemp = Double(str)
        } else {
            weatherTemp = try c.decodeIfPresent(Double.self, forKey: .weatherTemp)
        }
        // latitude: PostgreSQL DECIMAL → 可能是 String
        if let str = try? c.decodeIfPresent(String.self, forKey: .latitude) {
            latitude = Double(str)
        } else {
            latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        }
        // longitude: PostgreSQL DECIMAL → 可能是 String
        if let str = try? c.decodeIfPresent(String.self, forKey: .longitude) {
            longitude = Double(str)
        } else {
            longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        }
    }
}

struct FishCatch: Codable, Identifiable {
    let id: String
    let localId: String?
    let tripId: String?
    let species: String?
    let weightG: Int?
    let lengthCm: Double?
    let count: Int?
    let isReleased: Bool?
    let styleCode: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, species, count, notes
        case localId    = "local_id"
        case tripId     = "trip_id"
        case weightG    = "weight_g"
        case lengthCm   = "length_cm"
        case isReleased = "is_released"
        case styleCode  = "style_code"
    }

    // 自定义解码：length_cm 是 DECIMAL(5,1)，node-pg 可能返回 String
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id         = try c.decode(String.self, forKey: .id)
        localId    = try c.decodeIfPresent(String.self, forKey: .localId)
        tripId     = try c.decodeIfPresent(String.self, forKey: .tripId)
        species    = try c.decodeIfPresent(String.self, forKey: .species)
        weightG    = try c.decodeIfPresent(Int.self, forKey: .weightG)
        count      = try c.decodeIfPresent(Int.self, forKey: .count)
        isReleased = try c.decodeIfPresent(Bool.self, forKey: .isReleased)
        styleCode  = try c.decodeIfPresent(String.self, forKey: .styleCode)
        notes      = try c.decodeIfPresent(String.self, forKey: .notes)
        // length_cm: PostgreSQL DECIMAL → 可能是 String
        if let str = try? c.decodeIfPresent(String.self, forKey: .lengthCm) {
            lengthCm = Double(str)
        } else {
            lengthCm = try c.decodeIfPresent(Double.self, forKey: .lengthCm)
        }
    }
}

struct FishingStyle: Codable, Identifiable {
    let id: Int
    let name: String
    let code: String
}
