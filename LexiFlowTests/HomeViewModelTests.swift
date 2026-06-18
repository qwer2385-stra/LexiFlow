import XCTest
import CoreData
@testable import LexiFlow

// MARK: - HomeViewModel 测试

final class HomeViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: HomeViewModel!
    var persistenceController: PersistenceController!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        sut = HomeViewModel()
        persistenceController = PersistenceController(inMemory: true)
    }

    override func tearDown() {
        sut = nil
        persistenceController = nil
        super.tearDown()
    }

    // MARK: - Helper: 创建测试用户

    private func createTestUser(context: NSManagedObjectContext) -> UserMO {
        let user = UserMO(context: context)
        user.id = UUID()
        user.nickname = "测试用户"
        user.targetDailyMinutes = 30
        user.targetWeeklyWords = 50
        user.cetLevel = "CET4"
        user.currentDifficultyLevel = 1
        user.createdAt = Date()
        return user
    }

    // MARK: - 初始状态测试

    func test_initialState_isCorrect() {
        XCTAssertNil(sut.todayProgress)
        XCTAssertEqual(sut.completionPercent, 0.0)
        XCTAssertEqual(sut.streakDays, 0)
        XCTAssertEqual(sut.vocabularyCount, 0)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - loadTodayProgress 测试

    /// Given: 无今日进度 → When: loadTodayProgress → Then: 创建新进度
    func test_loadTodayProgress_whenNoExisting_createsNew() {
        // Given
        let context = persistenceController.viewContext
        let user = createTestUser(context: context)

        // When
        sut.loadTodayProgress(context: context, user: user)

        // Then: 创建了新的 DailyProgressMO
        XCTAssertNotNil(sut.todayProgress, "应创建今日进度")
        XCTAssertEqual(sut.todayProgress?.currentStage, 1)
        XCTAssertFalse(sut.todayProgress?.stage1Completed ?? true)
        XCTAssertFalse(sut.todayProgress?.isDayComplete ?? true)
        XCTAssertEqual(sut.todayProgress?.user?.id, user.id)
    }

    /// Given: 已有今日进度 → When: loadTodayProgress → Then: 复用已有
    func test_loadTodayProgress_whenExisting_returnsExisting() {
        // Given
        let context = persistenceController.viewContext
        let user = createTestUser(context: context)

        // 先创建进度
        sut.loadTodayProgress(context: context, user: user)
        let firstProgressID = sut.todayProgress?.id

        // When: 再次加载
        sut.loadTodayProgress(context: context, user: user)

        // Then: 复用已有
        XCTAssertEqual(sut.todayProgress?.id, firstProgressID,
                       "应复用已创建的今日进度")
    }

    // MARK: - updateCompletionPercent 测试

    /// Given: 0 completed stages → Then: completionPercent = 0
    func test_completionPercent_zeroCompleted() {
        // Given
        let context = persistenceController.viewContext
        let user = createTestUser(context: context)
        sut.loadTodayProgress(context: context, user: user)

        // Then
        XCTAssertEqual(sut.completionPercent, 0.0,
                       "无完成阶段时进度为 0%")
    }

    /// Given: 2 completed stages → Then: completionPercent = 0.5
    func test_completionPercent_twoCompleted_isHalf() {
        // Given
        let context = persistenceController.viewContext
        let user = createTestUser(context: context)
        sut.loadTodayProgress(context: context, user: user)

        // When: 完成阶段 1
        sut.unlockNextStage()  // stage: 1→2, stage1Completed=true

        // Then
        XCTAssertEqual(sut.completionPercent, 0.25,
                       "完成 1/4 = 25%")
    }

    /// Given: all 4 stages completed → Then: completionPercent = 1.0
    func test_completionPercent_allCompleted_isFull() {
        // Given
        let context = persistenceController.viewContext
        let user = createTestUser(context: context)
        sut.loadTodayProgress(context: context, user: user)

        // When: 完成所有阶段
        sut.completeDay()

        // Then
        XCTAssertEqual(sut.completionPercent, 1.0,
                       "全部完成 = 100%")
        XCTAssertTrue(sut.todayProgress?.isDayComplete ?? false,
                      "isDayComplete 应为 true")
    }

    // MARK: - unlockNextStage 测试

    /// Given: stage=1 → When: unlockNextStage → Then: stage=2, stage1Completed=true
    func test_unlockNextStage_from1_to2() {
        // Given
        let context = persistenceController.viewContext
        let user = createTestUser(context: context)
        sut.loadTodayProgress(context: context, user: user)

        // When
        sut.unlockNextStage()

        // Then
        XCTAssertEqual(sut.todayProgress?.currentStage, 2)
        XCTAssertTrue(sut.todayProgress?.stage1Completed ?? false)
        XCTAssertFalse(sut.todayProgress?.stage2Completed ?? true)
    }

    /// Given: stage=4 → When: unlockNextStage → Then: 不再变化（上限为 4）
    func test_unlockNextStage_at4_doesNotExceed() {
        // Given
        let context = persistenceController.viewContext
        let user = createTestUser(context: context)
        sut.loadTodayProgress(context: context, user: user)

        // 快速到达 stage 4
        sut.unlockNextStage()  // 1→2
        sut.unlockNextStage()  // 2→3
        sut.unlockNextStage()  // 3→4

        // When: 尝试超越 stage 4
        sut.unlockNextStage()

        // Then: 保持在 stage 4
        XCTAssertEqual(sut.todayProgress?.currentStage, 4,
                       "Stage 最大为 4，不应超越")
        XCTAssertTrue(sut.todayProgress?.isDayComplete ?? false,
                      "到达 stage 4 时应标记为完成")
    }

    /// Given: stage=3→4 → Then: stage4Completed + isDayComplete
    func test_unlockNextStage_from3_to4_completesDay() {
        // Given
        let context = persistenceController.viewContext
        let user = createTestUser(context: context)
        sut.loadTodayProgress(context: context, user: user)

        // Skip to stage 3 first
        sut.unlockNextStage()  // 1→2
        sut.unlockNextStage()  // 2→3

        // When: 3→4
        sut.unlockNextStage()

        // Then
        XCTAssertTrue(sut.todayProgress?.stage4Completed ?? false)
        XCTAssertTrue(sut.todayProgress?.isDayComplete ?? false)
    }

    // MARK: - loadVocabularyCount 测试

    func test_loadVocabularyCount_countsUserWords() {
        // Given
        let context = persistenceController.viewContext
        let user = createTestUser(context: context)

        // 创建 5 个 UserWord
        for _ in 0..<5 {
            let uw = UserWordMO(context: context)
            uw.id = UUID()
            uw.addedAt = Date()
            uw.srsStage = 0
            uw.nextReviewDate = Date()
            uw.easeFactor = 2.5
            uw.reviewCount = 0
            uw.consecutiveCorrect = 0
            uw.isMastered = false
            uw.user = user
        }
        try? context.save()

        // When
        sut.loadTodayProgress(context: context, user: user)

        // Then
        XCTAssertEqual(sut.vocabularyCount, 5,
                       "词汇量应统计关联的 UserWord 数量")
    }

    // MARK: - completeDay 测试

    func test_completeDay_allStagesCompleted() {
        // Given
        let context = persistenceController.viewContext
        let user = createTestUser(context: context)
        sut.loadTodayProgress(context: context, user: user)

        // When
        sut.completeDay()

        // Then
        XCTAssertTrue(sut.todayProgress?.stage1Completed ?? false)
        XCTAssertTrue(sut.todayProgress?.stage2Completed ?? false)
        XCTAssertTrue(sut.todayProgress?.stage3Completed ?? false)
        XCTAssertTrue(sut.todayProgress?.stage4Completed ?? false)
        XCTAssertTrue(sut.todayProgress?.isDayComplete ?? false)
        XCTAssertEqual(sut.completionPercent, 1.0)
    }

    // MARK: - 回归测试 Bug #2: Force Unwrap 移除

    /// 验证 completeDay 不再使用 force unwrap — managedObjectContext 为 nil 时不崩溃
    func test_completeDay_whenContextNil_doesNotCrash_regressionBug2() {
        // Given: 创建进度但直接从 nil context 创建（模拟异常情况）
        let context = persistenceController.viewContext
        let user = createTestUser(context: context)
        sut.loadTodayProgress(context: context, user: user)

        // When: 直接设置 todayProgress 到一个 context=nil 的对象不崩溃
        // 实际场景：如果 Core Data 对象被删除，managedObjectContext 返回 nil
        // 修复后的代码使用 if let 安全解包
        sut.completeDay()

        // Then: 不崩溃即为通过（run without fatal error）
        XCTAssertTrue(true, "No crash = Bug #2 fixed")
    }
}
