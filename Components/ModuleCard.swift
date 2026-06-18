import SwiftUI

/// 首页模块入口卡片
/// 显示：图标 + 阶段名 + 建议时长 + 锁定/完成状态
struct ModuleCard: View {

    /// 阶段编号（1~4）
    let stage: Int
    /// 阶段图标（SF Symbol）
    let icon: String
    /// 阶段名称
    let name: String
    /// 建议时长（分钟）
    let suggestedMinutes: Int
    /// 是否已完成
    let isCompleted: Bool
    /// 是否锁定
    let isLocked: Bool
    /// 当前进行中
    let isActive: Bool

    /// 点击回调
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 左侧图标
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconForegroundColor)
                }

                // 中间文字
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("约 \(suggestedMinutes) 分钟")
                            .font(.caption)
                    }
                    .foregroundColor(.textSecondary)
                }

                Spacer()

                // 右侧状态
                statusIndicator
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? Color.accentBlue.opacity(0.4) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked ? 0.5 : 1.0)
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private var statusIndicator: some View {
        if isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.successGreen)
        } else if isActive {
            Image(systemName: "play.circle.fill")
                .font(.title3)
                .foregroundColor(.accentBlue)
        } else if isLocked {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundColor(.textSecondary)
        } else {
            Image(systemName: "circle")
                .font(.title3)
                .foregroundColor(.textSecondary)
        }
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        if isActive { return Color.accentBlue.opacity(0.05) }
        return Color.secondaryBackground
    }

    private var iconBackgroundColor: Color {
        if isLocked { return Color.secondaryBackground }
        if isCompleted { return Color.successGreen.opacity(0.15) }
        if isActive { return Color.accentBlue.opacity(0.15) }
        return Color.secondaryBackground
    }

    private var iconForegroundColor: Color {
        if isLocked { return .textSecondary }
        if isCompleted { return .successGreen }
        if isActive { return .accentBlue }
        return .textSecondary
    }

    private var textColor: Color {
        isLocked ? .textSecondary : .textPrimary
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        ModuleCard(
            stage: 1, icon: "newspaper.fill", name: "新闻输入",
            suggestedMinutes: 10, isCompleted: true, isLocked: false, isActive: false,
            action: {}
        )
        ModuleCard(
            stage: 2, icon: "text.magnifyingglass", name: "精读拆解",
            suggestedMinutes: 8, isCompleted: false, isLocked: false, isActive: true,
            action: {}
        )
        ModuleCard(
            stage: 3, icon: "brain.head.profile", name: "四六级训练",
            suggestedMinutes: 7, isCompleted: false, isLocked: true, isActive: false,
            action: {}
        )
        ModuleCard(
            stage: 4, icon: "pencil.and.outline", name: "英文输出",
            suggestedMinutes: 5, isCompleted: false, isLocked: true, isActive: false,
            action: {}
        )
    }
    .padding()
    .background(Color.white)
}
