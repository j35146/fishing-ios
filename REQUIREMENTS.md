# REQUIREMENTS.md · iOS Phase 1 功能清单

> 状态说明：`[ ]` 未完成 / `[x]` 已完成
> 每完成一项立即更新本文件，不得提前宣告完成。

---

## 模块一：项目基础（I01–I08）

- [x] I01 · 安装 XcodeGen（`brew install xcodegen`，已安装则跳过）
- [x] I02 · 创建 `project.yml`（Bundle ID: com.jiangfeng.fishinglog，iOS 17+，Alamofire 5.9.x SPM）
- [x] I03 · 创建 `FishingLog/Resources/Info.plist`（基础 key + Privacy 说明）
- [x] I04 · 创建 `FishingLog/Resources/Config.plist`，包含 `API_BASE_URL` 键（默认值 `http://localhost`）
- [x] I05 · `xcodegen generate` 成功生成 `.xcodeproj`，无报错
- [x] I06 · `xcodebuild` 编译通过，零 error（Warning 可忽略）
- [x] I07 · 创建 `scripts/verify.sh`，包含编译检查 + 关键文件存在性检查
- [x] I08 · `FishingLogApp.swift` 入口，全局设置 `.preferredColorScheme(.dark)`

---

## 模块二：设计系统（I09–I14）

- [x] I09 · `DesignSystem/Colors.swift`：定义 Color 扩展（AppBackground / CardBackground / CardElevated / CardSurface / PrimaryGold / AccentBlue / TextPrimary / TextSecondary / TextTertiary / DestructiveRed）
- [x] I10 · `DesignSystem/Typography.swift`：定义 Font 扩展（flTitle / flHeadline / flBody / flCaption）
- [x] I11 · `DesignSystem/Components/FLCard.swift`：通用卡片容器（CardBackground 背景 + 圆角 12 + padding 16）
- [x] I12 · `DesignSystem/Components/FLButton.swift`：主按钮（PrimaryGold）和次按钮（CardBackground）两种样式
- [x] I13 · `DesignSystem/Components/FLTextField.swift`：深色输入框（CardBackground 背景 + TextSecondary 占位符）
- [x] I14 · `DesignSystem/Components/SyncBadge.swift`：同步状态角标（✅ synced / ⏳ pending / ❌ failed）

---

## 模块三：认证（I15–I21）

- [x] I15 · `Core/Auth/KeychainManager.swift`：save / get / delete token（使用 Security framework）
- [x] I16 · `Core/Auth/AuthManager.swift`：ObservableObject，`isLoggedIn: Bool`，login() / logout()
- [x] I17 · `Features/Auth/LoginView.swift`：用户名输入框 + 密码输入框（SecureField）+ 登录按钮，深海风格
- [x] I18 · 登录请求调用 `POST /api/v1/auth/login`，成功后 token 写入 Keychain
- [x] I19 · 登录失败时显示 Alert，提示"用户名或密码错误"
- [x] I20 · `ContentView.swift` 根据 `AuthManager.isLoggedIn` 切换显示 LoginView 或 MainTabView
- [x] I21 · `MainTabView.swift`：5 个 Tab（日志 / 统计 / 装备 / 钓点 / 我的），Phase 1 只实现"日志"Tab，其余显示占位页

---

## 模块四：网络层（I22–I28）

- [x] I22 · `Core/Network/APIClient.swift`：Alamofire Session 单例，从 Config.plist 读取 baseURL，自动注入 Bearer token
- [x] I23 · `Core/Network/APIError.swift`：枚举（unauthorized / notFound / serverError / networkError / decodingError）
- [x] I24 · `Core/Network/Models/TripModel.swift`：Trip / FishCatch / FishingStyle 的 Codable 结构体
- [x] I25 · `Core/Network/Models/EquipmentModel.swift`：Equipment / EquipmentCategory 的 Codable 结构体
- [x] I26 · `Core/Network/Routes/TripAPI.swift`：fetchTrips(page:) / syncTrips(items:) / deleteTrip(id:)
- [x] I27 · `Core/Network/Routes/EquipmentAPI.swift`：fetchEquipment() / fetchCategories()
- [x] I28 · 收到 401 时，自动调用 `AuthManager.logout()`，跳转登录页

---

## 模块五：Core Data（I29–I35）

- [x] I29 · `FishingLog.xcdatamodeld` 定义 `TripEntity`（id / localId / title / tripDate / locationName / weatherTemp / weatherWind / weatherCondition / companions / notes / syncStatus / styleIds / updatedAt / createdAt）
- [x] I30 · `FishingLog.xcdatamodeld` 定义 `CatchEntity`（id / localId / tripId / species / weightG / lengthCm / count / isReleased / styleCode / notes），关联 TripEntity（一对多）
- [x] I31 · `FishingLog.xcdatamodeld` 定义 `EquipmentEntity`（id / name / brand / model / categoryName），用于本地缓存装备列表
- [x] I32 · `FishingLog.xcdatamodeld` 定义 `StyleEntity`（id / name / code）
- [x] I33 · `Core/CoreData/CoreDataManager.swift`：NSPersistentContainer 单例，提供 viewContext
- [x] I34 · CoreDataManager 提供：saveContext() / fetchTrips() / upsertTrip() / deleteTrip() / fetchCatches(for:) / upsertCatch() / deleteCatch()
- [x] I35 · CoreDataManager 提供：upsertEquipments([]) / fetchEquipments() / fetchPendingTrips()

---

## 模块六：出行列表（I36–I42）

- [x] I36 · `Features/Trips/List/TripsListViewModel.swift`：从 CoreData 加载列表；提供 refresh()（调 API → 存 CoreData）
- [x] I37 · `Features/Trips/List/TripsListView.swift`：NavigationStack + ScrollView，AppBackground 背景，顶部标题"钓鱼志"+ 右上角"+"按钮
- [x] I38 · `Features/Trips/List/TripCardView.swift`：CardBackground 卡片，显示日期 / 地点 / 钓法标签（AccentBlue 胶囊）/ 渔获数量 / 右下角 SyncBadge
- [x] I39 · 列表为空时显示占位页（SF Symbol 图标 + "还没有出行记录" + "立即新建"按钮）
- [x] I40 · 支持下拉刷新（`.refreshable`），调用 `viewModel.refresh()`
- [x] I41 · 点击卡片导航到 `TripDetailView`
- [x] I42 · 右上角"+"按钮 sheet 弹出 `NewTripView`

---

## 模块七：新建出行（I43–I51）

- [x] I43 · `Features/Trips/NewTrip/NewTripViewModel.swift`：管理 4 步表单状态，持有 basicInfo / catches / selectedEquipmentIds / currentStep
- [x] I44 · `Features/Trips/NewTrip/NewTripView.swift`：顶部进度条（4步）+ 步骤容器 + 下一步/完成按钮
- [x] I45 · `Step1BasicInfoView.swift`：出行日期（DatePicker，必填）+ 钓法多选（台钓/路亚 Toggle，必填）+ 地点/标题/天气温度/天气状况/同行人（可选）
- [x] I46 · `Step2CatchesView.swift`：显示已添加渔获列表 + "添加渔获"按钮，点击弹出 AddCatchSheet
- [x] I47 · `AddCatchSheet.swift`：鱼种（TextField）+ 钓法归属（Picker）+ 重量克（数字输入）+ 体长（数字输入）+ 数量（Stepper）+ 是否放流（Toggle）
- [x] I48 · `Step3EquipmentView.swift`：从 API 或本地缓存加载装备列表，分类展示，支持多选（勾选标记）
- [x] I49 · `Step4SummaryView.swift`：汇总展示（日期/地点/钓法/渔获数量/装备数量），"完成保存"按钮
- [x] I50 · 点击"完成保存"：写入 CoreData（syncStatus = "pending"），dismiss sheet，触发 SyncManager
- [x] I51 · Step1 缺少必填项时，"下一步"按钮置灰，无法前进

---

## 模块八：行程详情（I52–I58）

- [x] I52 · `Features/Trips/Detail/TripDetailViewModel.swift`：从 CoreData 读取 trip + catches + equipment
- [x] I53 · `Features/Trips/Detail/TripDetailView.swift`：NavigationStack，ScrollView 布局，AppBackground 背景
- [x] I54 · 顶部信息卡：日期 / 地点 / 天气（温度+状况）/ 钓法标签（AccentBlue 胶囊）
- [x] I55 · 渔获列表区：Section 标题"渔获记录" + CatchRowView（鱼种 / 重量 / 数量 / 放流徽章）
- [x] I56 · 装备列表区：Section 标题"所用装备" + 装备名称列表
- [x] I57 · 同行人区：Section 标题"同行钓友" + 文字展示
- [x] I58 · 右上角菜单：编辑（导航到编辑表单，复用 NewTripView 预填数据）/ 删除（Alert 确认 → API 删除 → CoreData 删除 → 返回列表）

---

## 模块九：同步机制（I59–I64）

- [x] I59 · `Core/Sync/SyncManager.swift`：单例，NWPathMonitor 监测网络状态变化
- [x] I60 · 网络从断开→恢复时，自动触发 `syncPendingTrips()`
- [x] I61 · `syncPendingTrips()`：读取所有 syncStatus = "pending" 的 TripEntity，调用 `POST /api/v1/trips/sync`
- [x] I62 · 同步成功后，将对应 TripEntity 的 syncStatus 更新为 "synced"，serverId 写入 id 字段
- [x] I63 · 同步失败后，syncStatus 更新为 "failed"，不影响下次重试
- [x] I64 · `FishingLogApp.swift` 监听 `scenePhase == .active`，每次进入前台触发一次同步检查

---

## 模块十：验证脚本（I65）

- [x] I65 · `scripts/verify.sh` 完整验证：① xcodegen generate 无错 ② xcodebuild 编译无 error ③ 关键 Swift 文件存在 ④ xcdatamodeld 包含四个 Entity

---

## 完成进度

**65 / 65 项已完成**

> 提示：每完成一项请同步更新上方数字。
