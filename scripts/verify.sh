#!/bin/bash

PASS=0; FAIL=0
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

check() {
    local desc="$1"; shift
    if "$@" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $desc"; PASS=$((PASS + 1))
    else
        echo -e "${RED}✗${NC} $desc"; FAIL=$((FAIL + 1))
    fi
}

cd "$(dirname "$0")/.."
export PATH="$HOME/bin:$PATH"
echo "=== 钓鱼志 iOS Phase 1 + Phase 2 验证 ==="

# 1. XcodeGen 可用
check "XcodeGen 已安装" which xcodegen

# 2. Phase 1 关键文件存在
check "project.yml 存在"           test -f project.yml
check "CLAUDE.md 存在"             test -f CLAUDE.md
check "REQUIREMENTS.md 存在"       test -f REQUIREMENTS.md
check "Config.plist 存在"          test -f FishingLog/Resources/Config.plist
check "Colors.swift 存在"          test -f "FishingLog/DesignSystem/Colors.swift"
check "AuthManager.swift 存在"     test -f "FishingLog/Core/Auth/AuthManager.swift"
check "KeychainManager.swift 存在" test -f "FishingLog/Core/Auth/KeychainManager.swift"
check "APIClient.swift 存在"       test -f "FishingLog/Core/Network/APIClient.swift"
check "CoreDataManager.swift 存在" test -f "FishingLog/Core/CoreData/CoreDataManager.swift"
check "SyncManager.swift 存在"     test -f "FishingLog/Core/Sync/SyncManager.swift"
check "LoginView.swift 存在"       test -f "FishingLog/Features/Auth/LoginView.swift"
check "TripsListView.swift 存在"   test -f "FishingLog/Features/Trips/List/TripsListView.swift"
check "TripDetailView.swift 存在"  test -f "FishingLog/Features/Trips/Detail/TripDetailView.swift"
check "NewTripView.swift 存在"     test -f "FishingLog/Features/Trips/NewTrip/NewTripView.swift"

# 3. Core Data 模型检查
check "xcdatamodeld 存在"          test -d "FishingLog/Resources/FishingLog.xcdatamodeld"
check "TripEntity 定义存在"        grep -r "TripEntity"     "FishingLog/Resources/"
check "CatchEntity 定义存在"       grep -r "CatchEntity"    "FishingLog/Resources/"
check "EquipmentEntity 定义存在"   grep -r "EquipmentEntity" "FishingLog/Resources/"
check "MediaEntity 定义存在"       grep -r "MediaEntity"     "FishingLog/Resources/"
check "SpotEntity 定义存在"        grep -r "SpotEntity"      "FishingLog/Resources/"

# ===== Phase 2 文件检查 =====
echo ""
echo "--- Phase 2 文件检查 ---"

# 统计模块
check "StatsView.swift 存在"           test -f "FishingLog/Features/Stats/StatsView.swift"
check "StatsViewModel.swift 存在"      test -f "FishingLog/Features/Stats/StatsViewModel.swift"
check "StatsModel.swift 存在"          test -f "FishingLog/Core/Network/Models/StatsModel.swift"
check "StatsAPI.swift 存在"            test -f "FishingLog/Core/Network/Routes/StatsAPI.swift"
check "OverviewCardsView.swift 存在"   test -f "FishingLog/Features/Stats/Components/OverviewCardsView.swift"
check "SeasonalChartView.swift 存在"   test -f "FishingLog/Features/Stats/Components/SeasonalChartView.swift"
check "SpeciesChartView.swift 存在"    test -f "FishingLog/Features/Stats/Components/SpeciesChartView.swift"
check "TopCatchListView.swift 存在"    test -f "FishingLog/Features/Stats/Components/TopCatchListView.swift"

# 装备模块
check "GearListView.swift 存在"        test -f "FishingLog/Features/Equipment/GearListView.swift"
check "GearListViewModel.swift 存在"   test -f "FishingLog/Features/Equipment/GearListViewModel.swift"
check "GearCardView.swift 存在"        test -f "FishingLog/Features/Equipment/Components/GearCardView.swift"
check "NewEquipmentView.swift 存在"    test -f "FishingLog/Features/Equipment/NewEquipmentView.swift"
check "EditEquipmentView.swift 存在"   test -f "FishingLog/Features/Equipment/EditEquipmentView.swift"
check "EquipmentAPI.swift 存在"        test -f "FishingLog/Core/Network/Routes/EquipmentAPI.swift"

# 媒体模块
check "MediaModel.swift 存在"          test -f "FishingLog/Core/Network/Models/MediaModel.swift"
check "MediaAPI.swift 存在"            test -f "FishingLog/Core/Network/Routes/MediaAPI.swift"
check "MediaUploadManager.swift 存在"  test -f "FishingLog/Core/Media/MediaUploadManager.swift"
check "FullScreenImageView.swift 存在" test -f "FishingLog/Features/Media/FullScreenImageView.swift"
check "TripMediaGridView.swift 存在"   test -f "FishingLog/Features/Trips/Detail/Components/TripMediaGridView.swift"

# 钓点模块
check "SpotModel.swift 存在"           test -f "FishingLog/Core/Network/Models/SpotModel.swift"
check "SpotAPI.swift 存在"             test -f "FishingLog/Core/Network/Routes/SpotAPI.swift"
check "SpotsView.swift 存在"           test -f "FishingLog/Features/Spots/SpotsView.swift"
check "SpotsViewModel.swift 存在"      test -f "FishingLog/Features/Spots/SpotsViewModel.swift"
check "SpotMapView.swift 存在"         test -f "FishingLog/Features/Spots/SpotMapView.swift"
check "SpotListView.swift 存在"        test -f "FishingLog/Features/Spots/SpotListView.swift"
check "NewSpotView.swift 存在"         test -f "FishingLog/Features/Spots/NewSpotView.swift"
check "SpotAnnotationView.swift 存在"  test -f "FishingLog/Features/Spots/Components/SpotAnnotationView.swift"
check "SpotCardView.swift 存在"        test -f "FishingLog/Features/Spots/Components/SpotCardView.swift"

# 个人中心模块
check "ProfileView.swift 存在"         test -f "FishingLog/Features/Profile/ProfileView.swift"
check "ProfileViewModel.swift 存在"    test -f "FishingLog/Features/Profile/ProfileViewModel.swift"
check "SettingsView.swift 存在"        test -f "FishingLog/Features/Profile/SettingsView.swift"
check "AboutView.swift 存在"           test -f "FishingLog/Features/Profile/AboutView.swift"

# 4. XcodeGen 生成
echo ""
echo "--- 构建验证 ---"
check "xcodegen generate 成功" xcodegen generate

# 5. 编译
echo "⏳ 编译中，可能需要几分钟..."
check "xcodebuild 编译无 error" xcodebuild build \
    -project FishingLog.xcodeproj \
    -scheme FishingLog \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath /tmp/fl-build \
    CODE_SIGNING_ALLOWED=NO \
    -quiet

# 汇总
echo ""
echo "==============================="
echo -e "通过: ${GREEN}$PASS${NC}  失败: ${RED}$FAIL${NC}"
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}✓ 全部通过${NC}"
else
    echo -e "${RED}✗ 有 $FAIL 项未通过，请修复后重新验证${NC}"
    exit 1
fi
