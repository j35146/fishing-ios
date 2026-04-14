import SwiftUI

struct TripCardView: View {
    let trip: TripEntity

    private var displayDate: String {
        guard let date = trip.tripDate else { return "未知日期" }
        let fmt = DateFormatter(); fmt.dateStyle = .medium; fmt.locale = Locale(identifier: "zh_CN")
        return fmt.string(from: date)
    }

    private var styleTagNames: [String] {
        (trip.styleNames ?? "").split(separator: ",").map(String.init)
    }

    private var syncStatus: SyncStatus {
        SyncStatus(rawValue: trip.syncStatus ?? "pending") ?? .pending
    }

    var body: some View {
        FLCard {
            VStack(alignment: .leading, spacing: 10) {
                // 顶部：日期 + 同步状态
                HStack {
                    Text(displayDate).font(.flCaption).foregroundColor(.textSecondary)
                    Spacer()
                    SyncBadge(status: syncStatus)
                }

                // 地点
                Text(trip.locationName ?? "未记录地点")
                    .font(.flHeadline).foregroundColor(.textPrimary)
                    .lineLimit(1)

                // 钓法标签 + 渔获数
                HStack(spacing: 8) {
                    ForEach(styleTagNames, id: \.self) { tag in
                        Text(tag).font(.flCaption).foregroundColor(.appBackground)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.accentBlue)
                            .cornerRadius(6)
                    }
                    Spacer()
                    let catchCount = trip.catches?.count ?? 0
                    Label("\(catchCount) 尾", systemImage: "fish.fill")
                        .font(.flCaption).foregroundColor(.textSecondary)
                }
            }
        }
    }
}
