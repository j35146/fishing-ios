import SwiftUI
import PhotosUI

struct Step4SummaryView: View {
    @ObservedObject var vm: NewTripViewModel
    @ObservedObject var uploadManager = MediaUploadManager.shared

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

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

                    // 照片区域
                    VStack(alignment: .leading, spacing: 8) {
                        Text("出行照片")
                            .font(.flLabel)
                            .foregroundStyle(Color.textSecondary)

                        if !selectedImages.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(80)), count: 3), spacing: 8) {
                                ForEach(0..<selectedImages.count, id: \.self) { i in
                                    Image(uiImage: selectedImages[i])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }

                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: 9,
                            matching: .images
                        ) {
                            Label("添加照片", systemImage: "photo.on.rectangle.angled")
                                .font(.flBody)
                                .foregroundStyle(Color.accentBlue)
                        }
                        .onChange(of: selectedItems) { _, newItems in
                            Task { await loadImages(from: newItems) }
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
    }

    // 将照片数据传递给 ViewModel
    var imageDataArray: [Data] {
        selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        selectedImages = images
        // 传递照片数据给 ViewModel 以便保存时上传
        vm.photoDataArray = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
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
