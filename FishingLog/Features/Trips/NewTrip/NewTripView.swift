import SwiftUI

struct NewTripView: View {
    let onComplete: () async -> Void
    @StateObject private var vm = NewTripViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    // 进度条
                    StepProgressBar(currentStep: vm.currentStep, totalSteps: 4)
                        .padding(.horizontal, FLMetrics.horizontalPadding)
                        .padding(.top, 16)

                    // 步骤内容
                    TabView(selection: $vm.currentStep) {
                        Step1BasicInfoView(vm: vm).tag(0)
                        Step2CatchesView(vm: vm).tag(1)
                        Step3EquipmentView(vm: vm).tag(2)
                        Step4SummaryView(vm: vm).tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: vm.currentStep)

                    // 底部按钮
                    HStack(spacing: 12) {
                        if vm.currentStep > 0 {
                            FLSecondaryButton("上一步") { vm.currentStep -= 1 }
                        }
                        if vm.currentStep < 3 {
                            FLPrimaryButton("下一步") { vm.currentStep += 1 }
                                .disabled(vm.currentStep == 0 && !vm.step1Valid)
                                .opacity(vm.currentStep == 0 && !vm.step1Valid ? 0.5 : 1)
                        } else {
                            FLPrimaryButton("完成保存", isLoading: vm.isSaving) {
                                Task {
                                    if await vm.save() {
                                        await onComplete()
                                        dismiss()
                                    }
                                }
                            }
                        }
                        // 上传错误提示
                        if let err = vm.errorMessage {
                            Text(err)
                                .font(.flCaption)
                                .foregroundStyle(Color.destructiveRed)
                                .padding(.horizontal, FLMetrics.horizontalPadding)
                        }
                    }
                    .padding(.horizontal, FLMetrics.horizontalPadding)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("新建出行")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= currentStep ? Color.primaryGold : Color.cardBackground)
                    .frame(height: 4)
            }
        }
    }
}
