import XCTest
import CoreData
@testable import LexiFlow

// MARK: - ReviewViewModel 测试

final class ReviewViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: ReviewViewModel!
    var persistenceController: PersistenceController!
    var srsService: SRSService!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        sut = ReviewViewModel()
        persistenceController = PersistenceController(inMemory: true)
        srsService = SRSService()
    }

    override func tearDown() {
        sut = nil
        srsService = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func createWordWithUserWord(
        context: NSManagedObjectContext,
        text: String = "abandon",
        definition: String = "放弃",
        srsStage: Int = 0,
        nextReviewDate: Date = Date().addingTimeInterval(-3600),
        isMastered: Bool = false
    ) -> UserWordMO {
        // 创建 WordMO
        let word = WordMO(context: context)
        word.id = UUID()
        word.text = text
        word.phonetic = "/test/"
        word.partOfSpeech = "v."
        word.definition = definition
        word.exampleSentence = "Example for \(text)."
        word.sentenceStructure = ""
        word.cetLevel = "CET4"
        word.frequencyRank = 1

        // 创建 UserWordMO
        let userWord = UserWordMO(context: context)
        userWord.id = UUID()
        userWord.addedAt = Date()
        userWord.srsStage = srsStage
        userWord.nextReviewDate = nextReviewDate
        userWord.easeFactor = AppConstants.defaultEaseFactor
        userWord.reviewCount = 0
        userWord.consecutiveCorrect = 0
        userWord.isMastered = isMastered
        userWord.word = word

        return userWord
    }

    // MARK: - 初始状态测试

    func test_initialState_isIdle() {
        XCTAssertTrue(sut.cardStack.isEmpty)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.totalCards, 0)
        XCTAssertEqual(sut.reviewedCount, 0)
        XCTAssertEqual(sut.sessionState, .idle)
        XCTAssertNil(sut.currentCard)
        XCTAssertEqual(sut.progress, 0)
    }

    // MARK: - loadDueCards 测试

    /// Given: 3 due cards → When: loadDueCards → Then: cardStack populated
    func test_loadDueCards_populatesCardStack() {
        // Given
        let context = persistenceController.viewContext
        for i in 0..<3 {
            _ = createWordWithUserWord(
                context: context,
                text: "word\(i)",
                srsStage: i,
                nextReviewDate: Date().addingTimeInterval(-3600)  // 已到期
            )
        }
        try? context.save()

        // When
        sut.loadDueCards(context: context)

        // Then
        XCTAssertEqual(sut.totalCards, 3)
        XCTAssertEqual(sut.cardStack.count, 3)
        XCTAssertEqual(sut.sessionState, .active)
        XCTAssertNotNil(sut.currentCard)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.reviewedCount, 0)
    }

    /// Given: no due cards → When: loadDueCards → Then: session completed
    func test_loadDueCards_whenNoCards_sessionCompleted() {
        // Given: 无到期卡片
        let context = persistenceController.viewContext

        // When
        sut.loadDueCards(context: context)

        // Then
        XCTAssertEqual(sut.sessionState, .completed, "无卡片时应直接完成")
        XCTAssertTrue(sut.cardStack.isEmpty)
        XCTAssertEqual(sut.totalCards, 0)
    }

    /// Given: mastered cards only → When: loadDueCards → Then: excluded
    func test_loadDueCards_excludesMastered() {
        // Given
        let context = persistenceController.viewContext
        // 已掌握的单词（即使到期也不加载）
        _ = createWordWithUserWord(
            context: context,
            text: "mastered",
            srsStage: 6,
            nextReviewDate: Date().addingTimeInterval(-86400),
            isMastered: true
        )
        try? context.save()

        // When
        sut.loadDueCards(context: context)

        // Then
        XCTAssertEqual(sut.totalCards, 0,
                       "已掌握的卡片不应出现在复习中")
    }

    // MARK: - 卡片翻转测试

    func test_flipCurrentCard_togglesFlipped() {
        // Given
        let context = persistenceController.viewContext
        _ = createWordWithUserWord(context: context)
        try? context.save()
        sut.loadDueCards(context: context)

        // When: 翻转
        sut.flipCurrentCard()

        // Then
        XCTAssertTrue(sut.currentCard?.isFlipped ?? false)

        // When: 再次翻转
        sut.flipCurrentCard()

        // Then
        XCTAssertFalse(sut.currentCard?.isFlipped ?? true)
    }

    // MARK: - rateCard 测试

    /// Given: 1 card → When: rateCard with .good → Then: reviewedCount+1, card advances
    func test_rateCard_good_advancesToNext() {
        // Given
        let context = persistenceController.viewContext
        _ = createWordWithUserWord(context: context, text: "abandon")
        _ = createWordWithUserWord(context: context, text: "ability",
                                     nextReviewDate: Date().addingTimeInterval(-3600))
        try? context.save()
        sut.loadDueCards(context: context)
        XCTAssertEqual(sut.totalCards, 2)

        // When: 评分 .good
        sut.rateCard(.good, context: context)

        // Then
        XCTAssertEqual(sut.reviewedCount, 1)
        XCTAssertEqual(sut.correctCount, 1)
        XCTAssertEqual(sut.incorrectCount, 0)
    }

    /// Given: 1 card → When: rateCard with .hard → Then: incorrectCount+1
    func test_rateCard_hard_incrementsIncorrect() {
        // Given
        let context = persistenceController.viewContext
        _ = createWordWithUserWord(context: context)
        try? context.save()
        sut.loadDueCards(context: context)

        // When: 评分 .hard
        sut.rateCard(.hard, context: context)

        // Then
        XCTAssertEqual(sut.reviewedCount, 1)
        XCTAssertEqual(sut.incorrectCount, 1)
        XCTAssertEqual(sut.correctCount, 0)
    }

    /// Given: last card → When: rateCard → Then: session completed
    func test_rateCard_lastCard_completesSession() {
        // Given
        let context = persistenceController.viewContext
        _ = createWordWithUserWord(context: context)
        try? context.save()
        sut.loadDueCards(context: context)
        XCTAssertEqual(sut.totalCards, 1)

        // When: 评分
        sut.rateCard(.good, context: context)

        // Then
        XCTAssertEqual(sut.sessionState, .completed,
                       "最后一张卡片评分后应完成会话")
        XCTAssertEqual(sut.reviewedCount, 1)
    }

    /// Given: rateCard updates SRS state → Then: UserWord updated in Core Data
    func test_rateCard_updatesSRSInCoreData() {
        // Given
        let context = persistenceController.viewContext
        let userWord = createWordWithUserWord(
            context: context,
            text: "test_word",
            srsStage: 0
        )
        try? context.save()
        let originalStage = userWord.srsStage

        sut.loadDueCards(context: context)

        // When: 评分 .easy
        sut.rateCard(.easy, context: context)

        // Then: Core Data 中的 UserWord 状态被更新
        let updated = try? context.fetch(UserWordMO.fetchRequest()).first
        XCTAssertGreaterThan(updated?.srsStage ?? 0, originalStage,
                             "SRS stage 应该提升")
        XCTAssertEqual(updated?.reviewCount, 1,
                       "reviewCount 应该增加")
    }

    // MARK: - 进度计算测试

    func test_progress_calculation() {
        // Given
        let context = persistenceController.viewContext
        for i in 0..<4 {
            _ = createWordWithUserWord(
                context: context,
                text: "word\(i)",
                nextReviewDate: Date().addingTimeInterval(-3600)
            )
        }
        try? context.save()
        sut.loadDueCards(context: context)

        // When: 评分 2 张
        sut.rateCard(.good, context: context)  // reviewed=1
        sut.rateCard(.good, context: context)  // reviewed=2

        // Then
        XCTAssertEqual(sut.progress, 0.5, accuracy: 0.01,
                       "2/4 = 50%")
    }

    // MARK: - 重置测试

    func test_reset_clearsAllState() {
        // Given
        let context = persistenceController.viewContext
        _ = createWordWithUserWord(context: context)
        try? context.save()
        sut.loadDueCards(context: context)
        sut.rateCard(.good, context: context)

        // When
        sut.reset()

        // Then
        XCTAssertTrue(sut.cardStack.isEmpty)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.totalCards, 0)
        XCTAssertEqual(sut.reviewedCount, 0)
        XCTAssertEqual(sut.correctCount, 0)
        XCTAssertEqual(sut.incorrectCount, 0)
        XCTAssertEqual(sut.sessionState, .idle)
    }

    // MARK: - ReviewCard 转换测试

    func test_loadDueCards_mapsUserWordToReviewCard_correctly() {
        // Given
        let context = persistenceController.viewContext
        _ = createWordWithUserWord(
            context: context,
            text: "abandon",
            definition: "放弃",
            srsStage: 2
        )
        try? context.save()

        // When
        sut.loadDueCards(context: context)

        // Then
        let card = sut.currentCard
        XCTAssertNotNil(card)
        XCTAssertEqual(card?.wordText, "abandon")
        XCTAssertEqual(card?.definition, "放弃")
        XCTAssertEqual(card?.srsStage, 2)
        XCTAssertFalse(card?.isFlipped ?? true)
    }
}
