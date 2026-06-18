import SwiftUI

/// 环形进度条组件
/// 使用 Shape + animatableData 实现渐变色进度环
struct ProgressRing: View {

    /// 进度（0.0 ~ 1.0）
    let progress: Double
    /// 环的线宽
    let lineWidth: CGFloat
    /// 环的直径
    let size: CGFloat
    /// 中心显示的文字
    let centerText: String?

    /// 是否带动画
    var animated: Bool = true

    // MARK: - Init

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        size: CGFloat = 200,
        centerText: String? = nil,
        animated: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.size = size
        self.centerText = centerText
        self.animated = animated
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景环（灰色）
            Circle()
                .stroke(
                    Color.secondaryBackground,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // 进度环（渐变色）
            Circle()
                .trim(from: 0, to: animated ? progress : progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.accentBlue.opacity(0.5),
                            Color.accentBlue,
                            Color.accentBlue.opacity(0.8)
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)

            // 中心文字
            if let text = centerText {
                VStack(spacing: 4) {
                    Text(text)
                        .font(.lfLargeTitle)
                        .foregroundColor(.textPrimary)

                    Text("今日完成")
                        .font(.lfSubheadline)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        ProgressRing(
            progress: 0.5,
            centerText: "50%"
        )

        ProgressRing(
            progress: 0.75,
            lineWidth: 8,
            size: 120,
            centerText: "75%"
        )

        ProgressRing(
            progress: 1.0,
            lineWidth: 16,
            size: 160
        )
    }
    .padding()
    .background(Color.white)
}
