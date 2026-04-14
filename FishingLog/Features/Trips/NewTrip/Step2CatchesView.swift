import SwiftUI

struct Step2CatchesView: View {
    @ObservedObject var vm: NewTripViewModel
    @State private var showAddCatch = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(vm.catches) { catch_ in
                        FLCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(catch_.species.isEmpty ? "未命名" : catch_.species)
                                        .font(.flHeadline).foregroundColor(.textPrimary)
                                    Text("\(catch_.count) 尾 · \(catch_.weightG)g\(catch_.isReleased ? " · 放流" : "")")
                                        .font(.flCaption).foregroundColor(.textSecondary)
                                }
                                Spacer()
                                Button {
                                    vm.catches.removeAll { $0.id == catch_.id }
                                } label: {
                                    Image(systemName: "trash").foregroundColor(.destructiveRed)
                                }
                            }
                        }
                    }

                    Button { showAddCatch = true } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill").foregroundColor(.primaryGold)
                            Text("添加渔获").foregroundColor(.primaryGold).font(.flHeadline)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.primaryGold.opacity(0.1))
                        .cornerRadius(FLMetrics.cornerRadius)
                    }
                }
                .padding(.horizontal, FLMetrics.horizontalPadding)
                .padding(.vertical, 16)
            }
        }
        .sheet(isPresented: $showAddCatch) {
            AddCatchSheet(styleCodes: Array(vm.selectedStyleCodes)) { newCatch in
                vm.catches.append(newCatch)
            }
        }
    }
}

struct AddCatchSheet: View {
    let styleCodes: [String]
    let onAdd: (NewCatchForm) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var form = NewCatchForm()
    @State private var weightStr = ""
    @State private var lengthStr = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        FLCard {
                            VStack(spacing: 12) {
                                FLTextField(placeholder: "鱼种名称（必填）", text: $form.species)
                                HStack {
                                    FLTextField(placeholder: "重量 (g)", text: $weightStr, keyboardType: .numberPad)
                                    FLTextField(placeholder: "体长 (cm)", text: $lengthStr, keyboardType: .decimalPad)
                                }
                                HStack {
                                    Text("数量").font(.flBody).foregroundColor(.textPrimary)
                                    Spacer()
                                    Stepper("\(form.count)", value: $form.count, in: 1...99)
                                        .foregroundColor(.textPrimary)
                                }
                                HStack {
                                    Text("已放流").font(.flBody).foregroundColor(.textPrimary)
                                    Spacer()
                                    Toggle("", isOn: $form.isReleased).tint(.primaryGold)
                                }
                                if !styleCodes.isEmpty {
                                    HStack {
                                        Text("钓法归属").font(.flBody).foregroundColor(.textPrimary)
                                        Spacer()
                                        Picker("", selection: $form.styleCode) {
                                            Text("不指定").tag(Optional<String>.none)
                                            ForEach(styleCodes, id: \.self) { code in
                                                Text(code == "LURE" ? "路亚" : "台钓").tag(Optional(code))
                                            }
                                        }.tint(.primaryGold)
                                    }
                                }
                            }
                        }
                    }
                    .padding(FLMetrics.horizontalPadding)
                }
            }
            .navigationTitle("添加渔获")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }.foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("添加") {
                        form.weightG = Int(weightStr) ?? 0
                        form.lengthCm = Double(lengthStr) ?? 0
                        onAdd(form)
                        dismiss()
                    }
                    .disabled(form.species.isEmpty)
                    .foregroundColor(form.species.isEmpty ? .textSecondary : .primaryGold)
                }
            }
        }
    }
}
