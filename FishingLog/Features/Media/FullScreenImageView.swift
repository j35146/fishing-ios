import SwiftUI
import UIKit

struct FullScreenImageView: View {
    let keys: [String]
    let startIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var isSharing = false
    @State private var shareImage: UIImage?

    init(keys: [String], startIndex: Int) {
        self.keys = keys
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(keys.enumerated()), id: \.offset) { index, key in
                    FullScreenMediaImageView(key: key)
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
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    // 分享按钮
                    Button {
                        Task { await shareCurrentImage() }
                    } label: {
                        Image(systemName: isSharing ? "arrow.clockwise" : "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.textPrimary)
                            .padding(16)
                    }
                    .disabled(isSharing)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.textPrimary)
                            .padding(16)
                    }
                }
                Spacer()
                Text("\(currentIndex + 1) / \(keys.count)")
                    .font(.flCaption)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.bottom, 40)
            }
            .sheet(isPresented: Binding(
                get: { shareImage != nil },
                set: { if !$0 { shareImage = nil } }
            )) {
                if let image = shareImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    // 下载当前图片并弹出分享
    private func shareCurrentImage() async {
        guard currentIndex < keys.count else { return }
        isSharing = true
        defer { isSharing = false }

        let key = keys[currentIndex]
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        let urlString = "\(APIClient.shared.baseURL)/api/v1/media/file/\(encodedKey)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        if let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let image = UIImage(data: data) {
                shareImage = image
            }
        } catch {}
    }
}

// 系统分享面板
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// 全屏图片加载（通过 API 代理）
private struct FullScreenMediaImageView: View {
    let key: String
    @State private var uiImage: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else if failed {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.textTertiary)
                    Text("加载失败")
                        .font(.flCaption)
                        .foregroundStyle(Color.textTertiary)
                }
            } else {
                ProgressView().tint(.accentBlue)
            }
        }
        .task { await loadImage() }
    }

    private func loadImage() async {
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        let urlString = "\(APIClient.shared.baseURL)/api/v1/media/file/\(encodedKey)"
        guard let url = URL(string: urlString) else { failed = true; return }

        var request = URLRequest(url: url)
        if let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let image = UIImage(data: data) {
                uiImage = image
            } else {
                failed = true
            }
        } catch {
            failed = true
        }
    }
}
