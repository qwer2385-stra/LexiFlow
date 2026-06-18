import SwiftUI

// MARK: - LexiFlow 字体扩展

extension Font {

    /// 大标题：largeTitle + 加粗
    static let lfLargeTitle: Font = .largeTitle.bold()

    /// 标题：title2 + 半粗
    static let lfTitle2: Font = .title2.weight(.semibold)

    /// 正文
    static let lfBody: Font = .body

    /// 辅文
    static let lfSubheadline: Font = .subheadline

    /// 单词卡片：28pt serif 加粗
    static let lfWordCard: Font = .system(size: 28, weight: .bold, design: .serif)

    /// 音标：16pt
    static let lfPhonetic: Font = .system(size: 16)
}
