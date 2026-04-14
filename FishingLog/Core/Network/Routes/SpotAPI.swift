import Foundation
import Alamofire

extension APIClient {
    // 钓点列表
    func fetchSpots(page: Int = 1, spotType: String? = nil) async throws -> [Spot] {
        var params: Parameters = ["page": page, "pageSize": 50]
        if let t = spotType { params["spot_type"] = t }
        return try await request("/spots", method: .get,
                                 parameters: params, encoding: URLEncoding.default)
    }

    // 附近钓点
    func fetchNearbySpots(lat: Double, lng: Double, radius: Double = 10) async throws -> [Spot] {
        let params: Parameters = ["lat": lat, "lng": lng, "radius": radius]
        return try await request("/spots/nearby", method: .get,
                                 parameters: params, encoding: URLEncoding.default)
    }

    // 新建钓点
    func createSpot(_ req: CreateSpotRequest) async throws -> Spot {
        return try await request("/spots", method: .post,
                                 parameters: req.toParameters(),
                                 encoding: JSONEncoding.default)
    }

    // 删除钓点
    func deleteSpot(id: Int) async throws {
        struct EmptyData: Decodable {}
        let _: EmptyData = try await request("/spots/\(id)", method: .delete,
                                             parameters: nil, encoding: JSONEncoding.default)
    }
}

// Encodable → Parameters
private extension Encodable {
    func toParameters() -> Parameters {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? Parameters else {
            return [:]
        }
        return dict
    }
}
