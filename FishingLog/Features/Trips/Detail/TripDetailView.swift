import SwiftUI
import MapKit

struct TripDetailView: View {
    @StateObject private var vm: TripDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false

    private let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .long; f.locale = Locale(identifier: "zh_CN"); return f
    }()

    init(trip: TripEntity) {
        _vm = StateObject(wrappedValue: TripDetailViewModel(trip: trip))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 顶部信息卡
                    FLCard {
                        VStack(alignment: .leading, spacing: 10) {
                            if let date = vm.trip.tripDate {
                                Text(dateFmt.string(from: date))
                                    .font(.flCaption).foregroundColor(.textSecondary)
                            }
                            Text(vm.trip.locationName ?? "未记录地点")
                                .font(.flTitle).foregroundColor(.textPrimary)

                            // 钓法标签
                            let styleNames: [String] = (vm.trip.styleNames ?? "").split(separator: ",").map(String.init)
                            HStack(spacing: 8) {
                                ForEach(styleNames, id: \.self) { name in
                                    styleTagView(name)
                                }
                            }

                            // 天气
                            if let cond = vm.trip.weatherCondition, !cond.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "cloud.sun.fill").foregroundColor(.accentBlue)
                                    Text(cond).font(.flBody).foregroundColor(.textSecondary)
                                    if vm.trip.weatherTemp != 0 {
                                        Text("·  \(Int(vm.trip.weatherTemp))℃")
                                            .font(.flBody).foregroundColor(.textSecondary)
                                    }
                                }
                            }
                        }
                    }

                    // 钓场地图（有坐标时显示）
                    if vm.trip.latitude != 0 && vm.trip.longitude != 0 {
                        let coord = CLLocationCoordinate2D(
                            latitude: vm.trip.latitude,
                            longitude: vm.trip.longitude
                        )
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: coord,
                            latitudinalMeters: 2000,
                            longitudinalMeters: 2000
                        ))) {
                            Marker(vm.trip.locationName ?? "钓场", coordinate: coord)
                                .tint(Color.primaryGold)
                        }
                        .frame(height: 160)
                        .cornerRadius(FLMetrics.cornerRadius)
                        .allowsHitTesting(false)
                    }

                    // 渔获记录
                    if !vm.catches.isEmpty {
                        SectionHeader(title: "渔获记录", icon: "fish.fill")
                        ForEach(vm.catches, id: \.id) { catch_ in
                            FLCard {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(catch_.species ?? "未知鱼种")
                                            .font(.flHeadline).foregroundColor(.textPrimary)
                                        HStack(spacing: 8) {
                                            if catch_.weightG > 0 {
                                                Text("\(catch_.weightG)g").font(.flCaption).foregroundColor(.textSecondary)
                                            }
                                            Text("×\(catch_.count)").font(.flCaption).foregroundColor(.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    if catch_.isReleased {
                                        Text("放流").font(.flCaption).foregroundColor(.primaryGold)
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .overlay(RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.primaryGold, lineWidth: 1))
                                    }
                                }
                            }
                        }
                    }

                    // 出行相册
                    TripMediaGridView(tripLocalId: vm.trip.localId ?? UUID())

                    // 同行钓友
                    if let companions = vm.trip.companions as? [String], !companions.isEmpty {
                        SectionHeader(title: "同行钓友", icon: "person.2.fill")
                        FLCard {
                            Text(companions.joined(separator: "、"))
                                .font(.flBody).foregroundColor(.textPrimary)
                        }
                    }

                    // 备注
                    if let notes = vm.trip.notes, !notes.isEmpty {
                        SectionHeader(title: "备注", icon: "text.alignleft")
                        FLCard {
                            Text(notes).font(.flBody).foregroundColor(.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, FLMetrics.horizontalPadding)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(vm.trip.locationName ?? "行程详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Label("删除出行", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("删除", role: .destructive) {
                Task {
                    try? await vm.deleteTrip()
                    dismiss()
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复，确认删除此次出行记录？")
        }
    }

    // 钓法标签视图（拆分子表达式，避免 Swift 类型检查超时）
    @ViewBuilder
    private func styleTagView(_ name: String) -> some View {
        Text(name)
            .font(.flCaption)
            .foregroundColor(.appBackground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.accentBlue)
            .cornerRadius(6)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(.accentBlue).font(.flLabel)
            Text(title).font(.flLabel).foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 4)
    }
}
