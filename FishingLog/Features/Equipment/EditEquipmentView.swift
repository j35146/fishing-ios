import SwiftUI

struct EditEquipmentView: View {
    let item: Equipment
    let categories: [EquipmentCategory]
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var brand: String
    @State private var modelName: String
    @State private var selectedGroup: EquipmentGroup
    @State private var selectedCategoryId: Int?
    @State private var status: String
    @State private var purchaseDate: Date
    @State private var hasPurchaseDate: Bool
    @State private var priceText: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var error: String?

    // 当前大类下的小类
    private var groupCategories: [EquipmentCategory] {
        categories.filter { $0.groupCode == selectedGroup.rawValue }
    }

    init(item: Equipment, categories: [EquipmentCategory], onSaved: @escaping () -> Void) {
        self.item = item
        self.categories = categories
        self.onSaved = onSaved
        _name = State(initialValue: item.name)
        _brand = State(initialValue: item.brand ?? "")
        _modelName = State(initialValue: item.model ?? "")
        _selectedCategoryId = State(initialValue: item.categoryId)
        _status = State(initialValue: item.status ?? "active")
        _notes = State(initialValue: item.notes ?? "")
        _priceText = State(initialValue: item.purchasePrice.map { String(format: "%.0f", $0) } ?? "")

        // 根据已有 categoryId 推断大类
        if let catId = item.categoryId,
           let cat = categories.first(where: { $0.id == catId }) {
            _selectedGroup = State(initialValue: EquipmentGroup(rawValue: cat.groupCode ?? "traditional") ?? .traditional)
        } else {
            _selectedGroup = State(initialValue: .traditional)
        }

        if let dateStr = item.purchaseDate {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            _purchaseDate = State(initialValue: fmt.date(from: dateStr) ?? Date())
            _hasPurchaseDate = State(initialValue: true)
        } else {
            _purchaseDate = State(initialValue: Date())
            _hasPurchaseDate = State(initialValue: false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("名称 *").font(.flLabel).foregroundStyle(Color.textSecondary)
                            FLTextField(placeholder: "装备名称", text: $name)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("品牌").font(.flLabel).foregroundStyle(Color.textSecondary)
                            FLTextField(placeholder: "品牌", text: $brand)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("型号").font(.flLabel).foregroundStyle(Color.textSecondary)
                            FLTextField(placeholder: "型号", text: $modelName)
                        }

                        // 大类
                        VStack(alignment: .leading, spacing: 6) {
                            Text("大类").font(.flLabel).foregroundStyle(Color.textSecondary)
                            Picker("大类", selection: $selectedGroup) {
                                ForEach(EquipmentGroup.allCases) { group in
                                    Text(group.displayName).tag(group)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: selectedGroup) { _, _ in
                                selectedCategoryId = nil
                            }
                        }

                        // 小类
                        VStack(alignment: .leading, spacing: 6) {
                            Text("小类").font(.flLabel).foregroundStyle(Color.textSecondary)
                            Picker("小类", selection: $selectedCategoryId) {
                                Text("未分类").tag(nil as Int?)
                                ForEach(groupCategories) { cat in
                                    Text(cat.name).tag(cat.id as Int?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.cardBackground)
                            .cornerRadius(FLMetrics.cornerRadius)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("状态").font(.flLabel).foregroundStyle(Color.textSecondary)
                            Picker("状态", selection: $status) {
                                Text("在用").tag("active")
                                Text("停用").tag("inactive")
                                Text("维修中").tag("maintenance")
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(isOn: $hasPurchaseDate) {
                                Text("购买日期").font(.flLabel).foregroundStyle(Color.textSecondary)
                            }
                            .tint(.primaryGold)
                            if hasPurchaseDate {
                                DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("购买价格").font(.flLabel).foregroundStyle(Color.textSecondary)
                            FLTextField(placeholder: "0.00", text: $priceText, keyboardType: .decimalPad)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("备注").font(.flLabel).foregroundStyle(Color.textSecondary)
                            TextEditor(text: $notes)
                                .foregroundColor(.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color.cardBackground)
                                .cornerRadius(FLMetrics.cornerRadius)
                        }

                        if let error {
                            Text(error)
                                .font(.flCaption)
                                .foregroundStyle(Color.destructiveRed)
                        }

                        FLPrimaryButton("保存", isLoading: isSaving) {
                            Task { await save() }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, FLMetrics.horizontalPadding)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("编辑装备")
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
        isSaving = true
        error = nil

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        let req = UpdateEquipmentRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            brand: brand.isEmpty ? nil : brand,
            model: modelName.isEmpty ? nil : modelName,
            categoryId: selectedCategoryId,
            styleTags: [selectedGroup.styleTag],
            status: status,
            purchaseDate: hasPurchaseDate ? fmt.string(from: purchaseDate) : nil,
            purchasePrice: Double(priceText),
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let updated = try await APIClient.shared.updateEquipment(id: item.id, req)
            CoreDataManager.shared.updateEquipmentEntity(id: item.id, from: updated)
            onSaved()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}
