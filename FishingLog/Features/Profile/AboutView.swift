import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()

                // App 图标
                Image(systemName: "fish.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.primaryGold)

                // 名称 + 版本
                VStack(spacing: 6) {
                    Text("钓鱼志")
                        .font(.flTitle)
                        .foregroundStyle(Color.primaryGold)
                    Text("版本 \(appVersion)")
                        .font(.flCaption)
                        .foregroundStyle(Color.textTertiary)
                }

                // 简介
                Text("个人钓鱼记录与数据分析工具，支持离线使用，联网自动同步。")
                    .font(.flBody)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // 技术栈
                VStack(alignment: .leading, spacing: 8) {
                    Text("技术栈")
                        .font(.flHeadline)
                        .foregroundStyle(Color.textPrimary)
                    VStack(alignment: .leading, spacing: 4) {
                        TechItem(name: "SwiftUI", desc: "声明式 UI 框架")
                        TechItem(name: "Core Data", desc: "本地数据持久化")
                        TechItem(name: "Alamofire", desc: "网络请求")
                        TechItem(name: "Swift Charts", desc: "数据图表")
                        TechItem(name: "MapKit", desc: "地图与定位")
                    }
                }
                .padding(FLMetrics.cardPadding)
                .background(Color.cardBackground)
                .cornerRadius(FLMetrics.cornerRadius)
                .padding(.horizontal, FLMetrics.horizontalPadding)

                Spacer()
                Spacer()
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TechItem: View {
    let name: String
    let desc: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.accentBlue)
                .frame(width: 6, height: 6)
            Text(name)
                .font(.flBody)
                .foregroundStyle(Color.textPrimary)
            Text(desc)
                .font(.flCaption)
                .foregroundStyle(Color.textTertiary)
        }
    }
}
