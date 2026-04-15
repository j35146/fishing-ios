# 地图选点 + 拍照录像 + WeatherKit 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为新建出行添加地图选点、相机拍照/录像、天气自动获取三个功能

**Architecture:** 在现有 MVVM + offline-first 架构上扩展。地图选点用 MapKit 搜索+标注，坐标直接存 TripEntity（需后端加字段）。拍照/录像用 UIImagePickerController 包装，视频自动压缩到 720p 后上传，详情页用 AVKit VideoPlayer 播放。WeatherKit 在选定位置后自动获取天气并填入表单。

**Tech Stack:** SwiftUI, MapKit, CoreLocation, AVKit, AVFoundation, WeatherKit, PhotosUI

---

## 文件结构规划

### 新建文件
| 文件 | 职责 |
|------|------|
| `FishingLog/Features/Trips/NewTrip/MapLocationPickerView.swift` | 地图搜索+选点全屏页面 |
| `FishingLog/Features/Trips/NewTrip/CameraPickerView.swift` | UIImagePickerController 包装（拍照+录像） |
| `FishingLog/Features/Trips/Detail/Components/VideoPlayerView.swift` | 视频在线播放组件 |
| `FishingLog/Core/Weather/WeatherService.swift` | WeatherKit 封装，获取当日/历史天气 |

### 修改文件
| 文件 | 改动 |
|------|------|
| `FishingLog/Resources/FishingLog.xcdatamodeld/…/contents` | TripEntity 加 latitude/longitude/spotId |
| `FishingLog/Core/CoreData/CoreDataManager.swift` | createTrip/upsertTrip 加经纬度字段 |
| `FishingLog/Core/Network/Models/TripModel.swift` | Trip 结构体加 latitude/longitude |
| `FishingLog/Core/Sync/SyncManager.swift` | sync payload 加经纬度 |
| `FishingLog/Features/Trips/NewTrip/NewTripViewModel.swift` | 加坐标、视频数据、天气获取 |
| `FishingLog/Features/Trips/NewTrip/Step1BasicInfoView.swift` | 地点改为地图选择、天气自动获取按钮 |
| `FishingLog/Features/Trips/NewTrip/Step4SummaryView.swift` | 加拍照/录像菜单、视频预览 |
| `FishingLog/Features/Trips/Detail/TripDetailView.swift` | 加内嵌小地图 |
| `FishingLog/Features/Trips/Detail/Components/TripMediaGridView.swift` | 视频缩略图+播放按钮 |
| `FishingLog/Features/Media/FullScreenImageView.swift` | 支持视频全屏播放 |
| `FishingLog/Core/Media/MediaUploadManager.swift` | 支持视频上传 |
| `project.yml` | 加 WeatherKit capability |
| **服务端** `fishing-server/src/db/migrate.js` | fishing_trips 加 latitude/longitude 列 |
| **服务端** `fishing-server/src/routes/trips.js` | sync 接口接收 latitude/longitude |

---

## Task 1: 后端 — fishing_trips 表加经纬度字段

**Files:**
- Modify: `fishing-server/src/db/migrate.js`
- Modify: `fishing-server/src/routes/trips.js`

- [ ] **Step 1: 给 fishing_trips 表添加 latitude/longitude 列**

在生产服务器上执行 SQL：

```sql
ALTER TABLE fishing_trips ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8);
ALTER TABLE fishing_trips ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8);
```

- [ ] **Step 2: 修改 migrate.js，在 fishing_trips 建表语句中加入新字段**

在 `fishing_trips` 建表的 `location_name` 行之后添加：

```javascript
        latitude DECIMAL(10,8),
        longitude DECIMAL(11,8),
```

- [ ] **Step 3: 修改 trips.js — sync 接口接收 latitude/longitude**

在 `syncSchema` 的 properties 中添加：

```javascript
        latitude: { type: 'number' },
        longitude: { type: 'number' },
```

在 sync endpoint 的 INSERT 和 UPDATE SQL 中加入 `latitude` 和 `longitude` 字段。

具体改动：sync 函数中解构时增加 `latitude, longitude`，INSERT 语句增加这两个字段占位符，UPDATE 语句中用 `COALESCE(latitude, t.latitude)` 处理。

- [ ] **Step 4: 修改 trips.js — GET 接口返回 latitude/longitude**

在 GET `/trips` 和 GET `/trips/:id` 的 SELECT 语句中加入 `t.latitude, t.longitude`。

- [ ] **Step 5: 部署到生产服务器并验证**

```bash
# SSH 到生产服务器
# 1. 执行 SQL
docker exec fishing-server-postgres-1 psql -U fishing -d fishing -c "ALTER TABLE fishing_trips ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8); ALTER TABLE fishing_trips ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8);"
# 2. 更新代码文件（scp 或直接编辑）
# 3. 重建 app
cd /opt/fishing-server && docker compose up -d --build app
# 4. 验证
curl -s "http://home.weixia.org:35146/api/v1/trips?page=1&pageSize=1" -H "Authorization: Bearer TOKEN" | python3 -m json.tool
```

---

## Task 2: CoreData 模型 — TripEntity 加经纬度

**Files:**
- Modify: `FishingLog/Resources/FishingLog.xcdatamodeld/.../contents`
- Modify: `FishingLog/Core/CoreData/CoreDataManager.swift`

- [ ] **Step 1: 编辑 CoreData 模型 XML，给 TripEntity 加 3 个属性**

在 TripEntity 的 `<attribute>` 列表中（`locationName` 之后）添加：

```xml
<attribute name="latitude" optional="YES" attributeType="Double" defaultValueString="0" usesScalarValueType="YES"/>
<attribute name="longitude" optional="YES" attributeType="Double" defaultValueString="0" usesScalarValueType="YES"/>
<attribute name="spotId" optional="YES" attributeType="String"/>
```

- [ ] **Step 2: 修改 CoreDataManager.createTrip — 增加经纬度参数**

给 `createTrip` 方法签名添加 `latitude: Double?, longitude: Double?` 参数，在函数体中赋值：

```swift
entity.latitude = latitude ?? 0
entity.longitude = longitude ?? 0
```

- [ ] **Step 3: 修改 CoreDataManager.upsertTrip — 从服务端数据更新经纬度**

在 `upsertTrip(from trip: Trip)` 中添加：

```swift
if let lat = trip.latitude { entity.latitude = lat }
if let lng = trip.longitude { entity.longitude = lng }
```

- [ ] **Step 4: 编译验证**

```bash
xcodebuild build -project FishingLog.xcodeproj -scheme FishingLog -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/fl-build CODE_SIGNING_ALLOWED=NO -quiet
```

---

## Task 3: 网络模型 + 同步 — 经纬度贯通

**Files:**
- Modify: `FishingLog/Core/Network/Models/TripModel.swift`
- Modify: `FishingLog/Core/Sync/SyncManager.swift`

- [ ] **Step 1: Trip 模型加 latitude/longitude 字段**

在 `Trip` 结构体中添加属性：

```swift
let latitude: Double?
let longitude: Double?
```

在 `CodingKeys` 中添加：

```swift
case latitude, longitude
```

在 `init(from decoder:)` 中，用和 `weatherTemp` 相同的灵活解码方式（支持 String 和 Double）：

```swift
if let str = try? c.decodeIfPresent(String.self, forKey: .latitude) {
    latitude = Double(str)
} else {
    latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
}
// longitude 同理
```

- [ ] **Step 2: SyncManager 同步 payload 加经纬度**

在 `sync(trips:)` 方法中，构建 items 字典时添加：

```swift
"latitude"      : trip.latitude != 0 ? trip.latitude : NSNull(),
"longitude"     : trip.longitude != 0 ? trip.longitude : NSNull(),
```

- [ ] **Step 3: 编译验证**

---

## Task 4: 地图选点页面 — MapLocationPickerView

**Files:**
- Create: `FishingLog/Features/Trips/NewTrip/MapLocationPickerView.swift`

- [ ] **Step 1: 创建 MapLocationPickerView**

完整实现，包含：
- 顶部搜索栏：使用 `MKLocalSearchCompleter` 实现搜索建议
- 地图主体：`Map` 视图，支持长按选点 + 搜索结果标注
- 底部确认栏：显示选中的地名和坐标，「确认」按钮

```swift
import SwiftUI
import MapKit

struct MapLocationPickerView: View {
    @Binding var locationName: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Environment(\.dismiss) private var dismiss

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // 搜索栏
                    searchBar
                    // 搜索结果列表（覆盖在地图上方）
                    if isSearching && !searchResults.isEmpty {
                        searchResultsList
                    }
                    // 地图
                    mapView
                    // 底部确认栏
                    if selectedCoordinate != nil {
                        confirmBar
                    }
                }
            }
            .navigationTitle("选择钓场位置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }

    // ... (搜索栏、地图、结果列表、确认栏的子视图实现)
}
```

关键交互逻辑：
- **搜索**：用户输入文字 → `MKLocalSearch` 搜索 → 显示结果列表
- **选择搜索结果**：点击结果 → 地图移动到该位置 → 标注选中点 → 反向地理编码获取地名
- **长按选点**：MapReader + onTapGesture → 获取坐标 → 反向地理编码
- **确认**：将坐标和地名回传给 Binding，dismiss

- [ ] **Step 2: 编译验证**

---

## Task 5: Step1 改造 — 集成地图选点 + 天气自动获取

**Files:**
- Modify: `FishingLog/Features/Trips/NewTrip/Step1BasicInfoView.swift`
- Modify: `FishingLog/Features/Trips/NewTrip/NewTripViewModel.swift`

- [ ] **Step 1: NewTripViewModel 增加坐标和天气相关属性**

```swift
// 地点坐标
@Published var latitude: Double = 0
@Published var longitude: Double = 0
// 天气加载状态
@Published var isLoadingWeather = false
```

- [ ] **Step 2: 修改 Step1BasicInfoView — 地点字段改为地图选择器入口**

将原来的 `FLTextField("钓场地点", text: $vm.locationName)` 替换为：
- 一个可点击的行，显示当前选中的地点名称（或"点击选择钓场位置"占位符）
- 点击后弹出 `MapLocationPickerView` 全屏 sheet
- 选择后显示地点名称和小地图预览

```swift
// 地点选择（替换原文本输入）
Button { showMapPicker = true } label: {
    HStack {
        Image(systemName: "mappin.circle.fill")
            .foregroundStyle(Color.accentBlue)
        Text(vm.locationName.isEmpty ? "点击选择钓场位置" : vm.locationName)
            .font(.flBody)
            .foregroundStyle(vm.locationName.isEmpty ? Color.textTertiary : Color.textPrimary)
        Spacer()
        Image(systemName: "chevron.right")
            .foregroundStyle(Color.textTertiary)
    }
    .padding(FLMetrics.cardPadding)
    .background(Color.cardBackground)
    .cornerRadius(FLMetrics.cornerRadius)
}
.fullScreenCover(isPresented: $showMapPicker) {
    MapLocationPickerView(
        locationName: $vm.locationName,
        latitude: $vm.latitude,
        longitude: $vm.longitude
    )
}
```

- [ ] **Step 3: 修改天气区域 — 增加自动获取按钮**

在温度输入框旁边加一个「自动获取」按钮，点击后调用 WeatherService（Task 8 实现）：

```swift
HStack {
    FLTextField("温度 ℃", text: $vm.weatherTemp)
        .keyboardType(.decimalPad)
    Button {
        Task { await vm.fetchWeather() }
    } label: {
        Label(vm.isLoadingWeather ? "获取中..." : "自动获取",
              systemImage: "cloud.sun.fill")
            .font(.flCaption)
            .foregroundStyle(Color.accentBlue)
    }
    .disabled(vm.isLoadingWeather || (vm.latitude == 0 && vm.longitude == 0))
}
```

- [ ] **Step 4: 修改 NewTripViewModel.save() — 传入坐标**

在 `save()` 中调用 `CoreDataManager.shared.createTrip(...)` 时传入 `latitude` 和 `longitude`。

- [ ] **Step 5: 编译验证**

---

## Task 6: TripDetailView — 内嵌小地图

**Files:**
- Modify: `FishingLog/Features/Trips/Detail/TripDetailView.swift`

- [ ] **Step 1: 在详情页顶部信息卡后添加地图区域**

当 trip 有有效坐标（latitude != 0 && longitude != 0）时，显示一个小地图：

```swift
// 地点地图（有坐标时显示）
if vm.trip.latitude != 0 && vm.trip.longitude != 0 {
    let coord = CLLocationCoordinate2D(
        latitude: vm.trip.latitude,
        longitude: vm.trip.longitude
    )
    Map(position: .constant(.region(MKCoordinateRegion(
        center: coord,
        latitudinalMeters: 2000,
        longitudinalMeters: 2000
    )))) {
        Marker(vm.trip.locationName ?? "钓场", coordinate: coord)
            .tint(.primaryGold)
    }
    .frame(height: 160)
    .cornerRadius(FLMetrics.cornerRadius)
    .disabled(true) // 禁止交互，仅展示
}
```

- [ ] **Step 2: 编译验证**

---

## Task 7: 拍照/录像 — CameraPickerView + Step4 改造

**Files:**
- Create: `FishingLog/Features/Trips/NewTrip/CameraPickerView.swift`
- Modify: `FishingLog/Features/Trips/NewTrip/Step4SummaryView.swift`
- Modify: `FishingLog/Features/Trips/NewTrip/NewTripViewModel.swift`

- [ ] **Step 1: 创建 CameraPickerView — UIImagePickerController 包装**

```swift
import SwiftUI
import AVFoundation

struct CameraPickerView: UIViewControllerRepresentable {
    enum CaptureMode { case photo, video }

    let mode: CaptureMode
    let onCapture: (CameraCaptureResult) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        switch mode {
        case .photo:
            picker.cameraCaptureMode = .photo
        case .video:
            picker.mediaTypes = ["public.movie"]
            picker.cameraCaptureMode = .video
            picker.videoQuality = .typeMedium // 720p 自动压缩
            picker.videoMaximumDuration = 300  // 最长5分钟
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(.photo(image))
            } else if let videoURL = info[.mediaURL] as? URL {
                parent.onCapture(.video(videoURL))
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

enum CameraCaptureResult {
    case photo(UIImage)
    case video(URL)
}
```

- [ ] **Step 2: NewTripViewModel 增加视频数据存储**

```swift
// 媒体项（照片或视频）
struct MediaItem {
    enum MediaType { case photo, video }
    let type: MediaType
    let image: UIImage?      // 照片或视频缩略图
    let data: Data?          // JPEG 数据（照片）
    let videoURL: URL?       // 视频本地路径
    let mimeType: String     // "image/jpeg" 或 "video/mp4"
    let fileName: String
}

@Published var mediaItems: [MediaItem] = []
```

- [ ] **Step 3: 改造 Step4SummaryView — 添加媒体选择菜单**

将原来的单一 `PhotosPicker` 改为一个菜单按钮，提供三个选项：

```swift
@State private var showCamera = false
@State private var showVideoCamera = false
@State private var showActionSheet = false

// 替换原来的 PhotosPicker 为菜单
Menu {
    Button { showCamera = true } label: {
        Label("拍照", systemImage: "camera")
    }
    Button { showVideoCamera = true } label: {
        Label("录像", systemImage: "video")
    }
    // PhotosPicker 保留用于从相册选择
} label: {
    Label("添加照片/视频", systemImage: "plus.circle.fill")
        .font(.flBody)
        .foregroundStyle(Color.accentBlue)
}
```

同时在 `.fullScreenCover` 中添加相机调用：

```swift
.fullScreenCover(isPresented: $showCamera) {
    CameraPickerView(mode: .photo) { result in
        if case .photo(let image) = result {
            let resized = Self.resizedImage(image, maxDimension: 1600)
            // 添加到 mediaItems
        }
    }
}
.fullScreenCover(isPresented: $showVideoCamera) {
    CameraPickerView(mode: .video) { result in
        if case .video(let url) = result {
            // 读取视频数据，生成缩略图，添加到 mediaItems
        }
    }
}
```

- [ ] **Step 4: 更新媒体预览网格 — 支持显示视频缩略图**

在 `LazyVGrid` 中，视频项目上叠加播放按钮图标：

```swift
ForEach(0..<vm.mediaItems.count, id: \.self) { i in
    ZStack {
        if let img = vm.mediaItems[i].image {
            Image(uiImage: img)
                .resizable().scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        if vm.mediaItems[i].type == .video {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}
```

- [ ] **Step 5: 更新 save() 和 MediaUploadManager — 支持视频上传**

在 `NewTripViewModel.save()` 中，遍历 `mediaItems`，按类型上传：

```swift
for item in mediaItems {
    if let data = item.data {
        await MediaUploadManager.shared.uploadMedia(
            data, mimeType: item.mimeType, fileName: item.fileName, tripLocalId: localId
        )
    } else if let videoURL = item.videoURL,
              let videoData = try? Data(contentsOf: videoURL) {
        await MediaUploadManager.shared.uploadMedia(
            videoData, mimeType: item.mimeType, fileName: item.fileName, tripLocalId: localId
        )
    }
}
```

`MediaUploadManager.uploadMedia` 需要泛化，接受 mimeType 和 fileName 参数（当前写死了 "image/jpeg"）。

- [ ] **Step 6: 编译验证**

---

## Task 8: 视频播放 — VideoPlayerView + 媒体网格改造

**Files:**
- Create: `FishingLog/Features/Trips/Detail/Components/VideoPlayerView.swift`
- Modify: `FishingLog/Features/Trips/Detail/Components/TripMediaGridView.swift`
- Modify: `FishingLog/Features/Media/FullScreenImageView.swift`

- [ ] **Step 1: 创建 VideoPlayerView — 全屏视频播放器**

```swift
import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let key: String
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else if let error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.textTertiary)
                    Text(error).font(.flCaption).foregroundStyle(Color.textTertiary)
                }
            } else {
                ProgressView().tint(.accentBlue)
            }
            // 关闭按钮
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
            }
        }
        .task { await loadVideo() }
        .onDisappear { player?.pause() }
    }

    private func loadVideo() async {
        let urlString = "\(APIClient.shared.baseURL)/api/v1/media/file/\(key)"
        guard let url = URL(string: urlString) else { error = "无效地址"; return }
        // 创建带认证的 AVURLAsset
        var headers = ["Authorization": "Bearer \(KeychainManager.shared.getToken() ?? "")"]
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        player?.play()
        isLoading = false
    }
}
```

- [ ] **Step 2: TripMediaGridView — 视频项显示播放图标**

修改 `MediaImageView` 组件和网格循环，根据 `MediaEntity.type` 区分：

```swift
ForEach(Array(mediaItems.enumerated()), id: \.offset) { index, item in
    ZStack {
        MediaImageView(key: item.key ?? "")
            .frame(height: 100)
            .clipped()
            .cornerRadius(6)
        // 视频叠加播放图标
        if item.type == "video" {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(radius: 4)
        }
    }
    .onTapGesture {
        if item.type == "video" {
            selectedVideoKey = item.key
        } else {
            selectedIndex = index
        }
    }
}
```

添加视频全屏播放 sheet：

```swift
@State private var selectedVideoKey: String?

.fullScreenCover(item: $selectedVideoKey) { key in
    VideoPlayerView(key: key)
}
```

注意：需要让 `String` 遵循 `Identifiable`（通过扩展 `extension String: @retroactive Identifiable { public var id: String { self } }`），或用一个 wrapper。

- [ ] **Step 3: FullScreenImageView — 过滤掉视频项**

在传入 `keys` 时只传图片的 key，视频走单独的 `VideoPlayerView`。在 `TripMediaGridView` 中构建 `imageKeys` 数组：

```swift
let imageKeys = mediaItems.filter { $0.type != "video" }.compactMap { $0.key }
```

- [ ] **Step 4: 编译验证**

---

## Task 9: WeatherKit — 天气自动获取

**Files:**
- Create: `FishingLog/Core/Weather/WeatherService.swift`
- Modify: `FishingLog/Features/Trips/NewTrip/NewTripViewModel.swift`
- Modify: `project.yml`

- [ ] **Step 1: project.yml 添加 WeatherKit capability**

在 target settings 中添加 entitlements：

```yaml
    entitlements:
      path: FishingLog/FishingLog.entitlements
      properties:
        com.apple.developer.weatherkit: true
```

确保 `FishingLog.entitlements` 文件存在且包含该 key。

- [ ] **Step 2: 创建 WeatherService**

```swift
import Foundation
import WeatherKit
import CoreLocation

@MainActor
final class WeatherService {
    static let shared = WeatherService()
    private let service = WeatherKit.WeatherService.shared

    struct WeatherResult {
        let temperature: Double  // 摄氏度
        let condition: String    // 中文天气描述
        let wind: String         // 风力描述
    }

    // 获取指定位置和日期的天气
    func fetchWeather(latitude: Double, longitude: Double, date: Date) async -> WeatherResult? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let calendar = Calendar.current

        do {
            if calendar.isDateInToday(date) {
                // 当天：获取当前天气
                let weather = try await service.weather(for: location, including: .current)
                return WeatherResult(
                    temperature: weather.temperature.converted(to: .celsius).value,
                    condition: weather.condition.description,
                    wind: formatWind(weather.wind.speed.converted(to: .kilometersPerHour).value)
                )
            } else {
                // 历史/未来：获取日级天气
                let weather = try await service.weather(for: location, including: .daily)
                if let dayWeather = weather.forecast.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                    let avgTemp = (dayWeather.highTemperature.converted(to: .celsius).value
                                 + dayWeather.lowTemperature.converted(to: .celsius).value) / 2
                    return WeatherResult(
                        temperature: avgTemp,
                        condition: dayWeather.condition.description,
                        wind: formatWind(dayWeather.wind.speed.converted(to: .kilometersPerHour).value)
                    )
                }
            }
        } catch {
            print("WeatherKit 获取失败: \(error)")
        }
        return nil
    }

    private func formatWind(_ kmh: Double) -> String {
        switch kmh {
        case 0..<12: return "微风"
        case 12..<39: return "轻风"
        case 39..<62: return "中风"
        case 62..<88: return "大风"
        default: return "强风"
        }
    }
}
```

- [ ] **Step 3: NewTripViewModel 添加 fetchWeather 方法**

```swift
func fetchWeather() async {
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
```

- [ ] **Step 4: 编译验证**

---

## Task 10: 收尾 — 编译、XcodeGen 重新生成、全面验证

**Files:**
- Modify: `project.yml`

- [ ] **Step 1: 确保 project.yml 包含所有新文件路径**

由于 XcodeGen 按目录扫描源文件，新文件会自动包含。只需确认 entitlements 和 capabilities 配置正确。

- [ ] **Step 2: 重新生成 Xcode 项目**

```bash
/tmp/xcodegen-bin/xcodegen/bin/xcodegen generate
```

- [ ] **Step 3: 编译验证**

```bash
xcodebuild build -project FishingLog.xcodeproj -scheme FishingLog \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/fl-build CODE_SIGNING_ALLOWED=NO -quiet
```

- [ ] **Step 4: 在模拟器上手动测试完整流程**

1. 新建出行 → Step1 点击地点 → 地图搜索选点 → 确认
2. 天气自动获取按钮 → 验证温度/天气自动填入
3. Step4 拍照菜单 → 拍照/从相册选择/录像
4. 保存 → 验证上传成功
5. 出行详情页 → 小地图显示 + 照片/视频展示
6. 点击视频 → 全屏播放

---

## 执行顺序依赖

```
Task 1 (后端) ─── 无依赖，最先执行
Task 2 (CoreData) ─── 无依赖
Task 3 (网络模型) ─── 依赖 Task 2
Task 4 (地图选点页) ─── 无依赖
Task 5 (Step1改造) ─── 依赖 Task 2, 3, 4
Task 6 (详情页地图) ─── 依赖 Task 2
Task 7 (拍照录像) ─── 无依赖
Task 8 (视频播放) ─── 依赖 Task 7
Task 9 (WeatherKit) ─── 依赖 Task 5
Task 10 (收尾验证) ─── 依赖全部
```

可并行的组：
- **Group A**: Task 1 + Task 2 + Task 4 + Task 7（互不依赖）
- **Group B**: Task 3 + Task 5 + Task 6 + Task 8（依赖 Group A）
- **Group C**: Task 9 + Task 10（最后）
