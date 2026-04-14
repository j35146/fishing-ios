import SwiftUI

struct FLCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(FLMetrics.cardPadding)
            .background(Color.cardBackground)
            .cornerRadius(FLMetrics.cornerRadius)
    }
}
