import Foundation

// 统计概览
struct StatsOverview: Codable {
    let totalTrips: Int
    let totalCatches: Int
    let totalSpecies: Int
    let totalWeightKg: Double

    enum CodingKeys: String, CodingKey {
        case totalTrips = "total_trips"
        case totalCatches = "total_catches"
        case totalSpecies = "total_species"
        case totalWeightKg = "total_weight_kg"
    }
}

// 月度出行
struct SeasonalMonth: Codable, Identifiable {
    var id: Int { month }
    let month: Int
    let count: Int
}

struct SeasonalData: Codable {
    let year: Int
    let months: [SeasonalMonth]
}

// 鱼种分布
struct SpeciesItem: Codable, Identifiable {
    var id: String { name }
    let name: String
    let count: Int
    let percentage: Double
}

// 最大渔获
struct TopCatch: Codable, Identifiable {
    var id: String { "\(fishSpecies)-\(weightKg)" }
    let fishSpecies: String
    let weightKg: Double
    let tripDate: String

    enum CodingKeys: String, CodingKey {
        case fishSpecies = "fish_species"
        case weightKg = "weight_kg"
        case tripDate = "trip_date"
    }
}
