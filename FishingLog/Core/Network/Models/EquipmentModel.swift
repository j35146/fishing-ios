import Foundation

struct Equipment: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String?
    let model: String?
    let categoryId: Int?
    let categoryName: String?
    let styleTags: [String]?
    let status: String?
    let purchaseDate: String?
    let purchasePrice: Double?
    let notes: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, brand, model, notes, status
        case categoryId = "category_id"
        case categoryName = "category_name"
        case styleTags = "style_tags"
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case createdAt = "created_at"
    }

    // 自定义解码：处理 purchase_price 可能是 String（PostgreSQL DECIMAL）或 Number
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // id 可能是 Int 或 String
        if let intId = try? c.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = try c.decode(String.self, forKey: .id)
        }
        name          = try c.decode(String.self, forKey: .name)
        brand         = try c.decodeIfPresent(String.self, forKey: .brand)
        model         = try c.decodeIfPresent(String.self, forKey: .model)
        categoryId    = try c.decodeIfPresent(Int.self, forKey: .categoryId)
        categoryName  = try c.decodeIfPresent(String.self, forKey: .categoryName)
        styleTags     = try c.decodeIfPresent([String].self, forKey: .styleTags)
        status        = try c.decodeIfPresent(String.self, forKey: .status)
        purchaseDate  = try c.decodeIfPresent(String.self, forKey: .purchaseDate)
        notes         = try c.decodeIfPresent(String.self, forKey: .notes)
        createdAt     = try c.decodeIfPresent(String.self, forKey: .createdAt)
        // purchase_price: PostgreSQL DECIMAL 会被 node-pg 序列化为 String
        if let strPrice = try? c.decodeIfPresent(String.self, forKey: .purchasePrice) {
            purchasePrice = Double(strPrice)
        } else {
            purchasePrice = try c.decodeIfPresent(Double.self, forKey: .purchasePrice)
        }
    }
}

struct EquipmentCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let groupCode: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case groupCode = "group_code"
    }
}

// 装备大类
enum EquipmentGroup: String, CaseIterable, Identifiable {
    case traditional = "traditional"
    case lure = "lure"

    var id: String { rawValue }
    // API 筛选用大写（与数据库 style_tags 一致）
    var styleTag: String { rawValue.uppercased() }
    var displayName: String {
        switch self {
        case .traditional: "台钓"
        case .lure: "路亚"
        }
    }
}

struct CreateEquipmentRequest: Encodable {
    let name: String
    let brand: String?
    let model: String?
    let categoryId: Int?
    let styleTags: [String]?
    let status: String?
    let purchaseDate: String?
    let purchasePrice: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case name, brand, model, notes, status
        case categoryId = "category_id"
        case styleTags = "style_tags"
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
    }
}

typealias UpdateEquipmentRequest = CreateEquipmentRequest
