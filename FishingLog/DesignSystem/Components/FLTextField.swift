import SwiftUI

struct FLTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .foregroundColor(.textPrimary)
            .padding(12)
            .background(Color.cardBackground)
            .cornerRadius(FLMetrics.cornerRadius)
            .overlay(RoundedRectangle(cornerRadius: FLMetrics.cornerRadius)
                .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1))
    }
}
