import SwiftUI

struct FLPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading { ProgressView().tint(.white) }
                Text(title).font(.flHeadline).foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.primaryGold)
            .cornerRadius(FLMetrics.cornerRadius)
        }
        .disabled(isLoading)
    }
}

struct FLSecondaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title).font(.flHeadline).foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Color.cardBackground)
                .cornerRadius(FLMetrics.cornerRadius)
                .overlay(RoundedRectangle(cornerRadius: FLMetrics.cornerRadius)
                    .stroke(Color.textSecondary.opacity(0.3), lineWidth: 1))
        }
    }
}
