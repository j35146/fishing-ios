import SwiftUI
import PhotosUI
import AVFoundation

// 视频文件传输类型，用于从 PhotosPicker 加载视频
struct VideoTransferable: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            // 复制到临时目录，避免系统清理原始文件
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}

struct Step4SummaryView: View {
    @ObservedObject var vm: NewTripViewModel
    @ObservedObject var uploadManager = MediaUploadManager.shared

    @State private var showPhotoCamera = false
    @State private var showVideoCamera = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    private let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .long; f.locale = Locale(identifier: "zh_CN"); return f
    }()

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    FLCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SummaryRow(label: "日期", value: dateFmt.string(from: vm.tripDate))
                            SummaryRow(label: "地点", value: vm.locationName.isEmpty ? "未填写" : vm.locationName)
                            SummaryRow(label: "钓法", value: vm.selectedStyleCodes
                                .map { $0 == "LURE" ? "路亚" : "台钓" }.joined(separator: "、"))
                            SummaryRow(label: "渔获数量", value: "\(vm.catches.count) 条记录")
                            SummaryRow(label: "所用装备", value: "\(vm.selectedEquipmentIds.count) 件")
                            if !vm.weatherCondition.isEmpty {
                                SummaryRow(label: "天气", value: vm.weatherCondition)
                            }
                        }
                    }

                    // 媒体区域
                    VStack(alignment: .leading, spacing: 8) {
                        Text("出行照片/视频")
                            .font(.flLabel)
                            .foregroundStyle(Color.textSecondary)

                        // 媒体预览网格
                        if !vm.mediaItems.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(80)), count: 3), spacing: 8) {
                                ForEach(vm.mediaItems) { item in
                                    ZStack {
                                        Image(uiImage: item.thumbnail)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        // 视频项显示播放图标
                                        if item.type == .video {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundStyle(.white.opacity(0.85))
                                                .shadow(radius: 2)
                                        }
                                    }
                                }
                            }
                        }

                        // 操作按钮行
                        HStack(spacing: 16) {
                            // 拍摄菜单（拍照+录像）
                            Menu {
                                Button {
                                    showPhotoCamera = true
                                } label: {
                                    Label("拍照", systemImage: "camera")
                                }
                                Button {
                                    showVideoCamera = true
                                } label: {
                                    Label("录像", systemImage: "video")
                                }
                            } label: {
                                Label("拍摄", systemImage: "camera.fill")
                                    .font(.flBody)
                                    .foregroundStyle(Color.accentBlue)
                            }

                            // 从相册选择（支持图片和视频）
                            PhotosPicker(
                                selection: $selectedPhotoItems,
                                maxSelectionCount: 9,
                                matching: .any(of: [.images, .videos])
                            ) {
                                Label("从相册选择", systemImage: "photo.on.rectangle.angled")
                                    .font(.flBody)
                                    .foregroundStyle(Color.accentBlue)
                            }
                            .onChange(of: selectedPhotoItems) { _, newItems in
                                Task { await loadSelectedItems(from: newItems) }
                            }
                        }
                    }
                    .padding(FLMetrics.cardPadding)
                    .background(Color.cardBackground)
                    .cornerRadius(FLMetrics.cornerRadius)

                    Text("保存后将在后台自动同步到服务器")
                        .font(.flCaption).foregroundColor(.textSecondary)
                }
                .padding(.horizontal, FLMetrics.horizontalPadding)
                .padding(.vertical, 16)
            }

            // 上传遮罩
            if uploadManager.isUploading {
                Color.black.opacity(0.5).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.primaryGold)
                        .scaleEffect(1.2)
                    Text("上传中...")
                        .font(.flBody)
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .fullScreenCover(isPresented: $showPhotoCamera) {
            CameraPickerView(mode: .photo) { result in
                if case .photo(let image) = result {
                    let resized = Self.resizedImage(image, maxDimension: 1600)
                    if let jpegData = resized.jpegData(compressionQuality: 0.7) {
                        vm.mediaItems.append(TripMediaItem(
                            type: .photo, thumbnail: resized, data: jpegData, videoURL: nil,
                            mimeType: "image/jpeg", fileName: "photo-\(UUID().uuidString).jpg"
                        ))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showVideoCamera) {
            CameraPickerView(mode: .video) { result in
                if case .video(let url) = result {
                    let thumb = Self.videoThumbnail(url: url)
                    vm.mediaItems.append(TripMediaItem(
                        type: .video, thumbnail: thumb, data: nil, videoURL: url,
                        mimeType: "video/mp4", fileName: "video-\(UUID().uuidString).mp4"
                    ))
                }
            }
        }
    }

    // MARK: - 从相册加载媒体项

    private func loadSelectedItems(from items: [PhotosPickerItem]) async {
        for item in items {
            // 先尝试加载为图片
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let resized = Self.resizedImage(image, maxDimension: 1600)
                if let jpegData = resized.jpegData(compressionQuality: 0.7) {
                    vm.mediaItems.append(TripMediaItem(
                        type: .photo, thumbnail: resized, data: jpegData, videoURL: nil,
                        mimeType: "image/jpeg", fileName: "photo-\(UUID().uuidString).jpg"
                    ))
                }
                continue
            }
            // 再尝试加载为视频
            if let video = try? await item.loadTransferable(type: VideoTransferable.self) {
                let thumb = Self.videoThumbnail(url: video.url)
                vm.mediaItems.append(TripMediaItem(
                    type: .video, thumbnail: thumb, data: nil, videoURL: video.url,
                    mimeType: "video/mp4", fileName: "video-\(UUID().uuidString).mp4"
                ))
            }
        }
    }

    // MARK: - 工具方法

    /// 按最长边等比缩放图片
    static func resizedImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// 从视频 URL 生成缩略图
    static func videoThumbnail(url: URL) -> UIImage {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage(systemName: "video.fill") ?? UIImage()
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.flCaption).foregroundColor(.textSecondary)
            Spacer()
            Text(value).font(.flBody).foregroundColor(.textPrimary)
        }
    }
}
