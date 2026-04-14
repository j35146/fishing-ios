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
| 定位 | CoreLocation | 系统内置 |
| 本地存储 | Core Data | 系统自带 |
| 网络 | Alamofire | 5.9.x |
| 状态管理 | Combine + ObservableObject | 系统自带 |
| 网络监测 | Network.framework (NWPathMonitor) | 系统自带 |
| 项目构建 | XcodeGen | 2.x（brew 安装） |

---

## 目录结构

```
fishing-ios/
  ├── CLAUDE.md
  ├── REQUIREMENTS.md              ← Phase 1（I01–I65，已全部完成）
  ├── REQUIREMENTS_PHASE2.md       ← Phase 2（I66–I125，当前目标）
  ├── project.yml                  ← XcodeGen 配置
  ├── FishingLog/
  │   ├── App/
  │   │   ├── FishingLogApp.swift  ← @main 入口
  │   │   └── ContentView.swift    ← 根视图（LoginView 或 MainTabView）
  │   ├── Core/
  │   │   ├── Auth/                ← KeychainManager, AuthManager
  │   │   ├── Network/
  │   │   │   ├── APIClient.swift
  │   │   │   ├── APIError.swift
  │   │   │   ├── Models/          ← TripModel, CatchModel, EquipmentModel,
  │   │   │   │                       StatsModel, MediaModel, SpotModel
  │   │   │   └── Routes/          ← TripsAPI, CatchesAPI, EquipmentAPI,
  │   │   │                           StatsAPI, MediaAPI, SpotAPI
  │   │   ├── CoreData/            ← DataModel(.xcdatamodeld), CoreDataManager
  │   │   ├── Sync/                ← SyncManager
  │   │   └── Media/               ← MediaUploadManager（Phase 2）
  │   ├── Features/
  │   │   ├── Auth/                ← LoginView
  │   │   ├── Trips/
  │   │   │   ├── List/            ← TripsListView, TripCardView, ViewModel
  │   │   │   ├── Detail/          ← TripDetailView, ViewModel, TripMediaGridView
  │   │   │   └── NewTrip/         ← 4步新建表单（Step4含照片上传）
  │   │   ├── Equipment/           ← GearListView, NewEquipmentView, EditEquipmentView
  │   │   ├── Stats/               ← StatsView, ViewModel, Components/（Phase 2）
  │   │   ├── Media/               ← FullScreenImageView, PhotoPickerView（Phase 2）
  │   │   ├── Spots/               ← SpotsView, SpotMapView, SpotListView（Phase 2）
  │   │   └── Profile/             ← ProfileView, SettingsView, AboutView（Phase 2）
  │   ├── DesignSystem/
  │   │   ├── Colors.swift
  │   │   ├── Typography.swift
  │   │   └── Components/          ← FLCard, FLButton, FLTextField, SyncBadge
  │   └── Resources/
  │       ├── Info.plist
  │       ├── Config.plist          ← API_BASE_URL
  │       └── FishingLog.xcdatamodeld/
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

> 设计稿参考：`/Users/thomas/Desktop/Drive/AI/fishing/stitch/`
> 各文件夹含 `screen.png`（效果图）和 `code.html`（HTML 参考）

---

## 后端 API 参考

后端已完成（Phase 1+2 全部通过），主要接口：

| 接口 | 说明 |
|------|------|
| `POST /api/v1/auth/login` | 登录，返回 `{ data: { token, username } }` |
| `GET /api/v1/trips` | 出行列表（分页 + 筛选） |
| `POST /api/v1/trips/sync` | 批量离线同步（核心） |
| `GET /api/v1/trips/:id` | 出行详情 |
| `DELETE /api/v1/trips/:id` | 删除出行 |
| `GET /api/v1/equipment` | 装备列表（支持 styleTag/status/categoryId 筛选） |
| `POST /api/v1/equipment` | 新建装备 |
| `PUT /api/v1/equipment/:id` | 更新装备 |
| `DELETE /api/v1/equipment/:id` | 删除装备（已被引用返回 400） |
| `GET /api/v1/equipment/categories` | 装备分类 |
| `POST /api/v1/media/upload` | 上传媒体（multipart，字段名 file） |
| `GET /api/v1/media/presign/:key` | 获取预签名 URL |
| `DELETE /api/v1/media/:key` | 删除媒体文件 |
| `GET /api/v1/stats/overview` | 总览统计 |
| `GET /api/v1/stats/seasonal?year=` | 月度出行趋势（12 个月） |
| `GET /api/v1/stats/species` | 鱼种分布 |
| `GET /api/v1/stats/top-catches` | 最大渔获 Top 10 |
| `GET /api/v1/spots` | 钓点列表（分页 + 筛选） |
| `GET /api/v1/spots/nearby?lat=&lng=&radius=` | 附近钓点 |
| `POST /api/v1/spots` | 新建钓点 |
| `PUT /api/v1/spots/:id` | 更新钓点（仅本人） |
| `DELETE /api/v1/spots/:id` | 删除钓点（仅本人） |

**认证方式：** `Authorization: Bearer {token}`（每次请求自动注入）

---

## 代码规范

- 所有注释使用**中文**
- ViewModel 命名：`XxxViewModel`，加 `@MainActor` + 继承 `ObservableObject`
- View 层只负责展示，所有业务逻辑放 ViewModel
- Core Data 操作只通过 `CoreDataManager` 进行，禁止在 View/ViewModel 直接操作 `NSManagedObjectContext`
- 错误统一用 `AppError` 枚举，通过 `.alert` 在 View 层展示
- Keychain 存储 JWT token，禁止用 UserDefaults 存 token
- 所有 API 请求必须在后台线程发出，结果回到 `@MainActor` 更新 UI

---

## 常用命令

```bash
# 安装 XcodeGen（如未安装）
brew install xcodegen

# 生成 Xcode 项目（在 fishing-ios/ 目录下运行）
xcodegen generate

# 编译验证（无需签名）
xcodebuild build \
  -project FishingLog/FishingLog.xcodeproj \
  -scheme FishingLog \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/fl-build \
  CODE_SIGNING_ALLOWED=NO \
  -quiet 2>&1 | tail -30

# 运行验证脚本
bash scripts/verify.sh
```

---

## 工作流程（必须遵守）

1. **完成即标记**：每完成 `REQUIREMENTS.md` 中的一项，立即将 `[ ]` 改为 `[x]`，并更新底部进度数字
2. **模块自验证**：每完成一个完整模块，运行 `bash scripts/verify.sh`
3. **失败必修复**：有失败必须当场修复，不得跳过进入下一模块
4. **禁止提前宣告完成**：必须 verify.sh 全部通过后才能声明 Phase 1 完成

---

## 当前阶段

**iOS Phase 2** — 功能扩展（进行中）

| 阶段 | 范围 | 状态 |
|------|------|------|
| Phase 1（I01–I65） | 登录、出行 CRUD、渔获、装备选择、Core Data、自动同步 | ✅ 已完成 |
| Phase 2（I66–I125） | 统计图表、装备管理完整、媒体上传、钓点地图、个人中心 | ✅ 已完成 |

**需求文件：**
- Phase 1：`REQUIREMENTS.md`
- Phase 2：`REQUIREMENTS_PHASE2.md`（当前执行目标）

**提示词：**
- Phase 2 执行提示词：`/Users/thomas/Desktop/Drive/AI/fishing/docs/cc-prompt-ios-phase2.md`
