import SwiftUI

/// 高亮文本组件
/// 使用 AttributedString 渲染高频词高亮（黄色/蓝色背景）
struct HighlightText: View {

    /// 富文本正文
    let attributedBody: AttributedString

    // MARK: - Init

    /// 从纯文本 + 高亮词列表构建
    init(text: String, highlightedWords: [String], highlightColor: Color = .highlightYellow) {
        var attributed = AttributedString(text)

        // 对整个文本应用默认样式
        let fullRange = attributed.startIndex..<attributed.endIndex
        attributed[fullRange].font = .lfBody
        attributed[fullRange].foregroundColor = .textPrimary

        // 设置行间距
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.paragraphSpacing = 8
        attributed[fullRange].paragraphStyle = paragraphStyle

        // 对每个高亮词应用样式（使用 NSString 进行边界检查）
        let nsText = text as NSString
        for word in highlightedWords {
            var searchRange = NSRange(location: 0, length: nsText.length)
            while searchRange.location < nsText.length {
                let foundRange = nsText.range(
                    of: word,
                    options: [.caseInsensitive],
                    range: searchRange
                )
                guard foundRange.location != NSNotFound else { break }

                // 检查单词边界（前后字符是否为字母）
                let isStartBoundary = foundRange.location == 0 ||
                    !isLetterChar(nsText.character(at: foundRange.location - 1))
                let endPos = foundRange.location + foundRange.length
                let isEndBoundary = endPos >= nsText.length ||
                    !isLetterChar(nsText.character(at: endPos))

                if isStartBoundary && isEndBoundary {
                    // 将 NSRange 转换为 AttributedString 范围
                    if let attrRange = Range(foundRange, in: attributed) {
                        attributed[attrRange].backgroundColor = highlightColor
                        attributed[attrRange].foregroundColor = .accentBlue
                        attributed[attrRange].font = .system(size: 16, weight: .semibold)
                    }
                }

                searchRange.location = foundRange.location + foundRange.length
                searchRange.length = nsText.length - searchRange.location
            }
        }

        self.attributedBody = attributed
    }

    /// 直接传入已构建的 AttributedString
    init(attributed: AttributedString) {
        self.attributedBody = attributed
    }

    // MARK: - Body

    var body: some View {
        Text(attributedBody)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
    }
}

// MARK: - Helper

/// 检查 unichar 是否为字母字符
private func isLetterChar(_ ch: unichar) -> Bool {
    guard let scalar = UnicodeScalar(ch) else { return false }
    return CharacterSet.letters.contains(scalar)
}

// MARK: - Preview

#Preview {
    ScrollView {
        HighlightText(
            text: "Artificial intelligence is rapidly changing how people learn new languages. Recent advances in natural language processing have made it possible.",
            highlightedWords: ["Artificial", "intelligence", "language", "processing"],
            highlightColor: .highlightYellow
        )
        .padding()
    }
    .background(Color.white)
}
