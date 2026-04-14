import SwiftUI

extension Color {
    // 背景层
    static let appBackground   = Color(hex: "#071325")  // 深海蓝黑主背景
    static let cardBackground  = Color(hex: "#0D2137")  // 卡片主背景
    static let cardElevated    = Color(hex: "#1F2A3D")  // 卡片次级（选中/浮层）
    static let cardSurface     = Color(hex: "#2A3548")  // 最高层（弹窗/底栏）
    // 主色 / 辅色（以 Stitch 设计稿为准）
    static let primaryGold     = Color(hex: "#E6C364")  // 金色主色（CTA/重要数字/标题）
    static let accentBlue      = Color(hex: "#75D1FF")  // 浅蓝辅色（次要数据/图标/链接）
    // 文字
    static let textPrimary     = Color(hex: "#FFFFFF")
    static let textSecondary   = Color(hex: "#D7E3FC")  // 次要文字（浅蓝白）
    static let textTertiary    = Color(hex: "#B5C8E5")  // 三级文字（更淡）
    // 功能色
    static let destructiveRed  = Color(hex: "#EF4444")

    // Hex 初始化器
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// 尺寸常量
enum FLMetrics {
    static let cornerRadius: CGFloat = 12
    static let horizontalPadding: CGFloat = 16
    static let cardPadding: CGFloat = 16
}
