import SwiftUI
import CoreLocation

struct Step1BasicInfoView: View {
    @ObservedObject var vm: NewTripViewModel
    private let styles = [("台钓", "TRADITIONAL"), ("路亚", "LURE")]
    // 控制地图选点弹出
    @State private var showMapPicker = false
    // 反向地理编码状态
    @State private var isGeocodingName = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 出行日期（必填）
                FLCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("出行日期 *", systemImage: "calendar")
                            .font(.flLabel).foregroundColor(.accentBlue)
                        DatePicker("", selection: $vm.tripDate, displayedComponents: .date)
                            .datePickerStyle(.compact).labelsHidden()
                            .tint(.primaryGold)
                    }
                }

                // 钓法（必填）
                FLCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("钓法 *（可多选）", systemImage: "figure.fishing")
                            .font(.flLabel).foregroundColor(.accentBlue)
                        HStack(spacing: 12) {
                            ForEach(styles, id: \.1) { name, code in
                                Toggle(name, isOn: Binding(
                                    get: { vm.selectedStyleCodes.contains(code) },
                                    set: { on in
                                        if on { vm.selectedStyleCodes.insert(code) }
                                        else  { vm.selectedStyleCodes.remove(code) }
                                    }
                                ))
                                .toggleStyle(.button).tint(.primaryGold)
                            }
                        }
                    }
                }

                // 地点名称 + 地图选坐标
                FLCard {
                    VStack(alignment: .leading, spacing: 10) {
                        // 标题行：标签 + 自动获取按钮
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
                            .disabled(isGeocodingName || (vm.latitude == 0 && vm.longitude == 0))
                            .opacity((vm.latitude == 0 && vm.longitude == 0) ? 0.4 : 1)
                        }
                        // 手动输入地点名称
                        FLTextField(placeholder: "输入钓场名称，如：西湖、黑木河口", text: $vm.locationName)
                        // 地图选择坐标按钮
                        Button { showMapPicker = true } label: {
                            HStack {
                                Image(systemName: "map.fill")
                                    .foregroundStyle(Color.accentBlue)
                                Text(vm.latitude != 0 ? String(format: "已选坐标: %.4f, %.4f", vm.latitude, vm.longitude) : "点击在地图上选择位置")
                                    .font(.flCaption)
                                    .foregroundStyle(vm.latitude != 0 ? Color.textSecondary : Color.textTertiary)
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
                        locationName: $vm.locationName,
                        latitude: $vm.latitude,
                        longitude: $vm.longitude
                    )
                }

                // 天气（支持按坐标自动获取）
                FLCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("天气", systemImage: "cloud.sun.fill")
                                .font(.flLabel).foregroundColor(.textSecondary)
                            Spacer()
                            Button {
                                Task { await vm.fetchWeather() }
                            } label: {
                                Label(vm.isLoadingWeather ? "获取中..." : "自动获取",
                                      systemImage: "arrow.clockwise")
                                    .font(.flCaption)
                                    .foregroundStyle(Color.accentBlue)
                            }
                            .disabled(vm.isLoadingWeather || (vm.latitude == 0 && vm.longitude == 0))
                            .opacity((vm.latitude == 0 && vm.longitude == 0) ? 0.4 : 1)
                        }
                        HStack(spacing: 12) {
                            FLTextField(placeholder: "温度 ℃", text: $vm.weatherTemp, keyboardType: .decimalPad)
                                .frame(maxWidth: 100)
                            FLTextField(placeholder: "天气状况（晴/阴/雨/雪）", text: $vm.weatherCondition)
                        }
                    }
                }

                // 同行人
                FLCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("同行钓友", systemImage: "person.2.fill")
                            .font(.flLabel).foregroundColor(.textSecondary)
                        FLTextField(placeholder: "多人用顿号分隔，如：小明、小红", text: $vm.companions)
                    }
                }
            }
            .padding(.horizontal, FLMetrics.horizontalPadding)
            .padding(.vertical, 16)
        }
    }

    // 根据坐标反向地理编码获取地点名称
    private func reverseGeocodeLocation() async {
        guard vm.latitude != 0, vm.longitude != 0 else { return }
        isGeocodingName = true
        defer { isGeocodingName = false }

        let location = CLLocation(latitude: vm.latitude, longitude: vm.longitude)
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let p = placemarks.first {
                // 优先 name，其次拼接 locality + thoroughfare
                if let name = p.name, !name.isEmpty {
                    vm.locationName = p.locality != nil && !name.contains(p.locality!) ? "\(p.locality!) \(name)" : name
                } else {
                    var parts: [String] = []
                    if let v = p.locality { parts.append(v) }
                    if let v = p.thoroughfare { parts.append(v) }
                    vm.locationName = parts.isEmpty ? String(format: "%.4f, %.4f", vm.latitude, vm.longitude) : parts.joined(separator: " ")
                }
            }
        } catch {
            // 失败时用坐标作为名称
            vm.locationName = String(format: "%.4f, %.4f", vm.latitude, vm.longitude)
        }
    }
}
