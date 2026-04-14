import SwiftUI

struct SpotAnnotationView: View {
    let spot: Spot
    @State private var showCallout = false

    var body: some View {
        Button { showCallout.toggle() } label: {
            ZStack {
                Circle()
                    .fill(Color.accentBlue)
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.accentBlue.opacity(0.5), radius: 6)
                Image(systemName: spotIcon(spot.spotType))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .popover(isPresented: $showCallout) {
            SpotCalloutView(spot: spot)
                .presentationCompactAdaptation(.popover)
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

// 简洁浮层 callout
struct SpotCalloutView: View {
    let spot: Spot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(spot.name)
                .font(.flHeadline)
                .foregroundStyle(Color.textPrimary)
            if let type = spot.spotType {
                Text(SpotType(rawValue: type)?.displayName ?? type)
                    .font(.flCaption)
                    .foregroundStyle(Color.accentBlue)
            }
            if let desc = spot.description, !desc.isEmpty {
                Text(desc)
                    .font(.flCaption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color.cardBackground)
    }
}
