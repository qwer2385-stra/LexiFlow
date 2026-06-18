import SwiftUI

// MARK: - LexiFlow 主题色

extension Color {

    /// 强调蓝 #007AFF
    static let accentBlue = Color(red: 0x00 / 255.0, green: 0x7A / 255.0, blue: 0xFF / 255.0)

    /// 次要背景 #F2F2F7
    static let secondaryBackground = Color(red: 0xF2 / 255.0, green: 0xF2 / 255.0, blue: 0xF7 / 255.0)

    /// 主文字 #1C1C1E
    static let textPrimary = Color(red: 0x1C / 255.0, green: 0x1C / 255.0, blue: 0x1E / 255.0)

    /// 次级文字 #8E8E93
    static let textSecondary = Color(red: 0x8E / 255.0, green: 0x8E / 255.0, blue: 0x93 / 255.0)

    /// 成功绿 #34C759
    static let successGreen = Color(red: 0x34 / 255.0, green: 0xC7 / 255.0, blue: 0x59 / 255.0)

    /// 警告橙 #FF9500
    static let warningOrange = Color(red: 0xFF / 255.0, green: 0x95 / 255.0, blue: 0x00 / 255.0)

    /// 错误红 #FF3B30
    static let errorRed = Color(red: 0xFF / 255.0, green: 0x3B / 255.0, blue: 0x30 / 255.0)

    /// 高亮黄（用于文章高频词标记）
    static let highlightYellow = Color(red: 1.0, green: 0.92, blue: 0.45)

    /// 高亮蓝（用于文章高频词标记）
    static let highlightBlue = Color(red: 0.60, green: 0.82, blue: 1.0)
}
