import SwiftUI

struct SpotCardView: View {
    let spot: Spot
    var onDelete: () -> Void

    @State private var showDeleteAlert = false

    var body: some View {
        HStack(spacing: 12) {
            // 左侧图标
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cardElevated)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: spotIcon(spot.spotType))
                        .foregroundStyle(Color.accentBlue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.flHeadline)
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: 6) {
                    // 类型标签
                    if let type = spot.spotType {
                        TagBadge(text: SpotType(rawValue: type)?.displayName ?? type,
                                 color: .accentBlue)
                    }
                    // 公开/私密标识
                    if spot.isPublic == true {
                        TagBadge(text: "公开", color: .green)
                    } else {
                        TagBadge(text: "私密", color: .gray)
                    }
                }

                Text("经度: \(String(format: "%.4f", spot.longitude)) 纬度: \(String(format: "%.4f", spot.latitude))")
                    .font(.flCaption)
                    .foregroundStyle(Color.textTertiary)
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
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("删除", role: .destructive) { onDelete() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确认删除此钓点？")
        }
    }

    private func spotIcon(_ type: String?) -> String {
        switch type {
        case "river": return "water.waves"
        case "lake": return "drop.fill"
        case "reservoir": return "building.2.fill"
        case "sea": return "sailboat.fill"
        default: return "location.fill"
        }
    }
}
