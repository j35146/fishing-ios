import Foundation
import Alamofire

extension APIClient {
    // 分页获取出行列表
    // 后端返回 { success, data: [...], pagination: {...} }
    func fetchTrips(page: Int = 1, pageSize: Int = 50) async throws -> [Trip] {
        return try await request(
            "/trips?page=\(page)&pageSize=\(pageSize)",
            method: .get,
            parameters: nil,
            encoding: URLEncoding.default
        )
    }

    // 批量同步
    func syncTrips(_ items: [[String: Any]]) async throws -> [[String: Any]] {
        let url = "\(baseURL)/api/v1/trips/sync"
        return try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: .post,
                            parameters: ["trips": items],
                            encoding: JSONEncoding.default)
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success(let json):
                        if let dict = json as? [String: Any],
                           let data = dict["data"] as? [[String: Any]] {
                            continuation.resume(returning: data)
                        } else {
                            continuation.resume(returning: [])
                        }
                    case .failure(let error):
                        continuation.resume(throwing: AppError.networkError(error.localizedDescription))
                    }
                }
        }
    }

    // 删除出行
    func deleteTrip(id: String) async throws {
        let _: EmptyResponse = try await request("/trips/\(id)", method: .delete)
    }
}

struct EmptyResponse: Decodable {}
