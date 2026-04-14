import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 32) {
                // Logo 区
                VStack(spacing: 8) {
                    Image(systemName: "figure.fishing")
                        .font(.system(size: 64))
                        .foregroundColor(.accentBlue)
                    Text("钓鱼志").font(.flTitle).foregroundColor(.textPrimary)
                    Text("记录每一次出行").font(.flBody).foregroundColor(.textSecondary)
                }
                .padding(.top, 80)

                // 表单区
                VStack(spacing: 16) {
                    FLTextField(placeholder: "用户名", text: $username)
                    SecureFieldFL(placeholder: "密码", text: $password)
                }
                .padding(.horizontal, FLMetrics.horizontalPadding)

                // 登录按钮
                FLPrimaryButton("登录", isLoading: isLoading) {
                    Task { await performLogin() }
                }
                .padding(.horizontal, FLMetrics.horizontalPadding)

                Spacer()
            }
        }
        .alert("登录失败", isPresented: .constant(errorMessage != nil)) {
            Button("确认") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func performLogin() async {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "请输入用户名和密码"; return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authManager.login(username: username, password: password)
        } catch {
            errorMessage = "用户名或密码错误"
        }
    }
}

// SecureField 包装，保持样式一致
struct SecureFieldFL: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField(placeholder, text: $text)
            .foregroundColor(.textPrimary)
            .padding(12)
            .background(Color.cardBackground)
            .cornerRadius(FLMetrics.cornerRadius)
            .overlay(RoundedRectangle(cornerRadius: FLMetrics.cornerRadius)
                .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 0)
    }
}
