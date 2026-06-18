import Foundation

/// 复习卡片（值类型，非持久化）
struct ReviewCard: Identifiable {
    /// 对应用户单词 ID
    let userWordID: UUID
    /// 单词文本
    let wordText: String
    /// 释义
    let definition: String
    /// 例句
    let exampleSentence: String
    /// 音标
    let phonetic: String
    /// SRS 阶段
    let srsStage: Int
    /// 是否已翻转
    var isFlipped: Bool = false

    var id: UUID { userWordID }
}
