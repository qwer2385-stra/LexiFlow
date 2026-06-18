import Foundation

/// 考试题目（值类型，非持久化）
struct ExamQuestion: Identifiable, Codable {
    let id: UUID
    /// 题目文本
    let questionText: String
    /// 选项列表
    let options: [String]
    /// 正确答案索引
    let correctIndex: Int
    /// 用户选择索引
    var userSelectedIndex: Int?
    /// 答案解析
    let explanation: String
    /// 题目分类（vocabulary / sentence / comprehension）
    let category: String

    /// 用户是否回答正确
    var isCorrect: Bool {
        guard let selected = userSelectedIndex else { return false }
        return selected == correctIndex
    }

    /// 用户是否已作答
    var isAnswered: Bool {
        userSelectedIndex != nil
    }
}
