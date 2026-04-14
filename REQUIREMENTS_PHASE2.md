# REQUIREMENTS_PHASE2.md · iOS Phase 2 功能清单

> 状态说明：`[ ]` 未完成 / `[x]` 已完成
> 每完成一项立即更新本文件，不得提前宣告完成。
> Phase 1（I01–I65）已全部完成，Phase 2 从 I66 开始。

---

## 模块十一：统计页面（I66–I76）

- [x] I66 · `Core/Network/Models/StatsModel.swift`：定义 StatsOverview（total_trips / total_catches / total_species / total_weight_kg）、SeasonalMonth（month / count）、SeasonalData（year / months）、SpeciesItem（name / count / percentage）、TopCatch（fish_species / weight_kg / trip_date）
- [x] I67 · `Core/Network/Routes/StatsAPI.swift`：fetchOverview() / fetchSeasonal(year:) / fetchSpecies() / fetchTopCatches()，均返回对应 Model
- [x] I68 · `Features/Stats/StatsViewModel.swift`：@MainActor + ObservableObject，持有 overview / seasonal / species / topCatches，提供 fetchAll()，加载状态 isLoading / error
- [x] I69 · `Features/Stats/StatsView.swift`：ScrollView 主布局，AppBackground 背景，顶部标题"统计"，分区展示四个数据块，底部留安全区域
- [x] I70 · `Features/Stats/Components/OverviewCardsView.swift`：2×2 FLCard 网格，展示总出行/总渔获/鱼种数/总重量（单位 kg），数值 PrimaryGold 粗体，副标题 TextSecondary
- [x] I71 · `Features/Stats/Components/SeasonalChartView.swift`：Swift Charts（import Charts）月度出行折线图，X 轴为 1–12 月份缩写，Y 轴为次数，线条 AccentBlue，区域填充半透明，顶部标题"月度出行趋势"+ 年份 Picker（当年/去年）
- [x] I72 · `Features/Stats/Components/SpeciesChartView.swift`：Swift Charts SectorMark 饼图（鱼种分布），前5种显示图例（名称+百分比），超出合并为"其他"，无数据时显示占位文字
- [x] I73 · `Features/Stats/Components/TopCatchListView.swift`：最大渔获列表，最多展示 5 条（鱼种 / 重量 kg / 日期），PrimaryGold 重量数字，CardBackground 卡片
- [x] I74 · `MainTabView.swift` 统计 Tab 从占位页替换为 StatsView，Tab 图标 chart.bar.fill
- [x] I75 · StatsView 加载中显示 ProgressView，加载失败显示错误卡片（DestructiveRed 图标 + 错误信息 + "重试"按钮）
- [x] I76 · `xcodebuild` 编译通过，verify.sh 无新增 error

---

## 模块十二：装备管理完整（I77–I90）

- [x] I77 · `Core/Network/Models/EquipmentModel.swift` 扩展：EquipmentItem 添加字段（status / purchase_price / purchase_date / notes / style_tags / category_id），新增 CreateEquipmentRequest / UpdateEquipmentRequest Codable 结构体
- [x] I78 · `Core/Network/Routes/EquipmentAPI.swift` 扩展：新增 createEquipment(_ req:) / updateEquipment(id: _ req:) / deleteEquipment(id:)
- [x] I79 · `FishingLog.xcdatamodeld` EquipmentEntity 添加字段：status（String，默认 "active"）/ purchasePrice（Double，可空）/ purchaseDate（Date，可空）/ notes（String，可空）/ styleTags（Transformable，存 [String]）
- [x] I80 · `Core/CoreData/CoreDataManager.swift` 扩展：新增 insertEquipment() / updateEquipment(id:) / deleteEquipmentById(id:) 方法
- [x] I81 · `Features/Equipment/GearListViewModel.swift`：@MainActor + ObservableObject，加载装备列表（含分类筛选），持有 equipments / categories / selectedCategory / isLoading，提供 refresh() / deleteEquipment(id:)
- [x] I82 · `Features/Equipment/GearListView.swift`：顶部分类 Tab 滚动条（全部 + 各分类名称），下方卡片列表，AppBackground 背景，右上角"+"新建按钮，支持下拉刷新
- [x] I83 · `Features/Equipment/Components/GearCardView.swift`：CardBackground 卡片，显示名称（TextPrimary）/ 品牌+型号（TextSecondary）/ 分类标签（AccentBlue 胶囊）/ 状态徽章（active=绿 / inactive=灰 / maintenance=橙）
- [x] I84 · `Features/Equipment/NewEquipmentView.swift`：sheet 表单，字段：名称（必填 FLTextField）/ 品牌 / 型号 / 分类（Picker，从 API 加载）/ 状态（Picker: active/inactive/maintenance）/ 购买日期（DatePicker）/ 购买价格（数字输入）/ 备注（多行 TextEditor）；保存调 API → upsert CoreData → dismiss
- [x] I85 · `Features/Equipment/EditEquipmentView.swift`：复用 NewEquipmentView 表单，预填已有数据，保存调 PUT API → 更新 CoreData → dismiss
- [x] I86 · GearCardView 添加 swipe action：左滑显示编辑（AccentBlue）和删除（DestructiveRed）；删除弹 Alert 确认，确认后调 API → 删 CoreData → 从列表移除
- [x] I87 · 装备列表空状态：SF Symbol "wrench.and.screwdriver" + "暂无装备，点击右上角添加" + 说明文字
- [x] I88 · `MainTabView.swift` 装备 Tab 从占位页替换为 GearListView，Tab 图标 wrench.and.screwdriver.fill
- [x] I89 · `xcodebuild` 编译通过，verify.sh 无新增 error
- [x] I90 · 编辑装备进入 TripDetailView 的装备区点击装备名可进入详情（只读展示，非必需编辑入口）

---

## 模块十三：媒体上传（I91–I103）

- [x] I91 · `Core/Network/Models/MediaModel.swift`：MediaItem（id / key / url / type / size / createdAt）、UploadResult（key / url / type / size）Codable 结构体
- [x] I92 · `Core/Network/Routes/MediaAPI.swift`：uploadMedia(data: Data, mimeType: String) / getPresignedUrl(key: String) / deleteMedia(key: String)；uploadMedia 使用 Alamofire multipart upload
- [x] I93 · `FishingLog.xcdatamodeld` 新增 `MediaEntity`（id / localId / tripId / key / url / type / syncStatus / createdAt），关联 TripEntity（一对多）
- [x] I94 · `Core/CoreData/CoreDataManager.swift` 扩展：upsertMedia() / fetchMedia(for tripId:) / deleteMediaById(id:)
- [x] I95 · `Core/Media/MediaUploadManager.swift`：单例，接收 (tripLocalId, imageData, mimeType)，调 uploadMedia API，成功后 upsertMedia（syncStatus="synced"），失败后 syncStatus="failed"；发布 uploadProgress: Double
- [x] I96 · `Features/Trips/NewTrip/Step4SummaryView.swift` 添加"添加照片"区域：PhotosPicker（多选，最多 9 张），选后显示缩略图网格，"完成保存"同步触发 MediaUploadManager 上传
- [x] I97 · `Features/Trips/Detail/Components/TripMediaGridView.swift`：从 CoreData 加载该出行媒体，LazyVGrid 3列展示（AsyncImage），右上角显示数量，为空则不展示 Section
- [x] I98 · `Features/Media/FullScreenImageView.swift`：全屏查看图片，TabView 横滑切换，双指捏合缩放（MagnificationGesture），顶部安全区关闭按钮（X），深黑背景
- [x] I99 · TripDetailView 在渔获区下方添加"出行相册"Section，嵌入 TripMediaGridView，点击缩略图进入 FullScreenImageView
- [x] I100 · 上传进度：MediaUploadManager 上传中在 Step4 显示 ProgressView（overlay 半透明遮罩 + "上传中..."），完成后自动 dismiss
- [x] I101 · project.yml 添加 NSPhotoLibraryUsageDescription / NSCameraUsageDescription（Phase 1 已写入 Info.plist，确认 project.yml 也包含）
- [x] I102 · `xcodebuild` 编译通过，verify.sh 无新增 error
- [x] I103 · SyncManager 扩展：网络恢复时检查 syncStatus="failed" 的 MediaEntity，重新触发上传

---

## 模块十四：钓点地图（I104–I116）

- [x] I104 · `Core/Network/Models/SpotModel.swift`：Spot（id / name / description / latitude / longitude / spot_type / is_public / photo_url / created_at）、CreateSpotRequest、UpdateSpotRequest Codable 结构体；SpotType 枚举（river / lake / reservoir / sea / other）
- [x] I105 · `Core/Network/Routes/SpotAPI.swift`：fetchSpots(page:) / fetchNearbySpots(lat: lng: radius:) / createSpot(_ req:) / updateSpot(id: _ req:) / deleteSpot(id:)
- [x] I106 · `FishingLog.xcdatamodeld` 新增 `SpotEntity`（id / name / latitude / longitude / spotType / isPublic / photoUrl / createdAt）
- [x] I107 · `Core/CoreData/CoreDataManager.swift` 扩展：upsertSpots([]) / fetchSpots() / fetchSpot(id:) / deleteSpotById(id:)
- [x] I108 · `Features/Spots/SpotsViewModel.swift`：@MainActor + ObservableObject，CLLocationManager 获取用户位置，加载附近钓点列表，提供 addSpot() / deleteSpot() / refresh()
- [x] I109 · `Features/Spots/SpotsView.swift`：NavigationStack，顶部标题"钓点"+ 右上角"+"按钮，地图/列表两个 Picker 模式切换（Segmented Control）
- [x] I110 · `Features/Spots/SpotMapView.swift`：MapKit Map（.hybrid 卫星地图模式），显示用户位置，为每个 Spot 添加 Annotation；MapUserLocationButton；初始定位到用户所在位置
- [x] I111 · `Features/Spots/Components/SpotAnnotationView.swift`：自定义 Annotation：AccentBlue 圆形图钉 + 钓点类型图标（river/lake/reservoir/sea/other 不同 SF Symbol），选中后弹出 callout（名称/类型/距离 km）
- [x] I112 · `Features/Spots/SpotListView.swift`：钓点列表（CardBackground 卡片：名称/类型标签/距离）；支持下拉刷新；空状态占位页
- [x] I113 · `Features/Spots/Components/SpotCardView.swift`：卡片展示钓点信息（名称/类型 AccentBlue 胶囊/距离 TextSecondary/公开/私密标识）；左滑删除（Alert 确认）
- [x] I114 · `Features/Spots/NewSpotView.swift`：sheet 表单：名称（必填）/ 类型（Picker）/ 描述 / 公开开关；地图选点组件（MapView 小地图，长按 pin 选点，自动填充坐标）；保存调 POST /api/v1/spots → upsert CoreData → dismiss
- [x] I115 · `MainTabView.swift` 钓点 Tab 从占位页替换为 SpotsView，Tab 图标 map.fill
- [x] I116 · `xcodebuild` 编译通过，verify.sh 无新增 error

---

## 模块十五：个人中心（I117–I123）

- [x] I117 · `Features/Profile/ProfileViewModel.swift`：读取 Keychain token（用于展示已登录状态），提供 logout() 调用 AuthManager.logout()；持有用户名（从 UserDefaults 存储首次登录时写入的 username）
- [x] I118 · `Features/Profile/ProfileView.swift`：顶部头像区（SF Symbol person.circle.fill，AccentBlue 大图标）+ 用户名，中部统计小卡片行（总出行/总渔获，从 StatsViewModel 读取），下方设置列表（NavigationLink）
- [x] I119 · 退出登录：ProfileView 底部红色"退出登录"按钮，点击弹 Alert 确认，确认后 AuthManager.logout() → 清空 CoreData 缓存（可选）→ 返回 LoginView
- [x] I120 · `Features/Profile/SettingsView.swift`：设置列表（API 地址 / 关于 / 版本号），API 地址支持在 TextField 中修改并写入 Config.plist 对应的 UserDefaults 覆盖（运行时生效）
- [x] I121 · `Features/Profile/AboutView.swift`：App 图标（SF Symbol）+ 版本号（Bundle Short Version）+ 简介文字 + 技术栈列表
- [x] I122 · `MainTabView.swift` "我的" Tab 从占位页替换为 ProfileView，Tab 图标 person.fill
- [x] I123 · `xcodebuild` 编译通过，verify.sh 无新增 error

---

## 模块十六：验证与收尾（I124–I125）

- [x] I124 · `scripts/verify.sh` 补充 Phase 2 关键文件检查：StatsView / GearListView / SpotsView / ProfileView / MediaUploadManager / SpotEntity 等
- [x] I125 · `xcodebuild` + `bash scripts/verify.sh` 全部通过，所有 60 项更新为 [x]，底部进度更新为 **60 / 60**

---

## 完成进度

**60 / 60 项已完成**

> 提示：每完成一项请同步更新上方数字。Phase 2 完成后，合并 REQUIREMENTS.md（Phase 1）+ REQUIREMENTS_PHASE2.md 为统一文档可选。
