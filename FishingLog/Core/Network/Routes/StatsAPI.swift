import Foundation
import Alamofire

extension APIClient {
    // 总览统计
    func fetchStatsOverview() async throws -> StatsOverview {
        return try await request("/stats/overview", method: .get,
                                 parameters: nil, encoding: URLEncoding.default)
    }

    // 季节性趋势（按年）
    func fetchSeasonal(year: Int? = nil) async throws -> SeasonalData {
        var params: Parameters = [:]
        if let year { params["year"] = year }
        return try await request("/stats/seasonal", method: .get,
                                 parameters: params.isEmpty ? nil : params,
                                 encoding: URLEncoding.default)
    }

    // 鱼种分布
    func fetchSpecies() async throws -> [SpeciesItem] {
        return try await request("/stats/species", method: .get,
                                 parameters: nil, encoding: URLEncoding.default)
    }

    // Top 渔获
    func fetchTopCatches() async throws -> [TopCatch] {
        return try await request("/stats/top-catches", method: .get,
                                 parameters: nil, encoding: URLEncoding.default)
    }
}
