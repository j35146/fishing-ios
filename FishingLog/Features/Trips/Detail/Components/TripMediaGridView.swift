import SwiftUI

// 使 String 符合 Identifiable，用于 fullScreenCover(item:) 传递视频 key
extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct TripMediaGridView: View {
    let tripLocalId: UUID
    @State private var mediaItems: [MediaEntity] = []
    @State private var selectedIndex: Int?
    @State private var selectedVideoKey: String?
    @State private var loaded = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("出行相册")
                    .font(.flHeadline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if !mediaItems.isEmpty {
                    Text("\(mediaItems.count) 张")
                        .font(.flCaption)
                        .foregroundStyle(Color.textTertiary)
                }
            }

            if mediaItems.isEmpty && loaded {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.textTertiary)
                        Text("暂无照片")
                            .font(.flCaption)
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else if !mediaItems.isEmpty && mediaItems.allSatisfy({ $0.syncStatus == "failed" }) {
                // 所有媒体上传失败，显示错误详情
                VStack(spacing: 6) {
                    Text("照片上传失败")
                        .font(.flCaption)
                        .foregroundStyle(Color.destructiveRed)
                    ForEach(Array(mediaItems.prefix(2).enumerated()), id: \.offset) { _, m in
                        Text("key: \(m.key ?? "-") status: \(m.syncStatus ?? "-")")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.textTertiary)
                    }
                    Text("上次错误: \(MediaUploadManager.shared.lastError ?? "未知")")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.textTertiary)
                }
            } else if !mediaItems.isEmpty {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(mediaItems.enumerated()), id: \.offset) { index, item in
                        ZStack {
                            if item.type == "video" {
                                // 视频：显示占位背景 + 播放图标
                                Color.cardElevated
                                    .frame(height: 100)
                                    .cornerRadius(6)
                                    .overlay(
                                        VStack(spacing: 4) {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 32))
                                                .foregroundStyle(.white.opacity(0.85))
                                            Text("视频")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Color.textTertiary)
                                        }
                                    )
                            } else {
                                // 图片：正常加载缩略图
                                MediaImageView(key: item.key ?? "")
                                    .frame(height: 100)
                                    .clipped()
                                    .cornerRadius(6)
                            }
                        }
                        .onTapGesture {
                            if item.type == "video" {
                                // 视频点击：打开全屏播放器
                                selectedVideoKey = item.key
                            } else {
                                // 图片点击：在仅图片列表中定位索引
                                let imageItems = mediaItems.filter { $0.type != "video" }
                                if let imgIdx = imageItems.firstIndex(where: { $0.key == item.key }) {
                                    selectedIndex = imageItems.distance(from: imageItems.startIndex, to: imgIdx)
                                }
                            }
                        }
                    }
                }
                // 全屏图片查看器
                .fullScreenCover(isPresented: Binding(
                    get: { selectedIndex != nil },
                    set: { if !$0 { selectedIndex = nil } }
                )) {
                    if let index = selectedIndex {
                        // 仅传入图片类型的 key，过滤掉视频
                        let imageKeys = mediaItems.filter { $0.type != "video" }.compactMap { $0.key }
                        FullScreenImageView(
                            keys: imageKeys,
                            startIndex: index
                        )
                    }
                }
                // 全屏视频播放器
                .fullScreenCover(item: $selectedVideoKey) { key in
                    VideoPlayerView(key: key)
                }
            }
        }
        .padding(FLMetrics.cardPadding)
        .background(Color.cardBackground)
        .cornerRadius(FLMetrics.cornerRadius)
        .task {
            mediaItems = CoreDataManager.shared.fetchMedia(for: tripLocalId)
            loaded = true
        }
    }
}

// 通过 API 代理加载图片（走 80 端口，带 Token 认证）
struct MediaImageView: View {
    let key: String
    @State private var uiImage: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if failed {
                Color.cardElevated
                    .overlay(
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Color.textTertiary)
                    )
            } else {
                Color.cardElevated
                    .overlay(ProgressView().tint(.accentBlue))
            }
        }
        .task { await loadImage() }
    }

    private func loadImage() async {
        guard !key.isEmpty else { failed = true; return }
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
