import Foundation
import CoreData

/// 文章服务：解析文章、匹配高频词、WPM 计算
final class ArticleService {

    // MARK: - 词表加载

    /// CET4 高频词集合
    private(set) lazy var cet4WordSet: Set<String> = {
        loadWordSet(from: "CET4Words")
    }()

    /// CET6 高频词集合
    private(set) lazy var cet6WordSet: Set<String> = {
        loadWordSet(from: "CET6Words")
    }()

    // MARK: - 解析文章

    /// 将原始内容解析为含高亮标记的 ArticleContent
    func parseArticle(
        rawContent: String,
        articleID: UUID,
        title: String,
        cetLevel: String
    ) -> ArticleContent {
        let trimmed = rawContent.trimmed
        let words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordCount = words.count

        // 根据 CET 等级选择词表
        let wordSet = cetLevel == "CET6" ? cet6WordSet : cet4WordSet

        // 匹配高频词
        let matchedWords = matchHighFrequencyWords(content: trimmed, wordSet: wordSet)

        // 构建 AttributedString
        var attributed = AttributedString(trimmed)

        // 对每个匹配词高亮所有出现位置（使用 NSString 遍历全部匹配）
        let nsText = trimmed as NSString
        for match in matchedWords {
            var searchRange = NSRange(location: 0, length: nsText.length)
            while searchRange.location < nsText.length {
                let foundRange = nsText.range(
                    of: match,
                    options: [.caseInsensitive],
                    range: searchRange
                )
                guard foundRange.location != NSNotFound else { break }

                // 检查单词边界
                let isStartBoundary = foundRange.location == 0 ||
                    (foundRange.location > 0 && !isLetterChar(nsText.character(at: foundRange.location - 1)))
                let endPos = foundRange.location + foundRange.length
                let isEndBoundary = endPos >= nsText.length ||
                    (endPos < nsText.length && !isLetterChar(nsText.character(at: endPos)))

                if isStartBoundary && isEndBoundary {
                    if let attrRange = Range(foundRange, in: attributed) {
                        attributed[attrRange].backgroundColor = .yellow.opacity(0.3)
                        attributed[attrRange].foregroundColor = .blue
                        attributed[attrRange].font = .system(size: 16, weight: .semibold)
                        attributed[attrRange].underlineStyle = .single
                    }
                }

                searchRange.location = foundRange.location + foundRange.length
                searchRange.length = nsText.length - searchRange.location
            }
        }

        // 计算阅读时间
        let readMinutes = trimmed.estimatedReadMinutes(wpm: AppConstants.defaultWPM)

        return ArticleContent(
            articleID: articleID,
            title: title,
            attributedBody: attributed,
            highlightedWordIDs: matchedWords,
            wordCount: wordCount,
            estimatedReadMinutes: readMinutes
        )
    }

    // MARK: - 高频词匹配

    /// 在内容中标记所有 CET 词表中的词
    func matchHighFrequencyWords(content: String, wordSet: Set<String>) -> [String] {
        let words = content.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let lowercased = words.map { $0.lowercased() }
        let matched = lowercased.filter { wordSet.contains($0) }
        // 去重，返回原样大小写
        var unique: [String] = []
        var seen = Set<String>()
        for word in words {
            let lower = word.lowercased()
            if wordSet.contains(lower), !seen.contains(lower) {
                unique.append(word)
                seen.insert(lower)
            }
        }
        return unique
    }

    // MARK: - WPM 计算

    /// 计算 WPM（每分钟词数）
    func calculateWPM(wordCount: Int, seconds: Int) -> Double {
        guard seconds > 0 else { return 0 }
        let minutes = Double(seconds) / 60.0
        return Double(wordCount) / minutes
    }

    /// 估计阅读时间（分钟）
    func estimateReadTime(wordCount: Int, wpm: Double = AppConstants.defaultWPM) -> Int {
        let minutes = Double(wordCount) / wpm
        return max(1, Int(ceil(minutes)))
    }

    // MARK: - Private Helpers

    /// 从 JSON 文件加载词表
    private func loadWordSet(from fileName: String) -> Set<String> {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let words = try? JSONDecoder().decode([String].self, from: data) else {
            // 如果文件无法加载，返回一些内置的默认高频词
            return defaultWordSet()
        }
        return Set(words.map { $0.lowercased() })
    }

    /// 内置默认词表（约 50 个 CET4 高频词）
    private func defaultWordSet() -> Set<String> {
        let words = [
            "abandon", "ability", "able", "abnormal", "aboard", "abolish", "abortion",
            "about", "above", "abroad", "absence", "absolute", "absorb", "abstract",
            "abundant", "abuse", "academic", "accelerate", "accent", "accept",
            "access", "accompany", "accomplish", "account", "accurate", "accuse",
            "achieve", "acknowledge", "acquire", "adapt", "adequate", "adjust",
            "admire", "admit", "adopt", "advance", "advantage", "advertise",
            "affair", "affect", "afford", "aggressive", "agree", "agriculture",
            "allow", "alternative", "amaze", "ambition", "analyze", "ancient"
        ]
        return Set(words)
    }
}

// MARK: - File-Private Helper

/// 检查 unichar 是否为字母字符（用于单词边界检查）
private func isLetterChar(_ ch: unichar) -> Bool {
    guard let scalar = UnicodeScalar(ch) else { return false }
    return CharacterSet.letters.contains(scalar)
}
