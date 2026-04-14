import SwiftUI

struct NewEquipmentView: View {
    let categories: [EquipmentCategory]
    var defaultGroup: EquipmentGroup = .traditional
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var modelName = ""
    @State private var selectedGroup: EquipmentGroup
    @State private var selectedCategoryId: Int? = nil
    @State private var status = "active"
    @State private var purchaseDate = Date()
    @State private var hasPurchaseDate = false
    @State private var priceText = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var error: String?

    init(categories: [EquipmentCategory], defaultGroup: EquipmentGroup = .traditional,
         onSaved: @escaping () -> Void) {
        self.categories = categories
        self.defaultGroup = defaultGroup
        self.onSaved = onSaved
        _selectedGroup = State(initialValue: defaultGroup)
    }

    // 当前大类下的小类
    private var groupCategories: [EquipmentCategory] {
        categories.filter { $0.groupCode == selectedGroup.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // 名称（必填）
                        VStack(alignment: .leading, spacing: 6) {
                            Text("名称 *").font(.flLabel).foregroundStyle(Color.textSecondary)
                            FLTextField(placeholder: "装备名称", text: $name)
                        }

                        // 品牌
                        VStack(alignment: .leading, spacing: 6) {
                            Text("品牌").font(.flLabel).foregroundStyle(Color.textSecondary)
                            FLTextField(placeholder: "品牌", text: $brand)
                        }

                        // 型号
                        VStack(alignment: .leading, spacing: 6) {
                            Text("型号").font(.flLabel).foregroundStyle(Color.textSecondary)
                            FLTextField(placeholder: "型号", text: $modelName)
                        }

                        // 大类选择
                        VStack(alignment: .leading, spacing: 6) {
                            Text("大类").font(.flLabel).foregroundStyle(Color.textSecondary)
                            Picker("大类", selection: $selectedGroup) {
                                ForEach(EquipmentGroup.allCases) { group in
                                    Text(group.displayName).tag(group)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: selectedGroup) { _, _ in
                                // 切换大类时重置小类
                                selectedCategoryId = nil
                            }
                        }

                        // 小类选择
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

                        // 状态
                        VStack(alignment: .leading, spacing: 6) {
                            Text("状态").font(.flLabel).foregroundStyle(Color.textSecondary)
                            Picker("状态", selection: $status) {
                                Text("在用").tag("active")
                                Text("停用").tag("inactive")
                                Text("维修中").tag("maintenance")
                            }
                            .pickerStyle(.segmented)
                        }

                        // 购买日期
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

                        // 购买价格
                        VStack(alignment: .leading, spacing: 6) {
                            Text("购买价格").font(.flLabel).foregroundStyle(Color.textSecondary)
                            FLTextField(placeholder: "0.00", text: $priceText, keyboardType: .decimalPad)
                        }

                        // 备注
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
            .navigationTitle("新建装备")
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

        let req = CreateEquipmentRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            brand: brand.isEmpty ? nil : brand,
            model: modelName.isEmpty ? nil : modelName,
            categoryId: selectedCategoryId,
            styleTags: nil,
            status: status,
            purchaseDate: hasPurchaseDate ? fmt.string(from: purchaseDate) : nil,
            purchasePrice: Double(priceText),
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let item = try await APIClient.shared.createEquipment(req)
            CoreDataManager.shared.insertEquipment(item)
            onSaved()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}
