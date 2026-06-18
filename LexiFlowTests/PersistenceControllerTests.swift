import XCTest
import CoreData
@testable import LexiFlow

// MARK: - Core Data 持久化控制器测试

final class PersistenceControllerTests: XCTestCase {

    // MARK: - Properties

    var sut: PersistenceController!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        // 使用内存存储，避免污染磁盘
        sut = PersistenceController(inMemory: true)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - 初始化测试

    /// Given: inMemory=true → Then: 使用内存存储
    func test_init_withMemoryStore_createsContainer() {
        // Then
        XCTAssertNotNil(sut.container,
                        "PersistenceController 应成功创建 NSPersistentContainer")
        XCTAssertNotNil(sut.viewContext,
                        "viewContext 应可访问")
    }

    /// Given: 预览实例 → Then: 返回含预览数据的控制器
    func test_preview_instance_hasPopulatedData() {
        // When
        let preview = PersistenceController.preview

        // Then: 验证用户存在
        let userRequest = UserMO.fetchRequest()
        let users = try? preview.viewContext.fetch(userRequest)
        XCTAssertNotNil(users)
        XCTAssertFalse(users?.isEmpty ?? true,
                       "Preview 实例应包含用户数据")
    }

    // MARK: - 7 个 Entity 创建与关系测试

    /// Given: viewContext → When: 创建 UserMO → Then: 属性正确
    func test_createUserMO_allAttributesSet() {
        // Given
        let context = sut.viewContext

        // When
        let user = UserMO(context: context)
        user.id = UUID()
        user.nickname = "测试用户"
        user.targetDailyMinutes = 30
        user.targetWeeklyWords = 50
        user.cetLevel = "CET4"
        user.currentDifficultyLevel = 1
        user.createdAt = Date()

        // Then
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.nickname, "测试用户")
        XCTAssertEqual(user.targetDailyMinutes, 30)
        XCTAssertEqual(user.cetLevel, "CET4")
    }

    /// Given: viewContext → When: 创建 ArticleMO → Then: 属性正确
    func test_createArticleMO_allAttributesSet() {
        // Given
        let context = sut.viewContext

        // When
        let article = ArticleMO(context: context)
        article.id = UUID()
        article.title = "Test Article"
        article.rawContent = "This is a test article content."
        article.wordCount = 7
        article.difficultyLevel = 2
        article.source = "Test Source"
        article.publishDate = Date()
        article.isRead = false

        // Then
        XCTAssertEqual(article.title, "Test Article")
        XCTAssertEqual(article.wordCount, 7)
        XCTAssertFalse(article.isRead)
    }

    /// Given: viewContext → When: 创建 WordMO → Then: 属性正确
    func test_createWordMO_allAttributesSet() {
        // Given
        let context = sut.viewContext

        // When
        let word = WordMO(context: context)
        word.id = UUID()
        word.text = "abandon"
        word.phonetic = "/əˈbændən/"
        word.partOfSpeech = "v."
        word.definition = "放弃"
        word.exampleSentence = "They had to abandon the ship."
        word.sentenceStructure = "主语[They] 谓语[abandon]"
        word.cetLevel = "CET4"
        word.frequencyRank = 1

        // Then
        XCTAssertEqual(word.text, "abandon")
        XCTAssertEqual(word.cetLevel, "CET4")
        XCTAssertEqual(word.frequencyRank, 1)
    }

    /// Given: viewContext → When: 创建 UserWordMO with relationships → Then: 关系正确
    func test_createUserWordMO_relationshipsSet() {
        // Given
        let context = sut.viewContext
        let user = UserMO(context: context)
        user.id = UUID()
        user.nickname = "Test"
        user.targetDailyMinutes = 30
        user.targetWeeklyWords = 50
        user.cetLevel = "CET4"
        user.currentDifficultyLevel = 1
        user.createdAt = Date()

        let word = WordMO(context: context)
        word.id = UUID()
        word.text = "test"
        word.phonetic = "/test/"
        word.partOfSpeech = "n."
        word.definition = "测试"
        word.exampleSentence = "This is a test."
        word.sentenceStructure = ""
        word.cetLevel = "CET4"
        word.frequencyRank = 1

        // When
        let userWord = UserWordMO(context: context)
        userWord.id = UUID()
        userWord.addedAt = Date()
        userWord.srsStage = 0
        userWord.nextReviewDate = Date()
        userWord.easeFactor = AppConstants.defaultEaseFactor
        userWord.reviewCount = 0
        userWord.consecutiveCorrect = 0
        userWord.isMastered = false
        userWord.user = user
        userWord.word = word

        // Then
        XCTAssertNotNil(userWord.user, "UserWord 应关联到 User")
        XCTAssertNotNil(userWord.word, "UserWord 应关联到 Word")
        XCTAssertEqual(userWord.user?.id, user.id)
        XCTAssertEqual(userWord.word?.text, "test")
    }

    /// Given: viewContext → When: 创建 DailyProgressMO → Then: 阶段状态正确
    func test_createDailyProgressMO_stageStateCorrect() {
        // Given
        let context = sut.viewContext

        // When
        let progress = DailyProgressMO(context: context)
        progress.id = UUID()
        progress.date = Date().startOfDay
        progress.currentStage = 1
        progress.stage1Completed = false
        progress.stage2Completed = false
        progress.stage3Completed = false
        progress.stage4Completed = false
        progress.isDayComplete = false
        progress.totalDurationSeconds = 0

        // Then
        XCTAssertEqual(progress.currentStage, 1)
        XCTAssertFalse(progress.isDayComplete)
        XCTAssertEqual(progress.totalDurationSeconds, 0)
    }

    /// Given: viewContext → When: 创建 LearningRecordMO → Then: 属性正确
    func test_createLearningRecordMO_allAttributesSet() {
        // Given
        let context = sut.viewContext

        // When
        let record = LearningRecordMO(context: context)
        record.id = UUID()
        record.date = Date()
        record.stage = 1
        record.stageName = "新闻输入"
        record.durationSeconds = 600
        record.wpm = 135.0
        record.comprehensionRate = 0.85

        // Then
        XCTAssertEqual(record.stage, 1)
        XCTAssertEqual(record.wpm, 135.0, accuracy: 0.01)
        XCTAssertEqual(record.comprehensionRate, 0.85, accuracy: 0.01)
    }

    /// Given: viewContext → When: 创建 ExamAttemptMO → Then: 属性正确
    func test_createExamAttemptMO_allAttributesSet() {
        // Given
        let context = sut.viewContext

        // When
        let exam = ExamAttemptMO(context: context)
        exam.id = UUID()
        exam.date = Date()
        exam.totalQuestions = 10
        exam.correctCount = 7
        exam.score = 70.0
        exam.timeUsedSeconds = 720
        exam.questionResultsJSON = "[]"
        exam.errorCategoriesJSON = "[]"

        // Then
        XCTAssertEqual(exam.totalQuestions, 10)
        XCTAssertEqual(exam.correctCount, 7)
        XCTAssertEqual(exam.score, 70.0, accuracy: 0.01)
    }

    // MARK: - CRUD 操作测试

    /// Given: UserMO created → When: saved then fetched → Then: data persists
    func test_saveAndFetch_user_persistsCorrectly() {
        // Given
        let context = sut.viewContext
        let userID = UUID()

        let user = UserMO(context: context)
        user.id = userID
        user.nickname = "CRUD测试"
        user.targetDailyMinutes = 45
        user.targetWeeklyWords = 60
        user.cetLevel = "CET6"
        user.currentDifficultyLevel = 3
        user.createdAt = Date()

        // When: 保存
        sut.save()

        // Then: 取出验证
        let request = UserMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userID as CVarArg)
        let results = try? context.fetch(request)

        XCTAssertNotNil(results)
        XCTAssertEqual(results?.count, 1)
        XCTAssertEqual(results?.first?.nickname, "CRUD测试")
        XCTAssertEqual(results?.first?.targetDailyMinutes, 45)
        XCTAssertEqual(results?.first?.cetLevel, "CET6")
    }

    /// Given: ArticleMO → When: update isRead → Then: change persists
    func test_update_article_isRead_persists() {
        // Given
        let context = sut.viewContext
        let articleID = UUID()

        let article = ArticleMO(context: context)
        article.id = articleID
        article.title = "Update Test"
        article.rawContent = "Content"
        article.wordCount = 1
        article.difficultyLevel = 1
        article.source = ""
        article.publishDate = Date()
        article.isRead = false
        sut.save()

        // When: 更新
        article.isRead = true
        sut.save()

        // Then
        let request = ArticleMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", articleID as CVarArg)
        let results = try? context.fetch(request)
        XCTAssertTrue(results?.first?.isRead ?? false,
                      "更新后的 isRead 应为 true")
    }

    /// Given: Multiple UserWords → When: delete one → Then: count reduces
    func test_delete_userWord_countReduces() {
        // Given
        let context = sut.viewContext

        let uw1 = UserWordMO(context: context)
        uw1.id = UUID()
        uw1.addedAt = Date()
        uw1.srsStage = 0
        uw1.nextReviewDate = Date()
        uw1.easeFactor = 2.5
        uw1.reviewCount = 0
        uw1.consecutiveCorrect = 0
        uw1.isMastered = false

        let uw2 = UserWordMO(context: context)
        uw2.id = UUID()
        uw2.addedAt = Date()
        uw2.srsStage = 1
        uw2.nextReviewDate = Date()
        uw2.easeFactor = 2.5
        uw2.reviewCount = 1
        uw2.consecutiveCorrect = 1
        uw2.isMastered = false

        sut.save()

        let initialRequest = UserWordMO.fetchRequest()
        let initialCount = (try? context.count(for: initialRequest)) ?? 0
        XCTAssertEqual(initialCount, 2)

        // When: 删除一个
        context.delete(uw1)
        sut.save()

        // Then
        let finalCount = (try? context.count(for: UserWordMO.fetchRequest())) ?? 0
        XCTAssertEqual(finalCount, 1,
                       "删除后应只剩 1 条记录")
    }

    // MARK: - 关系级联测试

    /// Given: User → UserWords (1:N) → When: delete User → Then: UserWords cascade deleted
    func test_cascadeDelete_user_deletesUserWords() {
        // Given
        let context = sut.viewContext

        let user = UserMO(context: context)
        user.id = UUID()
        user.nickname = "级联测试"
        user.targetDailyMinutes = 30
        user.targetWeeklyWords = 50
        user.cetLevel = "CET4"
        user.currentDifficultyLevel = 1
        user.createdAt = Date()

        for _ in 0..<3 {
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
        sut.save()

        let uwBefore = (try? context.count(for: UserWordMO.fetchRequest())) ?? 0
        XCTAssertEqual(uwBefore, 3)

        // When: 删除用户
        context.delete(user)
        sut.save()

        // Then: UserWords 应被级联删除
        let uwAfter = (try? context.count(for: UserWordMO.fetchRequest())) ?? 0
        XCTAssertEqual(uwAfter, 0,
                       "删除 User 后，关联的 UserWord 应被级联删除")
    }

    // MARK: - SRS 默认值测试

    /// Given: new UserWordMO → Then: default EF = 2.5
    func test_userWord_defaultEaseFactor_isCorrect() {
        // Given
        let context = sut.viewContext

        // When
        let userWord = UserWordMO(context: context)
        userWord.id = UUID()
        userWord.addedAt = Date()
        userWord.srsStage = 0
        userWord.nextReviewDate = Date()
        userWord.reviewCount = 0
        userWord.consecutiveCorrect = 0
        userWord.isMastered = false
        // easeFactor not explicitly set → uses defaultValue from model

        // Then
        XCTAssertEqual(userWord.easeFactor, AppConstants.defaultEaseFactor,
                       "默认 easeFactor 应为 \(AppConstants.defaultEaseFactor)")
    }

    // MARK: - Preview 数据完整性测试

    /// Given: preview instance → Then: all entity types have data
    func test_previewData_hasAllEntityTypes() {
        // Given
        let preview = PersistenceController.preview
        let context = preview.viewContext

        // Then
        let users = (try? context.count(for: UserMO.fetchRequest())) ?? 0
        let articles = (try? context.count(for: ArticleMO.fetchRequest())) ?? 0
        let words = (try? context.count(for: WordMO.fetchRequest())) ?? 0
        let userWords = (try? context.count(for: UserWordMO.fetchRequest())) ?? 0
        let records = (try? context.count(for: LearningRecordMO.fetchRequest())) ?? 0
        let exams = (try? context.count(for: ExamAttemptMO.fetchRequest())) ?? 0
        let daily = (try? context.count(for: DailyProgressMO.fetchRequest())) ?? 0

        XCTAssertGreaterThan(users, 0, "Preview 应包含 UserMO")
        XCTAssertGreaterThan(articles, 0, "Preview 应包含 ArticleMO")
        XCTAssertGreaterThan(words, 0, "Preview 应包含 WordMO")
        XCTAssertGreaterThan(userWords, 0, "Preview 应包含 UserWordMO")
        XCTAssertGreaterThan(records, 0, "Preview 应包含 LearningRecordMO")
        XCTAssertGreaterThan(exams, 0, "Preview 应包含 ExamAttemptMO")
        XCTAssertGreaterThan(daily, 0, "Preview 应包含 DailyProgressMO")
    }
}
