import SwiftUI
import MapKit

struct NewSpotView: View {
    @ObservedObject var vm: SpotsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var spotType: SpotType = .lake
    @State private var desc = ""
    @State private var isPublic = true
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var pinLocation: CLLocationCoordinate2D?
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // 名称
                        VStack(alignment: .leading, spacing: 6) {
                            Text("名称 *").font(.flLabel).foregroundStyle(Color.textSecondary)
                            FLTextField(placeholder: "钓点名称", text: $name)
                        }

                        // 类型
                        VStack(alignment: .leading, spacing: 6) {
                            Text("类型").font(.flLabel).foregroundStyle(Color.textSecondary)
                            Picker("类型", selection: $spotType) {
                                ForEach(SpotType.allCases) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // 描述
                        VStack(alignment: .leading, spacing: 6) {
                            Text("描述").font(.flLabel).foregroundStyle(Color.textSecondary)
                            TextEditor(text: $desc)
                                .foregroundColor(.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 60)
                                .padding(8)
                                .background(Color.cardBackground)
                                .cornerRadius(FLMetrics.cornerRadius)
                        }

                        // 是否公开
                        Toggle(isOn: $isPublic) {
                            Text("公开钓点").font(.flLabel).foregroundStyle(Color.textSecondary)
                        }
                        .tint(.primaryGold)

                        // 地图选点
                        VStack(alignment: .leading, spacing: 6) {
                            Text("选择位置（长按地图标记）")
                                .font(.flLabel)
                                .foregroundStyle(Color.textSecondary)
                            MapPinSelector(
                                initialLocation: vm.userLocation,
                                pinLocation: $pinLocation
                            )
                            .frame(height: 200)
                            .cornerRadius(FLMetrics.cornerRadius)
                        }

                        // 坐标显示
                        if let pin = pinLocation {
                            HStack {
                                Text("经度: \(String(format: "%.6f", pin.longitude))")
                                    .font(.flCaption).foregroundStyle(Color.textTertiary)
                                Spacer()
                                Text("纬度: \(String(format: "%.6f", pin.latitude))")
                                    .font(.flCaption).foregroundStyle(Color.textTertiary)
                            }
                        }

                        // 手动输入坐标
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("纬度").font(.flCaption).foregroundStyle(Color.textTertiary)
                                FLTextField(placeholder: "31.2345", text: $latitude, keyboardType: .decimalPad)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("经度").font(.flCaption).foregroundStyle(Color.textTertiary)
                                FLTextField(placeholder: "121.4567", text: $longitude, keyboardType: .decimalPad)
                            }
                        }

                        if let error {
                            Text(error)
                                .font(.flCaption)
                                .foregroundStyle(Color.destructiveRed)
                        }

                        // 保存按钮
                        FLPrimaryButton("保存", isLoading: isSaving) {
                            Task { await save() }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, FLMetrics.horizontalPadding)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("新建钓点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private func save() async {
        // 确定坐标（优先使用地图选点，其次手动输入）
        let lat: Double
        let lng: Double
        if let pin = pinLocation {
            lat = pin.latitude
            lng = pin.longitude
        } else if let la = Double(latitude), let lo = Double(longitude) {
            lat = la
            lng = lo
        } else {
            error = "请选择或输入钓点坐标"
            return
        }

        isSaving = true
        error = nil

        let req = CreateSpotRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            description: desc.isEmpty ? nil : desc,
            latitude: lat,
            longitude: lng,
            spotType: spotType.rawValue,
            isPublic: isPublic,
            photoKey: nil
        )

        await vm.addSpot(req)
        isSaving = false
        dismiss()
    }
}

// 地图选点组件
struct MapPinSelector: View {
    let initialLocation: CLLocationCoordinate2D?
    @Binding var pinLocation: CLLocationCoordinate2D?

    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        MapReader { reader in
            Map(position: $position) {
                if let pin = pinLocation {
                    Marker("钓点", coordinate: pin)
                        .tint(Color.primaryGold)
                }
            }
            .mapStyle(.hybrid)
            .onTapGesture { point in
                if let coord = reader.convert(point, from: .local) {
                    pinLocation = coord
                }
            }
            .onAppear {
                if let loc = initialLocation {
                    position = .region(MKCoordinateRegion(
                        center: loc,
                        latitudinalMeters: 5000,
                        longitudinalMeters: 5000
                    ))
                }
            }
        }
    }
}
