import Foundation

// MARK: - String 扩展

extension String {

    /// 去除首尾空白与换行
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 是否为空或仅包含空白
    var isBlank: Bool {
        trimmed.isEmpty
    }

    /// 单词数（按空格拆分）
    var wordCount: Int {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.count
    }

    /// 估计阅读时间（分钟），基于给定 WPM
    func estimatedReadMinutes(wpm: Double = AppConstants.defaultWPM) -> Int {
        let count = Double(self.wordCount)
        let minutes = count / wpm
        return max(1, Int(ceil(minutes)))
    }

    /// 截取前 N 个字符，超出追加 "..."
    func truncated(_ maxLength: Int) -> String {
        guard count > maxLength else { return self }
        let index = self.index(startIndex, offsetBy: maxLength)
        return String(self[..<index]) + "..."
    }
}
