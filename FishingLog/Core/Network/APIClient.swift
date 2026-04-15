import Foundation
import Alamofire

final class APIClient {
    static let shared = APIClient()

    let baseURL: String
    lazy var session: Session = {
        let interceptor = AuthInterceptor()
        return Session(interceptor: interceptor)
    }()

    private init() {
        // 从 Config.plist 读取 base URL
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let url = dict["API_BASE_URL"] as? String {
            baseURL = url
        } else {
            baseURL = "http://localhost"
        }
    }

    // MARK: - 通用请求
    func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default
    ) async throws -> T {
        let url = "\(baseURL)/api/v1\(path)"
        return try await withCheckedThrowingContinuation { continuation in
            session.request(url, method: method, parameters: parameters, encoding: encoding)
                .validate()
                .responseDecodable(of: APIResponse<T>.self) { response in
                    switch response.result {
                    case .success(let apiResponse):
                        if let data = apiResponse.data {
                            continuation.resume(returning: data)
                        } else {
                            continuation.resume(throwing: AppError.serverError("无数据"))
                        }
                    case .failure(let error):
                        continuation.resume(throwing: AppError.networkError(error.localizedDescription))
                    }
                }
        }
    }

    // MARK: - 登录（无需 token）
    func login(username: String, password: String) async throws -> String {
        let url = "\(baseURL)/api/v1/auth/login"
        struct LoginResponse: Decodable { let token: String }
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: .post,
                       parameters: ["username": username, "password": password],
                       encoding: JSONEncoding.default)
                .validate()
                .responseDecodable(of: APIResponse<LoginResponse>.self) { response in
                    switch response.result {
                    case .success(let r):
                        if let token = r.data?.token {
                            continuation.resume(returning: token)
                        } else {
                            continuation.resume(throwing: AppError.serverError("Token 为空"))
                        }
                    case .failure:
                        continuation.resume(throwing: AppError.unauthorized)
                    }
                }
        }
    }
}

// MARK: - 统一响应结构
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

// MARK: - Token 自动注入
final class AuthInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session,
               completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        if let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        completion(.success(request))
    }
}
