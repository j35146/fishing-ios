import SwiftUI

enum SyncStatus: String {
    case synced  = "synced"
    case pending = "pending"
    case failed  = "failed"

    var icon: String {
        switch self {
        case .synced:  return "checkmark.circle.fill"
        case .pending: return "arrow.triangle.2.circlepath.circle.fill"
        case .failed:  return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .synced:  return .green
        case .pending: return .accentBlue
        case .failed:  return .destructiveRed
        }
    }
}

struct SyncBadge: View {
    let status: SyncStatus

    var body: some View {
        Image(systemName: status.icon)
            .foregroundColor(status.color)
            .font(.system(size: 14))
    }
}
