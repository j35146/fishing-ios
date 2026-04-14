import Foundation

enum AppError: LocalizedError {
    case unauthorized
    case notFound
    case serverError(String)
    case networkError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .unauthorized:       return "未授权，请重新登录"
        case .notFound:           return "资源不存在"
        case .serverError(let m): return "服务器错误：\(m)"
        case .networkError(let m):return "网络错误：\(m)"
        case .decodingError:      return "数据解析失败"
        }
    }
}
