import Foundation
import Alamofire

extension APIClient {
    // 获取装备列表（支持分类筛选）
    // 后端返回 { success, data: [...], pagination: {...} }
    // data 直接是数组，通过 APIResponse<[Equipment]> 解码
    func fetchEquipment(categoryId: Int? = nil, styleTag: String? = nil) async throws -> [Equipment] {
        var path = "/equipment?pageSize=200"
        if let catId = categoryId { path += "&categoryId=\(catId)" }
        if let tag = styleTag { path += "&styleTag=\(tag)" }
        return try await request(path, method: .get,
                                 parameters: nil, encoding: URLEncoding.default)
    }

    // 获取装备分类
    func fetchCategories() async throws -> [EquipmentCategory] {
        return try await request("/equipment/categories", method: .get,
                                 parameters: nil, encoding: URLEncoding.default)
    }

    // 新建装备
    func createEquipment(_ req: CreateEquipmentRequest) async throws -> Equipment {
        return try await request("/equipment", method: .post,
                                 parameters: req.toParameters(),
                                 encoding: JSONEncoding.default)
    }

    // 更新装备
    func updateEquipment(id: String, _ req: UpdateEquipmentRequest) async throws -> Equipment {
        return try await request("/equipment/\(id)", method: .put,
                                 parameters: req.toParameters(),
                                 encoding: JSONEncoding.default)
    }

    // 删除装备
    // 后端返回 { success, data: { id: "..." } }
    func deleteEquipment(id: String) async throws {
        struct DeleteResult: Decodable {
            let id: String?
        }
        let _: DeleteResult = try await request("/equipment/\(id)", method: .delete,
                                                parameters: nil, encoding: JSONEncoding.default)
    }
}

// 将 Encodable 转为 Parameters 字典
private extension Encodable {
    func toParameters() -> Parameters {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? Parameters else {
            return [:]
        }
        return dict
    }
}
