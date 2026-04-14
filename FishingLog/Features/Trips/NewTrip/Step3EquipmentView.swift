import SwiftUI

struct Step3EquipmentView: View {
    @ObservedObject var vm: NewTripViewModel

    var grouped: [String: [EquipmentEntity]] {
        Dictionary(grouping: vm.availableEquipments) { $0.categoryName ?? "其他" }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(grouped.keys.sorted(), id: \.self) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category).font(.flLabel).foregroundColor(.textSecondary)
                            .padding(.horizontal, 4)
                        ForEach(grouped[category] ?? [], id: \.id) { eq in
                            let isSelected = vm.selectedEquipmentIds.contains(eq.id ?? "")
                            Button {
                                if isSelected { vm.selectedEquipmentIds.remove(eq.id ?? "") }
                                else { vm.selectedEquipmentIds.insert(eq.id ?? "") }
                            } label: {
                                FLCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(eq.name ?? "").font(.flBody).foregroundColor(.textPrimary)
                                            if let brand = eq.brand {
                                                Text(brand).font(.flCaption).foregroundColor(.textSecondary)
                                            }
                                        }
                                        Spacer()
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.primaryGold)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, FLMetrics.horizontalPadding)
            .padding(.vertical, 16)
        }
        .task { await vm.loadEquipments() }
    }
}
