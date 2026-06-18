import SwiftUI

/// 难度评级按钮组
/// 三个按钮：简单/良好/困难，对应蓝/绿/橙配色
struct DifficultyButton: View {

    // MARK: - Properties

    /// 当前选中的难度
    @Binding var selectedDifficulty: SRSDifficulty?
    /// 点击回调
    let onSelect: (SRSDifficulty) -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            ForEach([SRSDifficulty.hard, .good, .easy], id: \.label) { difficulty in
                Button {
                    selectedDifficulty = difficulty
                    onSelect(difficulty)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: icon(for: difficulty))
                            .font(.title2)
                        Text(difficulty.label)
                            .font(.lfSubheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor(for: difficulty))
                    )
                    .foregroundColor(.white)
                    .scaleEffect(selectedDifficulty == difficulty ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3), value: selectedDifficulty)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func icon(for difficulty: SRSDifficulty) -> String {
        switch difficulty {
        case .easy: return "hand.thumbsup.fill"
        case .good: return "checkmark.circle.fill"
        case .hard: return "hand.thumbsdown.fill"
        }
    }

    private func backgroundColor(for difficulty: SRSDifficulty) -> Color {
        switch difficulty {
        case .easy:   return Color.accentBlue
        case .good:   return Color.successGreen
        case .hard:   return Color.warningOrange
        }
    }
}

// MARK: - Preview

#Preview {
    DifficultyButton(selectedDifficulty: .constant(nil)) { difficulty in
        print("Selected: \(difficulty.label)")
    }
    .padding()
    .background(Color.white)
}
