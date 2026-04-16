import SwiftUI

struct GearCardView: View {
    let item: Equipment
    var onEdit: () -> Void
    var onDelete: () -> Void

    @State private var showDeleteAlert = false

    var body: some View {
        HStack(spacing: 12) {
            // 左侧图标区
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cardElevated)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "wrench.fill")
                        .foregroundStyle(Color.accentBlue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.flHeadline)
                    .foregroundStyle(Color.textPrimary)

                if let brand = item.brand, let model = item.model,
                   !brand.isEmpty, !model.isEmpty {
                    Text("\(brand) \u{00B7} \(model)")
                        .font(.flCaption)
                        .foregroundStyle(Color.textSecondary)
                } else if let brand = item.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.flCaption)
                        .foregroundStyle(Color.textSecondary)
                }

                HStack(spacing: 6) {
                    // 分类标签
                    if let cat = item.categoryName, !cat.isEmpty {
                        TagBadge(text: cat, color: .accentBlue)
                    }
                    // 状态徽章
                    StatusBadge(status: item.status ?? "active")
                }
            }

            Spacer()
        }
        .padding(FLMetrics.cardPadding)
        .background(Color.cardBackground)
        .cornerRadius(FLMetrics.cornerRadius)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { showDeleteAlert = true } label: {
                Label("删除", systemImage: "trash")
            }
            Button { onEdit() } label: {
                Label("编辑", systemImage: "pencil")
            }
            .tint(.accentBlue)
        }
    }
}

// 分类标签
struct TagBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}

// 状态徽章
struct StatusBadge: View {
    let status: String

    private var displayInfo: (String, Color) {
        switch status {
        case "active": return ("在用", .green)
        case "maintenance": return ("维修中", .orange)
        default: return ("停用", .gray)
        }
    }

    var body: some View {
        let (text, color) = displayInfo
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .cornerRadius(4)
    }
}
