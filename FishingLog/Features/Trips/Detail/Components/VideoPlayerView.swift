import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let key: String
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var error: String?
    @State private var isDownloading = false
    @State private var shareFileURL: URL?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else if let error {
                // 加载失败时显示错误提示
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.textTertiary)
                    Text(error)
                        .font(.flCaption)
                        .foregroundStyle(Color.textTertiary)
                }
            } else {
                // 加载中显示进度指示器
                ProgressView().tint(.accentBlue)
            }
            // 顶部按钮栏
            VStack {
                HStack {
                    // 分享按钮
                    Button {
                        Task { await downloadAndShare() }
                    } label: {
                        if isDownloading {
                            ProgressView()
                                .tint(.white)
                                .padding(16)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.textPrimary)
                                .padding(16)
                        }
                    }
                    .disabled(isDownloading)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.textPrimary)
                            .padding(16)
                    }
                }
                Spacer()
            }
            .sheet(isPresented: Binding(
                get: { shareFileURL != nil },
                set: { if !$0 { shareFileURL = nil } }
            )) {
                if let url = shareFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .task { await loadVideo() }
        .onDisappear { player?.pause() }
    }

    // 下载视频到临时文件并弹出分享
    private func downloadAndShare() async {
        isDownloading = true
        defer { isDownloading = false }

        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        let urlString = "\(APIClient.shared.baseURL)/api/v1/media/file/\(encodedKey)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        if let token = KeychainManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // 写入临时文件
                let ext = key.hasSuffix(".mov") ? "mov" : "mp4"
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(ext)
                try data.write(to: tempURL)
                // 暂停播放后弹出分享
                player?.pause()
                shareFileURL = tempURL
            }
        } catch {}
    }

    // 通过预签名 URL 加载视频（无需自定义 HTTP 头，兼容性最好）
    private func loadVideo() async {
        do {
            let presignURL = try await APIClient.shared.getPresignedUrl(key: key)
            guard let url = URL(string: presignURL) else { error = "无效地址"; return }
            player = AVPlayer(url: url)
            player?.play()
        } catch {
            self.error = "视频加载失败"
        }
    }
}
