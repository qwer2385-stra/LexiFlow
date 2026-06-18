import SwiftUI

/// 3D 翻转卡片组件
/// 正反面内容通过闭包注入，点击触发翻转动画
struct FlipCardView<Front: View, Back: View>: View {

    // MARK: - Properties

    /// 是否已翻转
    @Binding var isFlipped: Bool
    /// 翻转角度
    @State private var rotation: Double = 0

    /// 正面内容
    let front: () -> Front
    /// 背面内容
    let back: () -> Back

    // MARK: - Init

    init(
        isFlipped: Binding<Bool>,
        @ViewBuilder front: @escaping () -> Front,
        @ViewBuilder back: @escaping () -> Back
    ) {
        self._isFlipped = isFlipped
        self.front = front
        self.back = back
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背面（当旋转超过 90° 时显示）
            backContent
                .opacity(rotation >= 90 ? 1 : 0)
                .rotation3DEffect(
                    .degrees(rotation + 180),
                    axis: (x: 0, y: 1, z: 0)
                )

            // 正面（当旋转小于 90° 时显示）
            frontContent
                .opacity(rotation < 90 ? 1 : 0)
                .rotation3DEffect(
                    .degrees(rotation),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .onTapGesture {
            flip()
        }
        .onChange(of: isFlipped) { newValue in
            withAnimation(.easeInOut(duration: 0.4)) {
                rotation = newValue ? 180 : 0
            }
        }
    }

    // MARK: - Content Views

    private var frontContent: some View {
        front()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var backContent: some View {
        back()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func flip() {
        withAnimation(.easeInOut(duration: 0.4)) {
            isFlipped.toggle()
            rotation = isFlipped ? 180 : 0
        }
    }
}

// MARK: - Preview

#Preview {
    FlipCardView(isFlipped: .constant(false)) {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.accentBlue)
            .overlay(
                Text("正面：单词")
                    .foregroundColor(.white)
                    .font(.lfWordCard)
            )
    } back: {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.successGreen)
            .overlay(
                Text("背面：释义")
                    .foregroundColor(.white)
                    .font(.lfTitle2)
            )
    }
    .frame(height: 300)
    .padding()
}
