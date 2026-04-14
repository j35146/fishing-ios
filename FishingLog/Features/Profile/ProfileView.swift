import SwiftUI

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // 头像区
                        VStack(spacing: 10) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.accentBlue)
                            Text(vm.username)
                                .font(.flTitle)
                                .foregroundStyle(Color.textPrimary)
                        }
                        .padding(.top, 20)

                        // 统计小卡片行
                        HStack(spacing: 12) {
                            ProfileStatCard(value: "\(vm.totalTrips)", label: "总出行")
                            ProfileStatCard(value: "\(vm.totalCatches)", label: "总渔获")
                        }

                        // 设置列表
                        VStack(spacing: 0) {
                            NavigationLink {
                                SettingsView()
                            } label: {
                                SettingsRow(icon: "server.rack", title: "服务器设置")
                            }
                            Divider().background(Color.cardElevated)
                            NavigationLink {
                                AboutView()
                            } label: {
                                SettingsRow(icon: "info.circle", title: "关于钓鱼志")
                            }
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(FLMetrics.cornerRadius)

                        Spacer(minLength: 40)

                        // 退出登录按钮
                        Button {
                            showLogoutAlert = true
                        } label: {
                            Text("退出登录")
                                .font(.flHeadline)
                                .foregroundStyle(Color.destructiveRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.cardBackground)
                                .cornerRadius(FLMetrics.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: FLMetrics.cornerRadius)
                                        .stroke(Color.destructiveRed.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, FLMetrics.horizontalPadding)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .alert("退出登录", isPresented: $showLogoutAlert) {
                Button("确认退出", role: .destructive) {
                    vm.logout()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("退出后需要重新登录")
            }
        }
    }
}

// 统计小卡片
private struct ProfileStatCard: View {
    let value: String
    let label: String

    var body: some View {
        FLCard {
            VStack(spacing: 4) {
                Text(value)
                    .font(.flTitle)
                    .foregroundStyle(Color.primaryGold)
                Text(label)
                    .font(.flCaption)
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// 设置行
private struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentBlue)
                .frame(width: 24)
            Text(title)
                .font(.flBody)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.flCaption)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(FLMetrics.cardPadding)
    }
}
