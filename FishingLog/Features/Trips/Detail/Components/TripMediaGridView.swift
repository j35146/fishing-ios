import SwiftUI

struct TripMediaGridView: View {
    let tripLocalId: UUID
    @State private var mediaItems: [MediaEntity] = []
    @State private var selectedIndex: Int?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    var body: some View {
        if !mediaItems.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("出行相册")
                        .font(.flHeadline)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("\(mediaItems.count) 张")
                        .font(.flCaption)
                        .foregroundStyle(Color.textTertiary)
                }

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(mediaItems.enumerated()), id: \.offset) { index, item in
                        AsyncImage(url: URL(string: item.url ?? "")) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            default:
                                Color.cardElevated
                            }
                        }
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(6)
                        .onTapGesture { selectedIndex = index }
                    }
                }
            }
            .padding(FLMetrics.cardPadding)
            .background(Color.cardBackground)
            .cornerRadius(FLMetrics.cornerRadius)
            .fullScreenCover(isPresented: Binding(
                get: { selectedIndex != nil },
                set: { if !$0 { selectedIndex = nil } }
            )) {
                if let index = selectedIndex {
                    FullScreenImageView(
                        urls: mediaItems.compactMap { $0.url },
                        startIndex: index
                    )
                }
            }
        }
    }

    init(tripLocalId: UUID) {
        self.tripLocalId = tripLocalId
        _mediaItems = State(initialValue: CoreDataManager.shared.fetchMedia(for: tripLocalId))
    }
}
