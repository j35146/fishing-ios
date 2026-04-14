import SwiftUI

struct SettingsView: View {
    @State private var apiUrl: String = ""
    @State private var showSavedAlert = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("API 地址")
                            .font(.flLabel)
                            .foregroundStyle(Color.textSecondary)
                        Text("当前地址: \(currentBaseURL)")
                            .font(.flCaption)
                            .foregroundStyle(Color.textTertiary)
                        FLTextField(placeholder: "http://your-server.com", text: $apiUrl)
                    }

                    FLPrimaryButton("保存") {
                        let trimmed = apiUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            UserDefaults.standard.set(trimmed, forKey: "api_base_url_override")
                        } else {
                            UserDefaults.standard.removeObject(forKey: "api_base_url_override")
                        }
                        showSavedAlert = true
                    }

                    Text("保存后重启 App 生效")
                        .font(.flCaption)
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, FLMetrics.horizontalPadding)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("服务器设置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            apiUrl = UserDefaults.standard.string(forKey: "api_base_url_override") ?? ""
        }
        .alert("已保存", isPresented: $showSavedAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("API 地址已保存，重启 App 后生效")
        }
    }

    private var currentBaseURL: String {
        if let override = UserDefaults.standard.string(forKey: "api_base_url_override"),
           !override.isEmpty {
            return override
        }
        return APIClient.shared.baseURL
    }
}
