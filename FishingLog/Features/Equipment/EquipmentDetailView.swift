import SwiftUI

struct EquipmentDetailView: View {
    let item: Equipment
    let categories: [EquipmentCategory]
    let onUpdated: () -> Void

    @State private var showEdit = false

    // 显示格式：仅日期
    private let displayFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // 名称 + 状态
                    FLCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(item.name)
                                    .font(.flTitle)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                StatusBadge(status: item.status ?? "active")
                            }
                            // 分类标签
                            HStack(spacing: 8) {
                                if let cat = item.categoryName, !cat.isEmpty {
                                    TagBadge(text: cat, color: .accentBlue)
                                }
                                if let tags = item.styleTags {
                                    ForEach(tags, id: \.self) { tag in
                                        TagBadge(text: tag == "LURE" ? "路亚" : "台钓", color: .primaryGold)
                                    }
                                }
                            }
                        }
                    }

                    // 品牌型号
                    if (item.brand != nil && !item.brand!.isEmpty) || (item.model != nil && !item.model!.isEmpty) {
                        FLCard {
                            VStack(alignment: .leading, spacing: 10) {
                                if let brand = item.brand, !brand.isEmpty {
                                    DetailRow(label: "品牌", value: brand)
                                }
                                if let model = item.model, !model.isEmpty {
                                    DetailRow(label: "型号", value: model)
                                }
                            }
                        }
                    }

                    // 购入信息
                    if item.purchaseDate != nil || item.purchasePrice != nil {
                        FLCard {
                            VStack(alignment: .leading, spacing: 10) {
                                if let dateStr = item.purchaseDate {
                                    DetailRow(label: "购入日期", value: parseAndFormatDate(dateStr))
                                }
                                if let price = item.purchasePrice, price > 0 {
                                    DetailRow(label: "购入价格", value: "¥\(String(format: "%.0f", price))")
                                }
                            }
                        }
                    }

                    // 备注
                    if let notes = item.notes, !notes.isEmpty {
                        FLCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("备注")
                                    .font(.flLabel)
                                    .foregroundStyle(Color.textSecondary)
                                Text(notes)
                                    .font(.flBody)
                                    .foregroundStyle(Color.textPrimary)
                            }
                        }
                    }

                    // 编辑按钮
                    FLPrimaryButton("编辑") {
                        showEdit = true
                    }
                }
                .padding(.horizontal, FLMetrics.horizontalPadding)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("装备详情")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEdit) {
            EditEquipmentView(item: item, categories: categories, onSaved: onUpdated)
        }
    }

    // 解析多种日期格式，统一输出仅日期
    private func parseAndFormatDate(_ str: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: str) { return displayFmt.string(from: date) }
        if let date = ISO8601DateFormatter().date(from: str) { return displayFmt.string(from: date) }
        let simple = DateFormatter()
        simple.dateFormat = "yyyy-MM-dd"
        if let date = simple.date(from: str) { return displayFmt.string(from: date) }
        return str
    }
}

// 详情行
private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.flCaption)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.flBody)
                .foregroundStyle(Color.textPrimary)
        }
    }
}
