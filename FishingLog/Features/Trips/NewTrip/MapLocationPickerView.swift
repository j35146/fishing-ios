import SwiftUI
import MapKit
import CoreLocation

/// 地图选点视图 — 从新建出行表单中以 sheet 方式弹出
/// 支持搜索地名、点击地图选点、反向地理编码获取地名
struct MapLocationPickerView: View {
    @Binding var locationName: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Environment(\.dismiss) private var dismiss

    // 地图状态
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedName = ""

    // 搜索状态
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showSearchResults = false

    // 当前可见区域（用于限定搜索范围）
    @State private var visibleRegion: MKCoordinateRegion?

    // 中国中心坐标（默认起始位置）
    private let defaultCenter = CLLocationCoordinate2D(latitude: 35.0, longitude: 105.0)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBackground.ignoresSafeArea()

                // 底层：地图
                mapLayer

                // 顶层：搜索栏 + 搜索结果
                VStack(spacing: 0) {
                    searchBar
                    if showSearchResults && !searchResults.isEmpty {
                        searchResultsList
                    }
                    Spacer()
                }
                .padding(.top, 8)

                // 右下角：定位按钮 + 底部确认栏
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        // 自定义定位按钮
                        Button {
                            position = .userLocation(fallback: .automatic)
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.accentBlue)
                                .frame(width: 40, height: 40)
                                .background(Color.cardBackground.opacity(0.9))
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        }
                        .padding(.trailing, FLMetrics.horizontalPadding)
                        .padding(.bottom, 12)
                    }
                    if selectedCoordinate != nil {
                        confirmationBar
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
            .onAppear {
                // 初始化地图位置：如果已有坐标绑定值则使用，否则默认中国中心
                if latitude != 0 && longitude != 0 {
                    let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    selectedCoordinate = coord
                    selectedName = locationName
                    position = .region(MKCoordinateRegion(
                        center: coord,
                        latitudinalMeters: 5000,
                        longitudinalMeters: 5000
                    ))
                } else {
                    position = .region(MKCoordinateRegion(
                        center: defaultCenter,
                        latitudinalMeters: 5_000_000,
                        longitudinalMeters: 5_000_000
                    ))
                }
            }
        }
    }

    // MARK: - 地图层

    private var mapLayer: some View {
        MapReader { proxy in
            Map(position: $position) {
                // 显示用户位置
                UserAnnotation()

                // 选中的标记点
                if let coord = selectedCoordinate {
                    Marker(selectedName.isEmpty ? "选中位置" : selectedName, coordinate: coord)
                        .tint(Color.primaryGold)
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange { context in
                visibleRegion = context.region
            }
            .onTapGesture { screenPoint in
                // 将屏幕坐标转为地理坐标
                if let coordinate = proxy.convert(screenPoint, from: .local) {
                    selectLocation(coordinate)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - 搜索栏

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textTertiary)
                .font(.flBody)

            TextField("搜索地名或钓场", text: $searchText)
                .foregroundColor(.textPrimary)
                .font(.flBody)
                .autocorrectionDisabled()
                .onSubmit {
                    Task { await search() }
                }
                .onChange(of: searchText) { _, newValue in
                    if newValue.isEmpty {
                        searchResults = []
                        showSearchResults = false
                    }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                    showSearchResults = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textTertiary)
                }
            }

            if isSearching {
                ProgressView()
                    .tint(.accentBlue)
                    .scaleEffect(0.8)
            }
        }
        .padding(12)
        .background(Color.cardBackground.opacity(0.95))
        .cornerRadius(FLMetrics.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: FLMetrics.cornerRadius)
                .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, FLMetrics.horizontalPadding)
    }

    // MARK: - 搜索结果列表

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchResults, id: \.self) { item in
                    Button {
                        selectSearchResult(item)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.accentBlue)
                                .font(.flHeadline)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name ?? "未知地点")
                                    .font(.flBody)
                                    .foregroundColor(.textPrimary)
                                    .lineLimit(1)

                                if let address = formatAddress(item) {
                                    Text(address)
                                        .font(.flCaption)
                                        .foregroundColor(.textTertiary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, FLMetrics.cardPadding)
                        .padding(.vertical, 12)
                    }

                    Divider()
                        .background(Color.textSecondary.opacity(0.1))
                }
            }
        }
        .frame(maxHeight: 240)
        .background(Color.cardBackground.opacity(0.95))
        .cornerRadius(FLMetrics.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: FLMetrics.cornerRadius)
                .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, FLMetrics.horizontalPadding)
        .padding(.top, 4)
    }

    // MARK: - 底部确认栏

    private var confirmationBar: some View {
        VStack(spacing: 12) {
            // 选中位置信息
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.primaryGold)
                    .font(.flHeadline)

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedName.isEmpty ? "未知位置" : selectedName)
                        .font(.flHeadline)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    if let coord = selectedCoordinate {
                        Text(String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                            .font(.flCaption)
                            .foregroundColor(.textTertiary)
                    }
                }

                Spacer()
            }

            // 确认按钮
            Button {
                confirmSelection()
            } label: {
                Text("确认")
                    .font(.flHeadline)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.primaryGold)
                    .cornerRadius(FLMetrics.cornerRadius)
            }
        }
        .padding(FLMetrics.cardPadding)
        .background(Color.cardSurface.opacity(0.95))
        .cornerRadius(FLMetrics.cornerRadius)
        .padding(.horizontal, FLMetrics.horizontalPadding)
        .padding(.bottom, 16)
    }

    // MARK: - 搜索位置

    private func search() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // 优先在当前地图可见区域内搜索
        if let region = visibleRegion {
            request.region = region
        }

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            searchResults = response.mapItems
            showSearchResults = true
        } catch {
            searchResults = []
            showSearchResults = false
        }
    }

    // MARK: - 选择搜索结果

    private func selectSearchResult(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        selectedCoordinate = coordinate
        selectedName = item.name ?? formatPlacemark(item.placemark)

        // 移动地图到选中位置
        position = .region(MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        ))

        // 收起搜索结果
        showSearchResults = false
        searchText = selectedName
    }

    // MARK: - 选择位置并反向地理编码

    private func selectLocation(_ coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        selectedName = "加载中…"

        // 收起搜索结果
        showSearchResults = false

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()

        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    selectedName = formatPlacemark(placemark)
                } else {
                    selectedName = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                }
            } catch {
                // 反向地理编码失败时使用坐标作为名称
                selectedName = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
            }
        }
    }

    // MARK: - 确认选择

    private func confirmSelection() {
        guard let coord = selectedCoordinate else { return }
        locationName = selectedName
        latitude = coord.latitude
        longitude = coord.longitude
        dismiss()
    }

    // MARK: - 格式化地址

    /// 从 CLPlacemark 生成可读的地名字符串
    private func formatPlacemark(_ placemark: CLPlacemark) -> String {
        // 优先使用 name，其次拼接 locality + thoroughfare
        if let name = placemark.name, !name.isEmpty {
            if let locality = placemark.locality, !name.contains(locality) {
                return "\(locality) \(name)"
            }
            return name
        }
        var parts: [String] = []
        if let locality = placemark.locality { parts.append(locality) }
        if let thoroughfare = placemark.thoroughfare { parts.append(thoroughfare) }
        if let subThoroughfare = placemark.subThoroughfare { parts.append(subThoroughfare) }
        return parts.isEmpty
            ? String(format: "%.4f, %.4f", placemark.location?.coordinate.latitude ?? 0, placemark.location?.coordinate.longitude ?? 0)
            : parts.joined(separator: " ")
    }

    /// 从 MKMapItem 格式化地址信息
    private func formatAddress(_ item: MKMapItem) -> String? {
        let placemark = item.placemark
        var parts: [String] = []
        if let locality = placemark.locality { parts.append(locality) }
        if let subLocality = placemark.subLocality { parts.append(subLocality) }
        if let administrativeArea = placemark.administrativeArea {
            if !parts.contains(administrativeArea) { parts.append(administrativeArea) }
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}
