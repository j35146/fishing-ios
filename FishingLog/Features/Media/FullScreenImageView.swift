import SwiftUI

struct FullScreenImageView: View {
    let urls: [String]
    let startIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0

    init(urls: [String], startIndex: Int) {
        self.urls = urls
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, urlString in
                    AsyncImage(url: URL(string: urlString)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(scale)
                                .gesture(
                                    MagnifyGesture()
                                        .onChanged { value in
                                            scale = min(max(value.magnification, 1.0), 4.0)
                                        }
                                        .onEnded { _ in
                                            withAnimation { scale = 1.0 }
                                        }
                                )
                        case .failure:
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.textTertiary)
                                Text("加载失败")
                                    .font(.flCaption)
                                    .foregroundStyle(Color.textTertiary)
                            }
                        default:
                            ProgressView().tint(.accentBlue)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // 顶部关闭按钮
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.textPrimary)
                            .padding(16)
                    }
                }
                Spacer()
                // 底部页码
                Text("\(currentIndex + 1) / \(urls.count)")
                    .font(.flCaption)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.bottom, 40)
            }
        }
    }
}
