import SwiftUI

struct Step1BasicInfoView: View {
    @ObservedObject var vm: NewTripViewModel
    private let styles = [("台钓", "TRADITIONAL"), ("路亚", "LURE")]

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

                // 地点
                FLCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("钓场/地点", systemImage: "location.fill")
                            .font(.flLabel).foregroundColor(.textSecondary)
                        FLTextField(placeholder: "如：西湖、黑木河口", text: $vm.locationName)
                    }
                }

                // 天气
                FLCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("天气", systemImage: "cloud.sun.fill")
                            .font(.flLabel).foregroundColor(.textSecondary)
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
}
