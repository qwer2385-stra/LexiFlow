import XCTest
import CoreData
@testable import LexiFlow

// MARK: - SRS 服务单元测试

final class SRSServiceTests: XCTestCase {

    // MARK: - Properties

    var sut: SRSService!
    var persistenceController: PersistenceController!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        sut = SRSService()
        persistenceController = PersistenceController(inMemory: true)
    }

    override func tearDown() {
        sut = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Stage → Interval 映射测试

    /// Given: SRS stage 0 → Expected: 1 day interval
    func test_stageInterval_stage0_returnsOneDay() {
        // When
        let result = sut.calculateNextReview(
            currentStage: 0, difficulty: .good, easeFactor: 2.5
        )
        // Then
        let expectedInterval = AppConstants.srsIntervals[0]!  // 86400秒 = 1天
        let actualInterval = result.nextReviewDate.timeIntervalSinceNow
        // 允许1秒误差（执行时间差）
        XCTAssertEqual(actualInterval, expectedInterval, accuracy: 1.0,
                       "Stage 0 应映射到 1 天间隔")
    }

    /// Given: SRS stage 1 → Expected: 3 day interval
    func test_stageInterval_stage1_returnsThreeDays() {
        let result = sut.calculateNextReview(
            currentStage: 1, difficulty: .good, easeFactor: 2.5
        )
        let expectedInterval = AppConstants.srsIntervals[1]!  // 259200秒 = 3天
        let actualInterval = result.nextReviewDate.timeIntervalSinceNow
        XCTAssertEqual(actualInterval, expectedInterval, accuracy: 1.0,
                       "Stage 1 应映射到 3 天间隔")
    }

    /// Given: SRS stage 2 → Expected: 7 day interval
    func test_stageInterval_stage2_returnsSevenDays() {
        let result = sut.calculateNextReview(
            currentStage: 2, difficulty: .good, easeFactor: 2.5
        )
        let expectedInterval = AppConstants.srsIntervals[2]!  // 604800秒 = 7天
        let actualInterval = result.nextReviewDate.timeIntervalSinceNow
        XCTAssertEqual(actualInterval, expectedInterval, accuracy: 1.0,
                       "Stage 2 应映射到 7 天间隔")
    }

    /// Given: SRS stage 3 → Expected: 15 day interval
    func test_stageInterval_stage3_returnsFifteenDays() {
        let result = sut.calculateNextReview(
            currentStage: 3, difficulty: .good, easeFactor: 2.5
        )
        let expectedInterval = AppConstants.srsIntervals[3]!  // 1296000秒 = 15天
        let actualInterval = result.nextReviewDate.timeIntervalSinceNow
        XCTAssertEqual(actualInterval, expectedInterval, accuracy: 1.0,
                       "Stage 3 应映射到 15 天间隔")
    }

    /// Given: SRS stage 4 → Expected: 30 day interval
    func test_stageInterval_stage4_returnsThirtyDays() {
        let result = sut.calculateNextReview(
            currentStage: 4, difficulty: .good, easeFactor: 2.5
        )
        let expectedInterval = AppConstants.srsIntervals[4]!  // 2592000秒 = 30天
        let actualInterval = result.nextReviewDate.timeIntervalSinceNow
        XCTAssertEqual(actualInterval, expectedInterval, accuracy: 1.0,
                       "Stage 4 应映射到 30 天间隔")
    }

    /// Given: SRS stage 5+ → Expected: 60 day default interval
    func test_stageInterval_stage5AndAbove_returnsSixtyDays() {
        // When: stage = 5
        let result5 = sut.calculateNextReview(
            currentStage: 5, difficulty: .good, easeFactor: 2.5
        )
        let expectedInterval = AppConstants.defaultSRSInterval  // 5184000秒 = 60天
        let actual5 = result5.nextReviewDate.timeIntervalSinceNow
        XCTAssertEqual(actual5, expectedInterval, accuracy: 1.0,
                       "Stage 5 应映射到 60 天默认间隔")

        // When: stage = 10（超出映射范围）
        let result10 = sut.calculateNextReview(
            currentStage: 10, difficulty: .good, easeFactor: 2.5
        )
        let actual10 = result10.nextReviewDate.timeIntervalSinceNow
        XCTAssertEqual(actual10, expectedInterval, accuracy: 1.0,
                       "Stage 10 应使用 60 天默认间隔")
    }

    // MARK: - Difficulty 影响测试

    /// Given: .easy difficulty → Then: stage+1, ef×1.3
    func test_difficulty_easy_incrementsStageAndMultipliesEF() {
        // Given
        let currentStage = 2
        let currentEF = 2.5

        // When
        let result = sut.calculateNextReview(
            currentStage: currentStage, difficulty: .easy, easeFactor: currentEF
        )

        // Then
        XCTAssertEqual(result.newStage, 3,
                       ".easy 应使 stage+1（2→3）")
        XCTAssertEqual(result.newEaseFactor, 2.5 * 1.3, accuracy: 0.001,
                       ".easy 应使 EF×1.3")
        XCTAssertFalse(result.isMastered,
                        "Stage 3 不应标记为已掌握")
    }

    /// Given: .good difficulty → Then: stage+1, ef unchanged
    func test_difficulty_good_incrementsStageAndKeepsEF() {
        // Given
        let currentStage = 1
        let currentEF = 2.0

        // When
        let result = sut.calculateNextReview(
            currentStage: currentStage, difficulty: .good, easeFactor: currentEF
        )

        // Then
        XCTAssertEqual(result.newStage, 2,
                       ".good 应使 stage+1（1→2）")
        XCTAssertEqual(result.newEaseFactor, 2.0, accuracy: 0.001,
                       ".good 应保持 EF 不变")
        XCTAssertFalse(result.isMastered,
                        "Stage 2 不应标记为已掌握")
    }

    /// Given: .hard difficulty → Then: stage-1(min 0), ef×0.85(min 1.3)
    func test_difficulty_hard_decrementsStageAndReducesEF() {
        // Given
        let currentStage = 3
        let currentEF = 2.5

        // When
        let result = sut.calculateNextReview(
            currentStage: currentStage, difficulty: .hard, easeFactor: currentEF
        )

        // Then
        XCTAssertEqual(result.newStage, 2,
                       ".hard 应使 stage-1（3→2）")
        XCTAssertEqual(result.newEaseFactor, 2.5 * 0.85, accuracy: 0.001,
                       ".hard 应使 EF×0.85")
    }

    // MARK: - EaseFactor 边界测试

    /// Given: EF already at minimum → .hard should not go below 1.3
    func test_easeFactor_neverBelowMinimum() {
        // Given: EF at exactly 1.3 (minimum)
        let minEF: Double = 1.3

        // When: .hard with EF=1.3
        let result = sut.calculateNextReview(
            currentStage: 2, difficulty: .hard, easeFactor: minEF
        )

        // Then: EF should stay at 1.3 (not go to 1.3*0.85=1.105)
        XCTAssertGreaterThanOrEqual(result.newEaseFactor, AppConstants.minEaseFactor,
                                     "EF 不应低于最小值 1.3")
        XCTAssertEqual(result.newEaseFactor, AppConstants.minEaseFactor, accuracy: 0.001,
                       "EF 应被钳制在 1.3")

        // When: .hard with EF=1.5
        let result2 = sut.calculateNextReview(
            currentStage: 2, difficulty: .hard, easeFactor: 1.5
        )
        XCTAssertEqual(result2.newEaseFactor, max(AppConstants.minEaseFactor, 1.5 * 0.85),
                       accuracy: 0.001, "EF=1.5 *.85=1.275 应被钳制到 1.3")
    }

    /// Given: .hard at stage 0 → stage should stay at 0 (not go negative)
    func test_stage_neverBelowZero() {
        // When: .hard at stage 0
        let result = sut.calculateNextReview(
            currentStage: 0, difficulty: .hard, easeFactor: 2.5
        )

        // Then: stage stays at 0
        XCTAssertEqual(result.newStage, 0,
                       "Stage 不应低于 0")
    }

    // MARK: - Mastered 判定测试

    /// Given: stage reaches 6 → isMastered = true
    func test_isMastered_whenStageReachesSix() {
        // When: .easy at stage 5
        let result = sut.calculateNextReview(
            currentStage: 5, difficulty: .easy, easeFactor: 2.5
        )

        // Then
        XCTAssertEqual(result.newStage, 6,
                       "Stage 应从 5 升到 6")
        XCTAssertTrue(result.isMastered,
                      "Stage ≥ 6 应标记为已掌握")
    }

    /// Given: stage below 6 → isMastered = false
    func test_isMastered_falseWhenStageBelowSix() {
        // When: .easy at stage 4
        let result = sut.calculateNextReview(
            currentStage: 4, difficulty: .easy, easeFactor: 2.5
        )

        // Then
        XCTAssertEqual(result.newStage, 5)
        XCTAssertFalse(result.isMastered,
                        "Stage < 6 不应标记为已掌握")
    }

    // MARK: - isDueForReview 测试

    /// Given: UserWord with past nextReviewDate → should be due
    func test_isDueForReview_whenDateIsPast_returnsTrue() {
        let context = persistenceController.viewContext
        let userWord = UserWordMO(context: context)
        userWord.id = UUID()
        userWord.addedAt = Date()
        userWord.srsStage = 0
        userWord.nextReviewDate = Date().addingTimeInterval(-3600)  // 1小时前
        userWord.easeFactor = 2.5
        userWord.reviewCount = 0
        userWord.consecutiveCorrect = 0
        userWord.isMastered = false

        // When
        let isDue = sut.isDueForReview(userWord)

        // Then
        XCTAssertTrue(isDue, "过期的卡片应该被标记为待复习")
    }

    /// Given: UserWord with future nextReviewDate → should NOT be due
    func test_isDueForReview_whenDateIsFuture_returnsFalse() {
        let context = persistenceController.viewContext
        let userWord = UserWordMO(context: context)
        userWord.id = UUID()
        userWord.addedAt = Date()
        userWord.srsStage = 1
        userWord.nextReviewDate = Date().addingTimeInterval(86400)  // 明天
        userWord.easeFactor = 2.5
        userWord.reviewCount = 1
        userWord.consecutiveCorrect = 1
        userWord.isMastered = false

        // When
        let isDue = sut.isDueForReview(userWord)

        // Then
        XCTAssertFalse(isDue, "未来的卡片不应该被标记为待复习")
    }

    /// Given: Mastered word → always NOT due
    func test_isDueForReview_whenMastered_returnsFalse() {
        let context = persistenceController.viewContext
        let userWord = UserWordMO(context: context)
        userWord.id = UUID()
        userWord.addedAt = Date()
        userWord.srsStage = 6
        userWord.nextReviewDate = Date().addingTimeInterval(-86400)  // 昨天
        userWord.easeFactor = 2.5
        userWord.reviewCount = 6
        userWord.consecutiveCorrect = 6
        userWord.isMastered = true

        // When
        let isDue = sut.isDueForReview(userWord)

        // Then
        XCTAssertFalse(isDue, "已掌握的卡片不应再进入复习")
    }

    // MARK: - applyReview 测试

    /// Given: a UserWord → When: applyReview with .good → Then: SRS state updated
    func test_applyReview_good_updatesSRSState() {
        let context = persistenceController.viewContext
        let userWord = UserWordMO(context: context)
        userWord.id = UUID()
        userWord.addedAt = Date()
        userWord.srsStage = 0
        userWord.nextReviewDate = Date()
        userWord.easeFactor = 2.5
        userWord.reviewCount = 0
        userWord.consecutiveCorrect = 0
        userWord.isMastered = false

        let originalReviewCount = userWord.reviewCount

        // When
        sut.applyReview(userWord: userWord, difficulty: .good, context: context)

        // Then
        XCTAssertEqual(userWord.srsStage, 1, "Stage 应从 0 升到 1")
        XCTAssertEqual(userWord.easeFactor, 2.5, accuracy: 0.001, ".good 应保持 EF")
        XCTAssertGreaterThan(userWord.nextReviewDate, Date(), "下次复习应在未来")
        XCTAssertEqual(userWord.reviewCount, originalReviewCount + 1, "复习次数+1")
        XCTAssertEqual(userWord.consecutiveCorrect, 1, "连续正确次数应为 1")
    }

    /// Given: a UserWord → When: applyReview with .hard → Then: consecutiveCorrect reset
    func test_applyReview_hard_resetsConsecutiveCorrect() {
        let context = persistenceController.viewContext
        let userWord = UserWordMO(context: context)
        userWord.id = UUID()
        userWord.addedAt = Date()
        userWord.srsStage = 2
        userWord.nextReviewDate = Date()
        userWord.easeFactor = 2.5
        userWord.reviewCount = 5
        userWord.consecutiveCorrect = 3  // 之前连续正确3次
        userWord.isMastered = false

        // When
        sut.applyReview(userWord: userWord, difficulty: .hard, context: context)

        // Then
        XCTAssertEqual(userWord.consecutiveCorrect, 0,
                       ".hard 应重置连续正确次数")
    }

    // MARK: - getDueCards 测试

    /// Given: due and non-due cards → When: getDueCards → Then: only due cards returned
    func test_getDueCards_returnsOnlyDueCards() {
        let context = persistenceController.viewContext

        // 创建到期卡片
        let dueWord = UserWordMO(context: context)
        dueWord.id = UUID()
        dueWord.addedAt = Date().addingTimeInterval(-86400 * 2)
        dueWord.srsStage = 1
        dueWord.nextReviewDate = Date().addingTimeInterval(-3600)  // 1小时前 → 到期
        dueWord.easeFactor = 2.5
        dueWord.reviewCount = 1
        dueWord.consecutiveCorrect = 1
        dueWord.isMastered = false

        // 创建未到期卡片
        let futureWord = UserWordMO(context: context)
        futureWord.id = UUID()
        futureWord.addedAt = Date()
        futureWord.srsStage = 2
        futureWord.nextReviewDate = Date().addingTimeInterval(86400 * 3)  // 3天后
        futureWord.easeFactor = 2.5
        futureWord.reviewCount = 2
        futureWord.consecutiveCorrect = 2
        futureWord.isMastered = false

        // 创建已掌握卡片（即使到期也不返回）
        let masteredWord = UserWordMO(context: context)
        masteredWord.id = UUID()
        masteredWord.addedAt = Date().addingTimeInterval(-86400 * 10)
        masteredWord.srsStage = 6
        masteredWord.nextReviewDate = Date().addingTimeInterval(-86400)  // 昨天
        masteredWord.easeFactor = 2.5
        masteredWord.reviewCount = 6
        masteredWord.consecutiveCorrect = 6
        masteredWord.isMastered = true

        try? context.save()

        // When
        let dueCards = sut.getDueCards(context: context)

        // Then
        XCTAssertEqual(dueCards.count, 1, "应只返回 1 张到期卡片（已掌握的排除）")
        XCTAssertEqual(dueCards.first?.id, dueWord.id, "返回的应为到期卡片")
    }

    /// Given: no due cards → When: getDueCards → Then: empty array
    func test_getDueCards_whenNoneDue_returnsEmpty() {
        let context = persistenceController.viewContext

        let futureWord = UserWordMO(context: context)
        futureWord.id = UUID()
        futureWord.addedAt = Date()
        futureWord.srsStage = 1
        futureWord.nextReviewDate = Date().addingTimeInterval(86400 * 7)  // 7天后
        futureWord.easeFactor = 2.5
        futureWord.reviewCount = 1
        futureWord.consecutiveCorrect = 1
        futureWord.isMastered = false

        try? context.save()

        // When
        let dueCards = sut.getDueCards(context: context)

        // Then
        XCTAssertTrue(dueCards.isEmpty, "无到期卡片应返回空数组")
    }

    // MARK: - getDueCount 测试

    func test_getDueCount_returnsCorrectCount() {
        let context = persistenceController.viewContext

        // 创建 3 张到期卡片
        for i in 0..<3 {
            let word = UserWordMO(context: context)
            word.id = UUID()
            word.addedAt = Date().addingTimeInterval(Double(-i - 1) * 86400)
            word.srsStage = i
            word.nextReviewDate = Date().addingTimeInterval(-3600)
            word.easeFactor = 2.5
            word.reviewCount = i
            word.consecutiveCorrect = i
            word.isMastered = false
        }

        try? context.save()

        // When
        let count = sut.getDueCount(context: context)

        // Then
        XCTAssertEqual(count, 3, "应返回到期卡片数量为 3")
    }
}
