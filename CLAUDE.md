# 钓鱼志 iOS · CLAUDE.md

> Claude Code 每次会话开始前必须完整读取本文件，再开始编码。

---

## 项目概述

个人钓鱼记录 App 的 iOS 原生客户端。单用户，支持完全离线使用，联网后自动同步至后端。

---

## 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| UI | SwiftUI | iOS 17+ |
| 图表 | Swift Charts | iOS 16+（系统内置） |
| 地图 | MapKit | iOS 17+（系统内置） |
| 照片 | PhotosUI | iOS 16+（系统内置） |
| 相机 | UIImagePickerController | 系统内置 |
| 视频播放 | AVKit / AVFoundation | 系统内置 |
| 天气 | WeatherKit | iOS 16+（需开发者账号启用） |
| 定位 | CoreLocation | 系统内置 |
| 本地存储 | Core Data | 系统自带 |
| 网络 | Alamofire | 5.9.x |
| 状态管理 | Combine + ObservableObject | 系统自带 |
| 网络监测 | Network.framework (NWPathMonitor) | 系统自带 |
| 项目构建 | XcodeGen | 2.x |

---

## 目录结构

```
fishing-ios/
  ├── CLAUDE.md                        ← 本文件（项目开发文档）
  ├── REQUIREMENTS.md                  ← Phase 1 需求（I01–I65，已完成）
  ├── REQUIREMENTS_PHASE2.md           ← Phase 2 需求（I66–I125，已完成）
  ├── project.yml                      ← XcodeGen 配置
  ├── docs/superpowers/plans/          ← 实现计划文档
  ├── FishingLog/
  │   ├── App/
  │   │   ├── FishingLogApp.swift      ← @main 入口
  │   │   ├── ContentView.swift        ← 根视图（LoginView 或 MainTabView）
  │   │   └── MainTabView.swift        ← 底部 Tab 导航
  │   ├── Core/
  │   │   ├── Auth/
  │   │   │   ├── AuthManager.swift    ← 登录状态管理
  │   │   │   └── KeychainManager.swift ← Token 持久化（Keychain + UserDefaults 兜底）
  │   │   ├── Network/
  │   │   │   ├── APIClient.swift      ← Alamofire 封装，Token 自动注入
  │   │   │   ├── APIError.swift       ← AppError 枚举
  │   │   │   ├── Models/
  │   │   │   │   ├── TripModel.swift      ← Trip 结构体（含 latitude/longitude）
  │   │   │   │   ├── MediaModel.swift     ← MediaItem, UploadResult, MediaSaveRequest
  │   │   │   │   ├── EquipmentModel.swift
  │   │   │   │   ├── StatsModel.swift
  │   │   │   │   └── SpotModel.swift
  │   │   │   └── Routes/
  │   │   │       ├── TripAPI.swift        ← fetchTrips, syncTrips, deleteTrip
  │   │   │       ├── MediaAPI.swift       ← uploadMedia, getPresignedUrl, deleteMedia
  │   │   │       ├── EquipmentAPI.swift
  │   │   │       ├── StatsAPI.swift
  │   │   │       └── SpotAPI.swift
  │   │   ├── CoreData/
  │   │   │   └── CoreDataManager.swift    ← CRUD（Trip/Catch/Equipment/Media/Spot）
  │   │   ├── Sync/
  │   │   │   └── SyncManager.swift        ← 离线同步 + 网络恢复重试
  │   │   ├── Media/
  │   │   │   └── MediaUploadManager.swift ← 图片/视频上传（支持重试）
  │   │   └── Weather/
  │   │       └── WeatherService.swift     ← WeatherKit 封装（当日/历史天气）
  │   ├── Features/
  │   │   ├── Auth/
  │   │   │   └── LoginView.swift
  │   │   ├── Trips/
  │   │   │   ├── List/
  │   │   │   │   ├── TripsListView.swift
  │   │   │   │   ├── TripsListViewModel.swift
  │   │   │   │   └── TripCardView.swift
  │   │   │   ├── Detail/
  │   │   │   │   ├── TripDetailView.swift         ← 含内嵌小地图
  │   │   │   │   ├── TripDetailViewModel.swift
  │   │   │   │   └── Components/
  │   │   │   │       ├── TripMediaGridView.swift   ← 图片+视频网格
  │   │   │   │       └── VideoPlayerView.swift     ← 全屏视频播放器（presign URL）
  │   │   │   └── NewTrip/
  │   │   │       ├── NewTripView.swift             ← 4步表单容器
  │   │   │       ├── NewTripViewModel.swift        ← 含坐标/天气/媒体数据
  │   │   │       ├── Step1BasicInfoView.swift      ← 日期/钓法/地图选点/天气自动获取
  │   │   │       ├── Step2CatchesView.swift        ← 渔获录入
  │   │   │       ├── Step3EquipmentView.swift      ← 装备选择
  │   │   │       ├── Step4SummaryView.swift        ← 总结+拍照/录像/相册选择
  │   │   │       ├── MapLocationPickerView.swift   ← 全屏地图搜索+选点
  │   │   │       └── CameraPickerView.swift        ← UIImagePickerController 包装
  │   │   ├── Equipment/
  │   │   │   ├── GearListView.swift
  │   │   │   ├── GearListViewModel.swift
  │   │   │   ├── NewEquipmentView.swift
  │   │   │   ├── EditEquipmentView.swift
  │   │   │   └── Components/GearCardView.swift
  │   │   ├── Stats/
  │   │   │   ├── StatsView.swift
  │   │   │   ├── StatsViewModel.swift
  │   │   │   └── Components/
  │   │   │       ├── OverviewCardsView.swift
  │   │   │       ├── SeasonalChartView.swift
  │   │   │       ├── SpeciesChartView.swift
  │   │   │       └── TopCatchListView.swift
  │   │   ├── Media/
  │   │   │   └── FullScreenImageView.swift         ← 全屏图片浏览（含分享）
  │   │   ├── Spots/
  │   │   │   ├── SpotsView.swift
  │   │   │   ├── SpotsViewModel.swift
  │   │   │   ├── SpotMapView.swift
  │   │   │   ├── SpotListView.swift
  │   │   │   ├── NewSpotView.swift
  │   │   │   └── Components/
  │   │   │       ├── SpotAnnotationView.swift
  │   │   │       └── SpotCardView.swift
  │   │   └── Profile/
  │   │       ├── ProfileView.swift
  │   │       ├── ProfileViewModel.swift
  │   │       ├── SettingsView.swift
  │   │       └── AboutView.swift
  │   ├── DesignSystem/
  │   │   ├── Colors.swift
  │   │   ├── Typography.swift
  │   │   └── Components/
  │   │       ├── FLCard.swift
  │   │       ├── FLButton.swift
  │   │       ├── FLTextField.swift
  │   │       └── SyncBadge.swift
  │   ├── FishingLog.entitlements              ← WeatherKit capability
  │   └── Resources/
  │       ├── Info.plist
  │       ├── Config.plist                     ← API_BASE_URL
  │       ├── Assets.xcassets/                 ← AppIcon
  │       └── FishingLog.xcdatamodeld/         ← CoreData 模型
  └── scripts/
      └── verify.sh
```

---

## 设计规范（严格遵守）

| 颜色 Token | Hex | 用途 |
|-----------|-----|------|
| AppBackground | #071325 | 所有页面主背景（深海蓝黑） |
| CardBackground | #0D2137 | 卡片、Sheet、输入框背景 |
| CardElevated | #1F2A3D | 卡片次级 / 选中态 / 浮层 |
| CardSurface | #2A3548 | 最高层面板、底栏、弹窗 |
| PrimaryGold | #E6C364 | 主按钮、CTA、重要数字、标题强调 |
| AccentBlue | #75D1FF | 辅色、次要指标、图标、链接 |
| TextPrimary | #FFFFFF | 主文字 |
| TextSecondary | #D7E3FC | 次要文字、描述 |
| TextTertiary | #B5C8E5 | 三级文字、占位符 |
| DestructiveRed | #EF4444 | 删除、警告 |

| 尺寸 Token | 值 |
|------------|---|
| CornerRadius | 12 |
| HorizontalPadding | 16 |
| CardPadding | 16 |

**强制全局深色：** `FishingLogApp.swift` 最外层加 `.preferredColorScheme(.dark)`

---

## 后端 API 参考

**生产环境：** `http://home.weixia.org:35146`

**认证方式：** `Authorization: Bearer {token}`（JWT 有效期 10 年，每次请求自动注入）

| 接口 | 说明 |
|------|------|
| `POST /api/v1/auth/login` | 登录，返回 `{ data: { token, username } }` |
| `GET /api/v1/trips` | 出行列表（分页，返回 latitude/longitude） |
| `POST /api/v1/trips/sync` | 批量离线同步（含 latitude/longitude） |
| `GET /api/v1/trips/:id` | 出行详情 |
| `DELETE /api/v1/trips/:id` | 删除出行 |
| `GET /api/v1/equipment` | 装备列表 |
| `POST /api/v1/equipment` | 新建装备 |
| `PUT /api/v1/equipment/:id` | 更新装备 |
| `DELETE /api/v1/equipment/:id` | 删除装备 |
| `GET /api/v1/equipment/categories` | 装备分类 |
| `POST /api/v1/media/upload` | 上传媒体（multipart，支持图片/视频） |
| `GET /api/v1/media/presign/:key` | 获取预签名 URL（用于视频播放） |
| `GET /api/v1/media/file/:key` | 文件流代理（用于图片加载，带 Token 认证） |
| `DELETE /api/v1/media/:key` | 删除媒体文件 |
| `GET /api/v1/stats/overview` | 总览统计 |
| `GET /api/v1/stats/seasonal?year=` | 月度出行趋势 |
| `GET /api/v1/stats/species` | 鱼种分布 |
| `GET /api/v1/stats/top-catches` | 最大渔获 Top 10 |
| `GET /api/v1/spots` | 钓点列表 |
| `GET /api/v1/spots/nearby?lat=&lng=&radius=` | 附近钓点 |
| `POST /api/v1/spots` | 新建钓点 |
| `PUT /api/v1/spots/:id` | 更新钓点 |
| `DELETE /api/v1/spots/:id` | 删除钓点 |

---

## CoreData 模型

### TripEntity
| 属性 | 类型 | 说明 |
|------|------|------|
| id | String | 服务端 UUID |
| localId | UUID | 客户端本地 ID |
| title | String? | 标题 |
| tripDate | Date | 出行日期 |
| locationName | String? | 地点名称（用户手动填写或自动获取） |
| latitude | Double | 纬度（0 = 未设置） |
| longitude | Double | 经度（0 = 未设置） |
| spotId | String? | 关联钓点 ID |
| styleIds | String? | 钓法 ID（逗号分隔） |
| styleNames | String? | 钓法名称（逗号分隔） |
| weatherTemp | Double | 温度（℃） |
| weatherCondition | String? | 天气状况 |
| companions | Transformable | 同行人数组 |
| notes | String? | 备注 |
| syncStatus | String | pending / synced / failed |
| createdAt | Date | 创建时间 |
| updatedAt | Date | 更新时间 |

### MediaEntity
| 属性 | 类型 | 说明 |
|------|------|------|
| key | String | S3 对象 key |
| url | String | 预签名 URL |
| type | String | "image" 或 "video" |
| tripLocalId | UUID | 关联出行的本地 ID |
| syncStatus | String | pending / synced / failed |
| localImageData | Binary? | 失败时保存原始数据用于重试 |

### 其他实体
- **CatchEntity** — 渔获记录（species, weightG, lengthCm, count, isReleased）
- **EquipmentEntity** — 装备（name, brand, model, categoryName, status）
- **SpotEntity** — 钓点（name, latitude, longitude, spotType）
- **StyleEntity** — 钓法（id, name, code）

---

## 核心功能说明

### 地图选点（Phase 3）
- **入口**：Step1BasicInfoView → 点击"选择地图位置"
- **组件**：MapLocationPickerView（全屏 sheet）
- **功能**：MKLocalSearch 搜索 + 地图点击选点 + 反向地理编码
- **数据流**：选中坐标 → Binding 回传 latitude/longitude → 用户可手动编辑地点名称或点"自动获取"反向地理编码
- **展示**：TripDetailView 有坐标时显示内嵌小地图（160pt 高，不可交互）

### 拍照/录像（Phase 3）
- **入口**：Step4SummaryView → Menu 菜单（拍照/录像/从相册选择）
- **拍照**：CameraPickerView（UIImagePickerController，.photo 模式）→ 缩放至 1600px + JPEG 0.7
- **录像**：CameraPickerView（.video 模式，720p，最长 5 分钟）
- **相册**：PhotosPicker，支持 .images + .videos
- **数据模型**：TripMediaItem（type/thumbnail/data/videoURL/mimeType/fileName）
- **上传**：MediaUploadManager.uploadMedia()，支持任意 mimeType

### 视频播放（Phase 3）
- **入口**：TripMediaGridView → 点击视频项 → 全屏 VideoPlayerView
- **加载方式**：先调 getPresignedUrl(key:) 获取预签名 URL，再用 AVPlayer 直接播放
- **缩略图**：视频在网格中显示深色占位背景 + 播放图标（不下载视频提取帧）

### 天气自动获取（Phase 3）
- **入口**：Step1BasicInfoView → 天气卡片 → "自动获取"按钮
- **前提**：需先选择地图坐标（按钮在无坐标时禁用）
- **服务**：WeatherService（WeatherKit）
  - 当天：获取当前天气（CurrentWeather）
  - 非当天：获取日级预报取平均温度（DayWeather）
- **天气条件自动翻译为中文**（晴/多云/阴/雨/雪等）

### 媒体分享（Phase 3）
- **图片分享**：FullScreenImageView 左上角分享按钮 → 下载原图 → UIActivityViewController
- **视频分享**：VideoPlayerView 左上角分享按钮 → 下载视频到临时文件 → UIActivityViewController
- **支持目标**：AirDrop、保存到相册、微信等所有系统分享目标

### 离线同步
- **写入**：本地 CoreData 优先，syncStatus = "pending"
- **同步**：SyncManager 监听网络变化，联网后自动 POST /trips/sync
- **重试**：网络恢复时自动重试失败的媒体上传
- **冲突处理**：服务端 COALESCE，客户端按 id + localId 双重查找防重复

### Token 持久化
- 双重存储：Keychain（主）+ UserDefaults（兜底）
- 读取优先级：内存缓存 → Keychain → UserDefaults
- JWT 有效期 10 年（服务端配置），无自动登出

---

## 代码规范

- 所有注释使用**中文**
- ViewModel 命名：`XxxViewModel`，加 `@MainActor` + 继承 `ObservableObject`
- View 层只负责展示，所有业务逻辑放 ViewModel
- Core Data 操作只通过 `CoreDataManager` 进行
- 错误统一用 `AppError` 枚举
- Token 存储：Keychain + UserDefaults 双重持久化
- 所有 API 请求必须在后台线程发出，结果回到 `@MainActor` 更新 UI
- 图片上传前缩放至最大 1600px，JPEG 质量 0.7
- 视频录制质量 `.typeMedium`（720p），最长 5 分钟

---

## 常用命令

```bash
# 生成 Xcode 项目（在 fishing-ios/ 目录下运行）
xcodegen generate

# 编译验证
xcodebuild build \
  -project FishingLog.xcodeproj \
  -scheme FishingLog \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/fl-build \
  -quiet 2>&1 | tail -30
```

---

## 生产环境

| 服务 | 地址 |
|------|------|
| API | http://home.weixia.org:35146 |
| SSH | `ssh -p 11122 thomas@home.weixia.org` |
| MinIO | Docker named volume `minio-data`（非 bind mount，避免 macOS VirtioFS 锁问题） |
| 数据库 | PostgreSQL 16 + PostGIS |
| nginx | `client_max_body_size 500M` |

### 服务端关键文件（/opt/fishing-server/）
- `docker-compose.yml` — 容器编排
- `nginx.conf` — 反向代理
- `.env` — 环境变量（JWT_EXPIRES_IN=3650d）
- `src/routes/trips.js` — 出行 CRUD + 同步（含 latitude/longitude）
- `src/routes/media.js` — 媒体上传 + 文件代理（/api/v1/media/file/*）
- `src/routes/spots.js` — 钓点 CRUD
- `src/utils/minio.js` — MinIO S3 客户端

---

## 开发阶段

| 阶段 | 范围 | 状态 |
|------|------|------|
| Phase 1（I01–I65） | 登录、出行 CRUD、渔获、装备选择、Core Data、自动同步 | ✅ 已完成 |
| Phase 2（I66–I125） | 统计图表、装备管理、媒体上传、钓点地图、个人中心 | ✅ 已完成 |
| Phase 3 | 地图选点、拍照/录像、视频播放、WeatherKit 天气、媒体分享 | ✅ 已完成 |

### Phase 3 修复的 Bug
| Bug | 根因 | 修复 |
|-----|------|------|
| 照片上传 500 | macOS Docker VirtioFS bind mount 不支持 MinIO 文件锁 | MinIO 改用 Docker named volume |
| 日期显示"未知日期" | 服务端返回带毫秒的 ISO8601，拼接解析失败 | 四级 fallback 日期解析 |
| 出行记录无法删除 | API 删除失败 throw 跳过本地删除 | `try await` → `try? await` |
| 杀进程后重新登录 | Keychain 在无签名环境不可靠 | 加 UserDefaults 兜底 |
| 视频无法播放 | AVURLAssetHTTPHeaderFieldsKey 非公开 API 不稳定 | 改用 presign URL |
| 视频缩略图不显示 | 视频数据无法 UIImage(data:) 解析 | 视频用占位图标替代 |
