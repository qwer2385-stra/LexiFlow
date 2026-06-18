import SwiftUI

/// 空状态占位组件
/// 图标 + 标题 + 描述
struct EmptyStateView: View {

    /// SF Symbol 图标名
    let icon: String
    /// 标题
    let title: String
    /// 描述
    let description: String
    /// 操作按钮文字（可选）
    var actionTitle: String?
    /// 操作回调
    var action: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(.textSecondary.opacity(0.6))

            Text(title)
                .font(.lfTitle2)
                .foregroundColor(.textPrimary)

            Text(description)
                .font(.lfSubheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.lfBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentBlue)
                        )
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        EmptyStateView(
            icon: "book.closed",
            title: "还没有单词",
            description: "开始阅读文章并标记生词，它们会出现在这里。",
            actionTitle: "去阅读文章",
            action: {}
        )

        EmptyStateView(
            icon: "chart.bar.xaxis",
            title: "暂无数据",
            description: "完成更多学习任务后，统计数据将在此显示。"
        )
    }
    .background(Color.white)
}
