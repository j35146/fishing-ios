import SwiftUI
import CoreLocation
import PhotosUI
import AVFoundation

struct EditTripView: View {
    let trip: TripEntity
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var tripDate: Date
    @State private var locationName: String
    @State private var latitude: Double
    @State private var longitude: Double
    @State private var title: String
    @State private var selectedStyleCodes: Set<String>
    @State private var weatherTemp: String
    @State private var weatherCondition: String
    @State private var companions: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showMapPicker = false
    @State private var isGeocodingName = false
    @State private var isLoadingWeather = false

    // 渔获管理
    @State private var catches: [CatchEntity] = []
    @State private var showAddCatch = false
    @State private var editingCatch: CatchEntity?

    // 媒体管理
    @State private var existingMedia: [MediaEntity] = []
    @State private var newMediaItems: [TripMediaItem] = []
    @State private var showPhotoCamera = false
    @State private var showVideoCamera = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isUploading = false

    init(trip: TripEntity, onSaved: @escaping () -> Void) {
        self.trip = trip
        self.onSaved = onSaved
        _tripDate = State(initialValue: trip.tripDate ?? Date())
        _locationName = State(initialValue: trip.locationName ?? "")
        _latitude = State(initialValue: trip.latitude)
        _longitude = State(initialValue: trip.longitude)
        _title = State(initialValue: trip.title ?? "")
        _weatherTemp = State(initialValue: trip.weatherTemp != 0 ? String(format: "%.0f", trip.weatherTemp) : "")
        _weatherCondition = State(initialValue: trip.weatherCondition ?? "")
        _companions = State(initialValue: (trip.companions as? [String])?.joined(separator: "、") ?? "")
        _notes = State(initialValue: trip.notes ?? "")
        // 解析钓法
        let codes = (trip.styleIds ?? "").split(separator: ",").map(String.init)
        var styleSet = Set<String>()
        for code in codes {
            switch code.trimmingCharacters(in: .whitespaces) {
            case "1", "TRADITIONAL": styleSet.insert("TRADITIONAL")
            case "2", "LURE": styleSet.insert("LURE")
            default: break
            }
        }
        _selectedStyleCodes = State(initialValue: styleSet)
    }

    private let styles = [("台钓", "TRADITIONAL"), ("路亚", "LURE")]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // 出行日期
                        FLCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("出行日期", systemImage: "calendar")
                                    .font(.flLabel).foregroundColor(.accentBlue)
                                DatePicker("", selection: $tripDate, displayedComponents: .date)
                                    .datePickerStyle(.compact).labelsHidden()
                                    .tint(.primaryGold)
                            }
                        }

                        // 钓法
                        FLCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("钓法", systemImage: "figure.fishing")
                                    .font(.flLabel).foregroundColor(.accentBlue)
                                HStack(spacing: 12) {
                                    ForEach(styles, id: \.1) { name, code in
                                        Toggle(name, isOn: Binding(
                                            get: { selectedStyleCodes.contains(code) },
                                            set: { on in
                                                if on { selectedStyleCodes.insert(code) }
                                                else  { selectedStyleCodes.remove(code) }
                                            }
                                        ))
                                        .toggleStyle(.button).tint(.primaryGold)
                                    }
                                }
                            }
                        }

                        // 地点
                        FLCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Label("钓场/地点", systemImage: "location.fill")
                                        .font(.flLabel).foregroundColor(.textSecondary)
                                    Spacer()
                                    Button {
                                        Task { await reverseGeocodeLocation() }
                                    } label: {
                                        Label(isGeocodingName ? "获取中..." : "自动获取",
                                              systemImage: "arrow.clockwise")
                                            .font(.flCaption)
                                            .foregroundStyle(Color.accentBlue)
                                    }
                                    .disabled(isGeocodingName || (latitude == 0 && longitude == 0))
                                    .opacity((latitude == 0 && longitude == 0) ? 0.4 : 1)
                                }
                                FLTextField(placeholder: "输入钓场名称", text: $locationName)
                                Button { showMapPicker = true } label: {
                                    HStack {
                                        Image(systemName: "map.fill")
                                            .foregroundStyle(Color.accentBlue)
                                        Text(latitude != 0 ? String(format: "已选坐标: %.4f, %.4f", latitude, longitude) : "点击在地图上选择位置")
                                            .font(.flCaption)
                                            .foregroundStyle(latitude != 0 ? Color.textSecondary : Color.textTertiary)
                                            .lineLimit(1)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.flCaption)
                                            .foregroundStyle(Color.textTertiary)
                                    }
                                    .padding(10)
                                    .background(Color.cardElevated)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .fullScreenCover(isPresented: $showMapPicker) {
                            MapLocationPickerView(
                                locationName: $locationName,
                                latitude: $latitude,
                                longitude: $longitude
                            )
                        }

                        // 天气
                        FLCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("天气", systemImage: "cloud.sun.fill")
                                        .font(.flLabel).foregroundColor(.textSecondary)
                                    Spacer()
                                    Button {
                                        Task { await fetchWeather() }
                                    } label: {
                                        Label(isLoadingWeather ? "获取中..." : "自动获取",
                                              systemImage: "arrow.clockwise")
                                            .font(.flCaption)
                                            .foregroundStyle(Color.accentBlue)
                                    }
                                    .disabled(isLoadingWeather || (latitude == 0 && longitude == 0))
                                    .opacity((latitude == 0 && longitude == 0) ? 0.4 : 1)
                                }
                                HStack(spacing: 12) {
                                    FLTextField(placeholder: "温度 ℃", text: $weatherTemp, keyboardType: .decimalPad)
                                        .frame(maxWidth: 100)
                                    FLTextField(placeholder: "天气状况", text: $weatherCondition)
                                }
                            }
                        }

                        // 同行人
                        FLCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("同行钓友", systemImage: "person.2.fill")
                                    .font(.flLabel).foregroundColor(.textSecondary)
                                FLTextField(placeholder: "多人用顿号分隔", text: $companions)
                            }
                        }

                        // 备注
                        FLCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("备注", systemImage: "text.alignleft")
                                    .font(.flLabel).foregroundColor(.textSecondary)
                                TextEditor(text: $notes)
                                    .foregroundColor(.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color.cardElevated)
                                    .cornerRadius(8)
                            }
                        }

                        // 渔获记录管理
                        FLCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("渔获记录", systemImage: "fish.fill")
                                    .font(.flLabel).foregroundColor(.accentBlue)

                                if !catches.isEmpty {
                                    ForEach(catches, id: \.objectID) { c in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(c.species ?? "未知鱼种")
                                                    .font(.flBody).foregroundStyle(Color.textPrimary)
                                                HStack(spacing: 6) {
                                                    if c.weightG > 0 {
                                                        Text("\(c.weightG)g").font(.flCaption).foregroundStyle(Color.textSecondary)
                                                    }
                                                    Text("×\(c.count)").font(.flCaption).foregroundStyle(Color.textSecondary)
                                                    if c.isReleased {
                                                        Text("放流").font(.flCaption).foregroundStyle(Color.primaryGold)
                                                    }
                                                }
                                            }
                                            Spacer()
                                            // 编辑按钮
                                            Button { editingCatch = c } label: {
                                                Image(systemName: "pencil.circle")
                                                    .foregroundStyle(Color.accentBlue)
                                            }
                                            // 删除按钮
                                            Button {
                                                CoreDataManager.shared.deleteCatch(c)
                                                catches.removeAll { $0.objectID == c.objectID }
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundStyle(Color.destructiveRed)
                                                    .font(.flCaption)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                        if c.objectID != catches.last?.objectID {
                                            Divider().background(Color.textTertiary.opacity(0.2))
                                        }
                                    }
                                }

                                Button { showAddCatch = true } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("添加渔获")
                                    }
                                    .font(.flCaption)
                                    .foregroundStyle(Color.primaryGold)
                                }
                            }
                        }
                        .sheet(isPresented: $showAddCatch) {
                            AddCatchSheet(styleCodes: Array(selectedStyleCodes)) { form in
                                let entity = CoreDataManager.shared.createCatch(
                                    trip: trip, species: form.species,
                                    weightG: form.weightG, lengthCm: form.lengthCm,
                                    count: form.count, isReleased: form.isReleased,
                                    styleCode: form.styleCode, notes: nil
                                )
                                catches.append(entity)
                            }
                        }
                        .sheet(item: $editingCatch) { catchEntity in
                            EditCatchSheet(catchEntity: catchEntity, styleCodes: Array(selectedStyleCodes)) {
                                // 刷新列表
                                catches = CoreDataManager.shared.fetchCatches(for: trip)
                            }
                        }

                        // 出行媒体管理
                        FLCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("照片/视频", systemImage: "photo.on.rectangle.angled")
                                    .font(.flLabel).foregroundColor(.textSecondary)

                                // 已有媒体
                                if !existingMedia.isEmpty {
                                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(80)), count: 3), spacing: 8) {
                                        ForEach(existingMedia, id: \.key) { media in
                                            ZStack(alignment: .topTrailing) {
                                                if media.type == "video" {
                                                    Color.cardElevated
                                                        .frame(width: 80, height: 80)
                                                        .cornerRadius(8)
                                                        .overlay(
                                                            Image(systemName: "play.circle.fill")
                                                                .font(.system(size: 24))
                                                                .foregroundStyle(.white.opacity(0.85))
                                                        )
                                                } else {
                                                    MediaImageView(key: media.key ?? "")
                                                        .frame(width: 80, height: 80)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                                // 删除按钮
                                                Button {
                                                    Task { await deleteMedia(media) }
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundStyle(.white, Color.destructiveRed)
                                                }
                                                .offset(x: 4, y: -4)
                                            }
                                        }
                                    }
                                }

                                // 新增媒体预览
                                if !newMediaItems.isEmpty {
                                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(80)), count: 3), spacing: 8) {
                                        ForEach(newMediaItems) { item in
                                            ZStack {
                                                Image(uiImage: item.thumbnail)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                if item.type == .video {
                                                    Image(systemName: "play.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundStyle(.white.opacity(0.85))
                                                }
                                            }
                                        }
                                    }
                                }

                                // 添加按钮
                                HStack(spacing: 12) {
                                    Menu {
                                        Button { showPhotoCamera = true } label: {
                                            Label("拍照", systemImage: "camera")
                                        }
                                        Button { showVideoCamera = true } label: {
                                            Label("录像", systemImage: "video")
                                        }
                                    } label: {
                                        Label("拍摄", systemImage: "camera.fill")
                                            .font(.flCaption)
                                            .foregroundStyle(Color.accentBlue)
                                    }

                                    PhotosPicker(
                                        selection: $selectedPhotoItems,
                                        maxSelectionCount: 9,
                                        matching: .any(of: [.images, .videos])
                                    ) {
                                        Label("从相册选择", systemImage: "photo.on.rectangle.angled")
                                            .font(.flCaption)
                                            .foregroundStyle(Color.accentBlue)
                                    }
                                    .onChange(of: selectedPhotoItems) { _, items in
                                        Task { await loadSelectedItems(items) }
                                    }
                                }
                            }
                        }
                        .fullScreenCover(isPresented: $showPhotoCamera) {
                            CameraPickerView(mode: .photo) { result in
                                if case .photo(let image) = result {
                                    let resized = resizedImage(image, maxDimension: 1600)
                                    if let data = resized.jpegData(compressionQuality: 0.7) {
                                        newMediaItems.append(TripMediaItem(
                                            type: .photo, thumbnail: resized, data: data, videoURL: nil,
                                            mimeType: "image/jpeg", fileName: "photo-\(UUID().uuidString).jpg"
                                        ))
                                    }
                                }
                            }
                        }
                        .fullScreenCover(isPresented: $showVideoCamera) {
                            CameraPickerView(mode: .video) { result in
                                if case .video(let url) = result {
                                    let thumb = videoThumbnail(url: url)
                                    newMediaItems.append(TripMediaItem(
                                        type: .video, thumbnail: thumb, data: nil, videoURL: url,
                                        mimeType: "video/mp4", fileName: "video-\(UUID().uuidString).mp4"
                                    ))
                                }
                            }
                        }

                        if let err = errorMessage {
                            Text(err).font(.flCaption).foregroundStyle(Color.destructiveRed)
                        }

                        // 保存按钮
                        FLPrimaryButton("保存修改", isLoading: isSaving) {
                            Task { await save() }
                        }
                    }
                    .padding(.horizontal, FLMetrics.horizontalPadding)
                    .padding(.vertical, 16)
                }
            }
            .task {
                catches = CoreDataManager.shared.fetchCatches(for: trip)
                existingMedia = CoreDataManager.shared.fetchMedia(for: trip.localId ?? UUID())
            }
            .navigationTitle("编辑出行")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    // 保存修改到 CoreData 并触发同步
    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let styleIds = selectedStyleCodes.joined(separator: ",")
        let styleNames = selectedStyleCodes.map { $0 == "LURE" ? "路亚" : "台钓" }.joined(separator: ",")
        let companionList = companions.split(separator: "、").map(String.init)

        // 更新 CoreData 实体
        trip.tripDate = tripDate
        trip.locationName = locationName.isEmpty ? nil : locationName
        trip.title = title.isEmpty ? nil : title
        trip.styleIds = styleIds
        trip.styleNames = styleNames
        trip.weatherTemp = Double(weatherTemp) ?? 0
        trip.weatherCondition = weatherCondition.isEmpty ? nil : weatherCondition
        trip.companions = companionList
        trip.notes = notes.isEmpty ? nil : notes
        trip.latitude = latitude
        trip.longitude = longitude
        trip.syncStatus = "pending"
        trip.updatedAt = Date()

        CoreDataManager.shared.saveContext()
        SyncManager.shared.syncIfNeeded()

        // 上传新增媒体
        if !newMediaItems.isEmpty {
            let localId = trip.localId ?? UUID()
            for item in newMediaItems {
                if let data = item.data {
                    await MediaUploadManager.shared.uploadMedia(data, mimeType: item.mimeType, fileName: item.fileName, tripLocalId: localId)
                } else if let url = item.videoURL, let data = try? Data(contentsOf: url) {
                    await MediaUploadManager.shared.uploadMedia(data, mimeType: item.mimeType, fileName: item.fileName, tripLocalId: localId)
                }
            }
        }

        onSaved()
        dismiss()
    }

    // 删除已有媒体
    private func deleteMedia(_ media: MediaEntity) async {
        if let key = media.key, !key.isEmpty {
            try? await APIClient.shared.deleteMedia(key: key)
        }
        CoreDataManager.shared.deleteMediaById(id: media.id ?? "")
        existingMedia.removeAll { $0.key == media.key }
    }

    // 从相册加载选中的图片/视频
    private func loadSelectedItems(_ items: [PhotosPickerItem]) async {
        for item in items {
            // 尝试加载图片
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let resized = resizedImage(image, maxDimension: 1600)
                if let jpegData = resized.jpegData(compressionQuality: 0.7) {
                    newMediaItems.append(TripMediaItem(
                        type: .photo, thumbnail: resized, data: jpegData, videoURL: nil,
                        mimeType: "image/jpeg", fileName: "photo-\(UUID().uuidString).jpg"
                    ))
                }
            }
        }
        selectedPhotoItems = []
    }

    // 图片缩放
    private func resizedImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    // 视频缩略图
    private func videoThumbnail(url: URL) -> UIImage {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage(systemName: "video.fill") ?? UIImage()
    }

    // 反向地理编码
    private func reverseGeocodeLocation() async {
        guard latitude != 0, longitude != 0 else { return }
        isGeocodingName = true
        defer { isGeocodingName = false }
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let p = placemarks.first {
                if let name = p.name, !name.isEmpty {
                    locationName = p.locality != nil && !name.contains(p.locality!) ? "\(p.locality!) \(name)" : name
                } else {
                    var parts: [String] = []
                    if let v = p.locality { parts.append(v) }
                    if let v = p.thoroughfare { parts.append(v) }
                    locationName = parts.isEmpty ? String(format: "%.4f, %.4f", latitude, longitude) : parts.joined(separator: " ")
                }
            }
        } catch {
            locationName = String(format: "%.4f, %.4f", latitude, longitude)
        }
    }

    // 自动获取天气
    private func fetchWeather() async {
        guard latitude != 0, longitude != 0 else { return }
        isLoadingWeather = true
        defer { isLoadingWeather = false }
        if let result = await WeatherService.shared.fetchWeather(
            latitude: latitude, longitude: longitude, date: tripDate
        ) {
            weatherTemp = String(format: "%.0f", result.temperature)
            weatherCondition = result.condition
        }
    }
}

// 编辑渔获 Sheet
struct EditCatchSheet: View {
    let catchEntity: CatchEntity
    let styleCodes: [String]
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var species: String
    @State private var weightStr: String
    @State private var lengthStr: String
    @State private var countStr: String
    @State private var isReleased: Bool
    @State private var styleCode: String?

    init(catchEntity: CatchEntity, styleCodes: [String], onSaved: @escaping () -> Void) {
        self.catchEntity = catchEntity
        self.styleCodes = styleCodes
        self.onSaved = onSaved
        _species = State(initialValue: catchEntity.species ?? "")
        _weightStr = State(initialValue: catchEntity.weightG > 0 ? "\(catchEntity.weightG)" : "")
        _lengthStr = State(initialValue: catchEntity.lengthCm > 0 ? String(format: "%.1f", catchEntity.lengthCm) : "")
        _countStr = State(initialValue: "\(catchEntity.count)")
        _isReleased = State(initialValue: catchEntity.isReleased)
        _styleCode = State(initialValue: catchEntity.styleCode)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FLCard {
                            VStack(spacing: 12) {
                                FLTextField(placeholder: "鱼种名称（必填）", text: $species)
                                HStack {
                                    FLTextField(placeholder: "重量 (g)", text: $weightStr, keyboardType: .numberPad)
                                    FLTextField(placeholder: "体长 (cm)", text: $lengthStr, keyboardType: .decimalPad)
                                }
                                HStack {
                                    FLTextField(placeholder: "数量", text: $countStr, keyboardType: .numberPad)
                                        .frame(maxWidth: 80)
                                    Text("尾").font(.flBody).foregroundColor(.textSecondary)
                                }
                                HStack {
                                    Text("已放流").font(.flBody).foregroundColor(.textPrimary)
                                    Spacer()
                                    Toggle("", isOn: $isReleased).tint(.primaryGold)
                                }
                                if !styleCodes.isEmpty {
                                    HStack {
                                        Text("钓法归属").font(.flBody).foregroundColor(.textPrimary)
                                        Spacer()
                                        Picker("", selection: $styleCode) {
                                            Text("不指定").tag(Optional<String>.none)
                                            ForEach(styleCodes, id: \.self) { code in
                                                Text(code == "LURE" ? "路亚" : "台钓").tag(Optional(code))
                                            }
                                        }.tint(.primaryGold)
                                    }
                                }
                            }
                        }
                    }
                    .padding(FLMetrics.horizontalPadding)
                }
            }
            .navigationTitle("编辑渔获")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }.foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        catchEntity.species = species
                        catchEntity.weightG = Int32(weightStr) ?? 0
                        catchEntity.lengthCm = Double(lengthStr) ?? 0
                        catchEntity.count = Int16(max(1, Int(countStr) ?? 1))
                        catchEntity.isReleased = isReleased
                        catchEntity.styleCode = styleCode
                        CoreDataManager.shared.saveContext()
                        onSaved()
                        dismiss()
                    }
                    .disabled(species.isEmpty)
                    .foregroundColor(species.isEmpty ? .textSecondary : .primaryGold)
                }
            }
        }
    }
}
