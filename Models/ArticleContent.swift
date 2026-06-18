import Foundation

/// 文章内容（值类型，含高亮信息）
struct ArticleContent {
    /// 文章 ID
    let articleID: UUID
    /// 文章标题
    let title: String
    /// 富文本正文（含高亮）
    let attributedBody: AttributedString
    /// 高亮单词 ID 列表
    let highlightedWordIDs: [String]
    /// 总词数
    let wordCount: Int
    /// 估计阅读时间（分钟）
    let estimatedReadMinutes: Int
}
