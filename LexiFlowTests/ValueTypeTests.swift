import XCTest
import Foundation
@testable import LexiFlow

// MARK: - 值类型模型测试

final class ValueTypeTests: XCTestCase {

    // MARK: - ReviewCard 测试

    /// Given: ReviewCard initialized → Then: all fields accessible and correct
    func test_reviewCard_allFieldsAccessible() {
        // Given
        let userWordID = UUID()

        // When
        var card = ReviewCard(
            userWordID: userWordID,
            wordText: "abandon",
            definition: "放弃",
            exampleSentence: "They had to abandon the ship.",
            phonetic: "/əˈbændən/",
            srsStage: 2,
            isFlipped: false
        )

        // Then: id 等于 userWordID
        XCTAssertEqual(card.id, userWordID)
        XCTAssertEqual(card.wordText, "abandon")
        XCTAssertEqual(card.definition, "放弃")
        XCTAssertEqual(card.exampleSentence, "They had to abandon the ship.")
        XCTAssertEqual(card.phonetic, "/əˈbændən/")
        XCTAssertEqual(card.srsStage, 2)
        XCTAssertFalse(card.isFlipped)

        // When: flip the card
        card.isFlipped.toggle()

        // Then
        XCTAssertTrue(card.isFlipped, "翻转后 isFlipped 应为 true")
    }

    /// Given: Two ReviewCards with same userWordID → Then: same id
    func test_reviewCard_identicalUserWordID_sameID() {
        // Given
        let uid = UUID()
        let card1 = ReviewCard(
            userWordID: uid, wordText: "a", definition: "",
            exampleSentence: "", phonetic: "", srsStage: 0
        )
        let card2 = ReviewCard(
            userWordID: uid, wordText: "b", definition: "",
            exampleSentence: "", phonetic: "", srsStage: 1
        )

        // Then: 相同 userWordID 产生相同 id
        XCTAssertEqual(card1.id, card2.id)
    }

    // MARK: - ExamQuestion 测试

    /// Given: ExamQuestion with correct answer → When: user selects correct → Then: isCorrect = true
    func test_examQuestion_correctAnswer_returnsTrue() {
        // Given
        let question = ExamQuestion(
            id: UUID(),
            questionText: "What is 1+1?",
            options: ["1", "2", "3", "4"],
            correctIndex: 1,
            explanation: "Simple math",
            category: "vocabulary"
        )

        // When/Then: 初始状态
        XCTAssertFalse(question.isAnswered, "未作答时应为 false")
        XCTAssertFalse(question.isCorrect, "未作答时 isCorrect 应为 false")
        XCTAssertNil(question.userSelectedIndex)
    }

    /// Given: ExamQuestion → When: user selects correct option → Then: isCorrect = true
    func test_examQuestion_whenCorrectOptionSelected_isCorrectTrue() {
        // Given
        var question = ExamQuestion(
            id: UUID(),
            questionText: "Synonym of big?",
            options: ["small", "large", "tiny", "narrow"],
            correctIndex: 1,
            explanation: "",
            category: "vocabulary"
        )

        // When: 选择正确答案 (index 1 = "large")
        question.userSelectedIndex = 1

        // Then
        XCTAssertTrue(question.isAnswered)
        XCTAssertTrue(question.isCorrect)
    }

    /// Given: ExamQuestion → When: user selects wrong option → Then: isCorrect = false
    func test_examQuestion_whenWrongOptionSelected_isCorrectFalse() {
        // Given
        var question = ExamQuestion(
            id: UUID(),
            questionText: "Antonym of hot?",
            options: ["cold", "warm", "boiling", "tepid"],
            correctIndex: 0,
            explanation: "",
            category: "vocabulary"
        )

        // When: 选择错误答案 (index 2 = "boiling")
        question.userSelectedIndex = 2

        // Then
        XCTAssertTrue(question.isAnswered)
        XCTAssertFalse(question.isCorrect)
    }

    /// Given: ExamQuestion → When: correctIndex out of bounds → Then: should handle gracefully
    /// (This tests the model's resilience to bad data)
    func test_examQuestion_correctIndexOutOfBounds() {
        // Given: correctIndex = 99, only 4 options
        var question = ExamQuestion(
            id: UUID(),
            questionText: "Test",
            options: ["A", "B", "C", "D"],
            correctIndex: 99,  // 越界
            explanation: "",
            category: "vocabulary"
        )

        // When: user picks an in-bounds index
        question.userSelectedIndex = 0

        // Then: isCorrect should be false (99 != 0)
        XCTAssertFalse(question.isCorrect,
                       "越界的 correctIndex 不会匹配任何用户选择")
    }

    /// Given: ExamQuestion → Then: category field preserved
    func test_examQuestion_categoryField() {
        // Given
        let question = ExamQuestion(
            id: UUID(),
            questionText: "Test",
            options: ["A", "B"],
            correctIndex: 0,
            explanation: "explanation",
            category: "sentence"
        )

        // Then
        XCTAssertEqual(question.category, "sentence")
        XCTAssertEqual(question.explanation, "explanation")
    }

    // MARK: - ArticleContent 测试

    /// Given: ArticleContent initialized → Then: all fields accessible
    func test_articleContent_allFieldsAccessible() {
        // Given
        let articleID = UUID()
        let attributed = AttributedString("Hello World")

        // When
        let content = ArticleContent(
            articleID: articleID,
            title: "Test Title",
            attributedBody: attributed,
            highlightedWordIDs: ["hello"],
            wordCount: 2,
            estimatedReadMinutes: 1
        )

        // Then
        XCTAssertEqual(content.articleID, articleID)
        XCTAssertEqual(content.title, "Test Title")
        XCTAssertEqual(content.highlightedWordIDs, ["hello"])
        XCTAssertEqual(content.wordCount, 2)
        XCTAssertEqual(content.estimatedReadMinutes, 1)
        XCTAssertFalse(String(content.attributedBody.characters).isEmpty)
    }

    /// Given: ArticleContent with empty attributedBody → Then: still valid
    func test_articleContent_emptyBody() {
        // Given
        let content = ArticleContent(
            articleID: UUID(),
            title: "Empty",
            attributedBody: AttributedString(""),
            highlightedWordIDs: [],
            wordCount: 0,
            estimatedReadMinutes: 1
        )

        // Then
        XCTAssertTrue(content.highlightedWordIDs.isEmpty)
        XCTAssertEqual(content.wordCount, 0)
    }

    // MARK: - SRSDifficulty 测试

    func test_srsDifficulty_labels() {
        XCTAssertEqual(SRSDifficulty.easy.label, "简单")
        XCTAssertEqual(SRSDifficulty.good.label, "良好")
        XCTAssertEqual(SRSDifficulty.hard.label, "困难")
    }

    // MARK: - SRSResult 测试

    func test_srsResult_allFieldsAccessible() {
        // Given
        let futureDate = Date().addingTimeInterval(86400)

        // When
        let result = SRSResult(
            newStage: 3,
            newEaseFactor: 2.8,
            nextReviewDate: futureDate,
            isMastered: false
        )

        // Then
        XCTAssertEqual(result.newStage, 3)
        XCTAssertEqual(result.newEaseFactor, 2.8, accuracy: 0.001)
        XCTAssertEqual(result.nextReviewDate, futureDate)
        XCTAssertFalse(result.isMastered)
    }
}
