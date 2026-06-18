import SwiftUI

/// 单词卡片行组件
/// 列表行样式：左文字（单词+释义），右日期+SRS 阶段标签
struct WordCard: View {

    /// 单词文本
    let wordText: String
    /// 释义
    let definition: String
    /// 音标（可选）
    var phonetic: String?
    /// 添加日期
    let date: Date
    /// SRS 阶段
    let srsStage: Int
    /// 是否已掌握
    var isMastered: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // 左侧：单词 + 释义
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(wordText)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundColor(.textPrimary)

                    if let phonetic = phonetic {
                        Text(phonetic)
                            .font(.lfPhonetic)
                            .foregroundColor(.textSecondary)
                    }

                    if isMastered {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.successGreen)
                    }
                }

                Text(definition)
                    .font(.lfSubheadline)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // 右侧：日期 + SRS 标签
            VStack(alignment: .trailing, spacing: 4) {
                Text(date.relativeDescription)
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Text(srsLabel)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(srsColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(srsColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    // MARK: - SRS 阶段标签

    private var srsLabel: String {
        if isMastered { return "已掌握" }
        switch srsStage {
        case 0: return "新词"
        case 1, 2: return "学习中"
        case 3, 4: return "巩固中"
        default: return "已掌握"
        }
    }

    private var srsColor: Color {
        if isMastered { return .successGreen }
        switch srsStage {
        case 0: return .errorRed
        case 1, 2: return .warningOrange
        case 3, 4: return .accentBlue
        default: return .successGreen
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        WordCard(
            wordText: "abandon",
            definition: "放弃；遗弃",
            phonetic: "/əˈbændən/",
            date: Date(),
            srsStage: 0
        )
        WordCard(
            wordText: "ability",
            definition: "能力；才能",
            phonetic: "/əˈbɪləti/",
            date: Date().addingTimeInterval(-86400),
            srsStage: 2
        )
        WordCard(
            wordText: "brilliant",
            definition: "杰出的；明亮的",
            phonetic: "/ˈbrɪliənt/",
            date: Date().addingTimeInterval(-7 * 86400),
            srsStage: 5,
            isMastered: true
        )
    }
    .listStyle(.plain)
}
