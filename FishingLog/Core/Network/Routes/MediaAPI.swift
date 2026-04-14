import Foundation
import Alamofire

extension APIClient {
    // 上传媒体文件（multipart）
    func uploadMedia(data: Data, mimeType: String, fileName: String) async throws -> UploadResult {
        let url = "\(baseURL)/api/v1/media/upload"
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { form in
                    form.append(data, withName: "file", fileName: fileName, mimeType: mimeType)
                },
                to: url
            )
            .validate()
            .responseDecodable(of: APIResponse<UploadResult>.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    if let result = apiResponse.data {
                        continuation.resume(returning: result)
                    } else {
                        continuation.resume(throwing: AppError.serverError("上传失败"))
                    }
                case .failure(let error):
                    continuation.resume(throwing: AppError.networkError(error.localizedDescription))
                }
            }
        }
    }

    // 获取预签名 URL
    func getPresignedUrl(key: String) async throws -> String {
        struct PresignData: Decodable { let url: String }
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        let result: PresignData = try await request("/media/presign/\(encodedKey)", method: .get,
                                                     parameters: nil, encoding: URLEncoding.default)
        return result.url
    }

    // 删除媒体
    func deleteMedia(key: String) async throws {
        struct EmptyData: Decodable {}
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        let _: EmptyData = try await request("/media/\(encodedKey)", method: .delete,
                                             parameters: nil, encoding: JSONEncoding.default)
    }
}
