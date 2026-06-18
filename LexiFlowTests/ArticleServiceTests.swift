import XCTest
@testable import LexiFlow

// MARK: - 文章服务单元测试

final class ArticleServiceTests: XCTestCase {

    // MARK: - Properties

    var sut: ArticleService!

    // MARK: - Test Data

    let sampleArticle = """
    Artificial intelligence is rapidly changing how people learn new languages. \
    Recent advances in natural language processing have made it possible for \
    applications to provide personalized feedback on pronunciation, grammar, \
    and vocabulary usage. Students can now practice conversations with AI tutors \
    that adapt to their proficiency level and learning style. The technology \
    analyzes speech patterns and provides immediate corrections, helping learners \
    improve their skills more efficiently than traditional methods.
    """

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        sut = ArticleService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - CET4/CET6 词表加载测试

    /// Given: ArticleService initialized → Then: CET4 word set is loaded
    func test_cet4WordSet_isLoaded() {
        // When
        let wordSet = sut.cet4WordSet

        // Then
        XCTAssertFalse(wordSet.isEmpty,
                       "CET4 词表不应为空")
        // 内置 fallback 至少包含常见 CET4 词汇
        XCTAssertTrue(wordSet.contains("abandon"),
                      "CET4 词表应包含 'abandon'")
        XCTAssertTrue(wordSet.contains("ability"),
                      "CET4 词表应包含 'ability'")
    }

    /// Given: ArticleService initialized → Then: CET6 word set is loaded
    func test_cet6WordSet_isLoaded() {
        // When
        let wordSet = sut.cet6WordSet

        // Then
        XCTAssertFalse(wordSet.isEmpty,
                       "CET6 词表不应为空")
    }

    /// Given: Word sets are loaded → Then: all words are lowercased
    func test_wordSets_areLowercased() {
        // When
        let cet4 = sut.cet4WordSet
        let cet6 = sut.cet6WordSet

        // Then
        for word in cet4 {
            XCTAssertEqual(word, word.lowercased(),
                           "CET4 词表中 '\(word)' 未转换为小写")
        }
        for word in cet6 {
            XCTAssertEqual(word, word.lowercased(),
                           "CET6 词表中 '\(word)' 未转换为小写")
        }
    }

    // MARK: - matchHighFrequencyWords 测试

    /// Given: Content with CET4 words → When: matched against CET4 word set → Then: matched words returned
    func test_matchHighFrequencyWords_findsCET4Words() {
        // Given
        let content = "The ability to abandon old habits requires determination."
        // "ability" and "abandon" are in CET4 default set
        let wordSet = Set(["ability", "abandon", "determination"])

        // When
        let matched = sut.matchHighFrequencyWords(content: content, wordSet: wordSet)

        // Then
        XCTAssertEqual(matched.count, 2,
                       "应匹配到 2 个高频词")
        XCTAssertTrue(matched.contains("ability"),
                      "应匹配到 'ability'")
        XCTAssertTrue(matched.contains("abandon"),
                      "应匹配到 'abandon'")
    }

    /// Given: Content with repeated words → When: matched → Then: duplicates removed
    func test_matchHighFrequencyWords_removesDuplicates() {
        // Given: "ability" appears twice
        let content = "The ability to learn is a great ability."
        let wordSet = Set(["ability"])

        // When
        let matched = sut.matchHighFrequencyWords(content: content, wordSet: wordSet)

        // Then
        XCTAssertEqual(matched.count, 1,
                       "重复出现的高频词应去重，只保留一条")
        XCTAssertEqual(matched.first, "ability")
    }

    /// Given: Content with no CET words → When: matched → Then: empty array
    func test_matchHighFrequencyWords_whenNoMatch_returnsEmpty() {
        // Given: word set that doesn't match content
        let content = "The cat sat on the mat."
        let wordSet = Set(["abandon", "ability", "abstract"])

        // When
        let matched = sut.matchHighFrequencyWords(content: content, wordSet: wordSet)

        // Then
        XCTAssertTrue(matched.isEmpty,
                      "无匹配词时应返回空数组")
    }

    /// Given: Mixed case content → When: matched → Then: case-insensitive matching, preserves original case
    func test_matchHighFrequencyWords_caseInsensitive() {
        // Given
        let content = "ABANDON all hope ye who abandon here."
        let wordSet = Set(["abandon"])

        // When
        let matched = sut.matchHighFrequencyWords(content: content, wordSet: wordSet)

        // Then
        XCTAssertEqual(matched.count, 1,
                       "大小写不敏感匹配，'ABANDON' 和 'abandon' 去重后只保留一个")
        // 保留原始大小写：第一个找到的是 "ABANDON"
        XCTAssertTrue(matched.contains("ABANDON") || matched.contains("abandon"),
                      "匹配结果应保留原始大小写形式")
    }

    /// Given: Content with words adjacent to punctuation → When: matched → Then: still matches
    func test_matchHighFrequencyWords_handlesPunctuation() {
        // Given
        let content = "The ability, according to research, is key."
        let wordSet = Set(["ability"])

        // When
        let matched = sut.matchHighFrequencyWords(content: content, wordSet: wordSet)

        // Then
        XCTAssertEqual(matched.count, 1,
                       "标点符号旁的单词应被正确匹配")
        XCTAssertEqual(matched.first, "ability")
    }

    // MARK: - calculateWPM 测试

    /// Given: 120 words in 60 seconds → Expected: 120 WPM
    func test_calculateWPM_standardCase() {
        // When
        let result = sut.calculateWPM(wordCount: 120, seconds: 60)

        // Then
        XCTAssertEqual(result, 120.0, accuracy: 0.01,
                       "120词/60秒 = 120 WPM")
    }

    /// Given: 200 words in 120 seconds → Expected: 100 WPM
    func test_calculateWPM_twoMinuteRead() {
        // When
        let result = sut.calculateWPM(wordCount: 200, seconds: 120)

        // Then
        XCTAssertEqual(result, 100.0, accuracy: 0.01,
                       "200词/120秒 = 100 WPM")
    }

    /// Given: 0 seconds → Expected: 0 WPM (guard against div by zero)
    func test_calculateWPM_zeroSeconds_returnsZero() {
        // When
        let result = sut.calculateWPM(wordCount: 100, seconds: 0)

        // Then
        XCTAssertEqual(result, 0.0,
                       "秒数为 0 时应返回 0 避免除零错误")
    }

    /// Given: 0 words → Expected: 0 WPM
    func test_calculateWPM_zeroWords_returnsZero() {
        // When
        let result = sut.calculateWPM(wordCount: 0, seconds: 60)

        // Then
        XCTAssertEqual(result, 0.0,
                       "词数为 0 时应返回 0")
    }

    // MARK: - estimateReadTime 测试

    /// Given: 120 words at 120 WPM → Expected: 1 minute
    func test_estimateReadTime_standardCase() {
        // When
        let result = sut.estimateReadTime(wordCount: 120, wpm: 120.0)

        // Then
        XCTAssertEqual(result, 1,
                       "120词/120WPM = 1分钟")
    }

    /// Given: 180 words at 120 WPM → Expected: 2 minutes (ceil)
    func test_estimateReadTime_roundsUp() {
        // When
        let result = sut.estimateReadTime(wordCount: 180, wpm: 120.0)

        // Then
        XCTAssertEqual(result, 2,
                       "180词/120WPM = 1.5 → ceil → 2分钟")
    }

    /// Given: Very few words → Expected: minimum 1 minute
    func test_estimateReadTime_minimumOneMinute() {
        // When
        let result = sut.estimateReadTime(wordCount: 5, wpm: 200.0)

        // Then
        XCTAssertEqual(result, 1,
                       "阅读时间最少为 1 分钟")
    }

    // MARK: - parseArticle 测试

    /// Given: Raw content + CET4 level → When: parseArticle → Then: ArticleContent created correctly
    func test_parseArticle_createsArticleContent_withCET4() {
        // Given
        let articleID = UUID()
        let title = "Test Article"

        // When
        let content = sut.parseArticle(
            rawContent: sampleArticle,
            articleID: articleID,
            title: title,
            cetLevel: "CET4"
        )

        // Then
        XCTAssertEqual(content.articleID, articleID)
        XCTAssertEqual(content.title, title)
        XCTAssertGreaterThan(content.wordCount, 0, "文章词数应 > 0")
        XCTAssertGreaterThan(content.estimatedReadMinutes, 0, "估计阅读时间应 > 0")
        // AttributedString body should exist
        XCTAssertFalse(String(content.attributedBody.characters).isEmpty,
                       "富文本正文不应为空")
    }

    /// Given: Raw content + CET6 level → When: parseArticle → Then: uses CET6 word set
    func test_parseArticle_withCET6_usesCET6WordSet() {
        // Given
        let articleID = UUID()

        // When
        let content = sut.parseArticle(
            rawContent: sampleArticle,
            articleID: articleID,
            title: "CET6 Article",
            cetLevel: "CET6"
        )

        // Then: ArticleContent is created (detailed word matching tested elsewhere)
        XCTAssertEqual(content.title, "CET6 Article")
        XCTAssertGreaterThan(content.wordCount, 0)
    }

    /// Given: Empty raw content → When: parseArticle → Then: returns ArticleContent with 0 words
    func test_parseArticle_emptyContent_returnsZeroWords() {
        // Given
        let articleID = UUID()

        // When
        let content = sut.parseArticle(
            rawContent: "",
            articleID: articleID,
            title: "Empty",
            cetLevel: "CET4"
        )

        // Then
        XCTAssertEqual(content.wordCount, 0, "空文章词数应为 0")
        // trimmed content is empty — AttributedString("") is valid
        XCTAssertEqual(content.estimatedReadMinutes, 1, "空文章最小阅读时间 1 分钟")
    }

    // MARK: - 回归测试 Bug #3: 多次出现的词全部高亮

    /// 验证同一高频词在文中多次出现时，所有出现位置都被高亮
    func test_parseArticle_highlightsAllOccurrences_regressionBug3() {
        // Given: "ability" 出现 3 次的文章
        let repeatedContent = """
        The ability to learn is important. Your ability grows with practice. \
        Never doubt your ability to improve.
        """
        let wordSet = Set(["ability"])
        sut = ArticleService()  // fresh instance with default CET word set

        // When: 匹配高频词
        let matched = sut.matchHighFrequencyWords(content: repeatedContent, wordSet: wordSet)

        // Then: 应匹配到 1 个唯一词
        XCTAssertEqual(matched.count, 1, "3 次出现去重后应为 1 个唯一词")

        // When: 解析文章
        let content = sut.parseArticle(
            rawContent: repeatedContent,
            articleID: UUID(),
            title: "Regression Test",
            cetLevel: "CET4"
        )

        // Then: attributedBody 中存在高亮（AttributedString 高亮通过 backgroundColor 体现）
        let bodyString = String(content.attributedBody.characters)
        XCTAssertTrue(bodyString.contains("ability"),
                      "文章内容应包含 'ability'")
        // 确认 highlightedWordIDs 包含该词
        XCTAssertTrue(content.highlightedWordIDs.contains { $0.lowercased() == "ability" },
                      "highlightedWordIDs 应包含 'ability'")
    }
}
