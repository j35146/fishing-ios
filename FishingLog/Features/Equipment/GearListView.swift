import SwiftUI

struct GearListView: View {
    @StateObject private var vm = GearListViewModel()
    @State private var showNewEquipment = false
    @State private var editingEquipment: Equipment?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // 第一层：大类 Tab（台钓 / 路亚）
                    HStack(spacing: 0) {
                        ForEach(EquipmentGroup.allCases) { group in
                            Button {
                                vm.selectGroup(group)
                            } label: {
                                VStack(spacing: 6) {
                                    Text(group.displayName)
                                        .font(.flHeadline)
                                        .foregroundStyle(
                                            vm.selectedGroup == group
                                                ? Color.primaryGold
                                                : Color.textTertiary
                                        )
                                    // 底部指示条
                                    Rectangle()
                                        .fill(vm.selectedGroup == group
                                              ? Color.primaryGold
                                              : Color.clear)
                                        .frame(height: 2)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, FLMetrics.horizontalPadding)
                    .padding(.top, 4)

                    // 第二层：小类胶囊横向滚动
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(title: "全部",
                                         isSelected: vm.selectedCategoryId == nil) {
                                vm.selectCategory(nil)
                            }
                            ForEach(vm.filteredCategories) { cat in
                                CategoryChip(title: cat.name,
                                             isSelected: vm.selectedCategoryId == cat.id) {
                                    vm.selectCategory(cat.id)
                                }
                            }
                        }
                        .padding(.horizontal, FLMetrics.horizontalPadding)
                        .padding(.vertical, 8)
                    }

                    // 装备列表
                    if vm.equipments.isEmpty && !vm.isLoading {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.textTertiary)
                            Text("暂无装备")
                                .font(.flHeadline)
                                .foregroundStyle(Color.textSecondary)
                            Text("点击右上角添加")
                                .font(.flCaption)
                                .foregroundStyle(Color.textTertiary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(vm.equipments) { item in
                                NavigationLink {
                                    EquipmentDetailView(item: item,
                                                        categories: vm.categories,
                                                        onUpdated: { Task { await vm.refresh() } })
                                } label: {
                                    GearCardView(item: item,
                                                 onEdit: { editingEquipment = item },
                                                 onDelete: { Task { await vm.deleteEquipment(id: item.id) } })
                                }
                                .listRowBackground(Color.appBackground)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: FLMetrics.horizontalPadding,
                                                         bottom: 4, trailing: FLMetrics.horizontalPadding))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable { await vm.refresh() }
                    }
                }
            }
            .navigationTitle("装备库")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewEquipment = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.primaryGold)
                    }
                }
            }
            .sheet(isPresented: $showNewEquipment) {
                NewEquipmentView(categories: vm.categories,
                                 defaultGroup: vm.selectedGroup) {
                    Task { await vm.refresh() }
                }
            }
            .sheet(item: $editingEquipment) { item in
                EditEquipmentView(item: item, categories: vm.categories) {
                    Task { await vm.refresh() }
                }
            }
        }
        .task { await vm.refresh() }
    }
}

// 分类胶囊按钮
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.flLabel)
                .foregroundStyle(isSelected ? Color.appBackground : Color.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.primaryGold : Color.cardElevated)
                .cornerRadius(99)
        }
    }
}
