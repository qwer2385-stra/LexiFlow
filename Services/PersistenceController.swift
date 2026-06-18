import Foundation
import CoreData

/// Core Data 持久化控制器（单例）
/// 使用编程方式构建 NSManagedObjectModel，无需 .xcdatamodeld 文件
final class PersistenceController: ObservableObject {

    // MARK: - Singleton

    static let shared = PersistenceController()

    // MARK: - Preview

    /// 预览专用实例（内存存储）
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        // 插入预览数据
        PreviewSampleData.populate(context: context)
        return controller
    }()

    // MARK: - Container

    let container: NSPersistentContainer

    /// 便捷访问 viewContext
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Init

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(
            name: AppConstants.coreDataModelName,
            managedObjectModel: PersistenceController.createManagedObjectModel()
        )

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // 生产环境下应使用更完善的错误处理
                fatalError("Core Data 存储加载失败: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data 保存失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 编程式 NSManagedObjectModel

    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // ---- UserMO ----
        let userEntity = NSEntityDescription()
        userEntity.name = "UserMO"
        userEntity.managedObjectClassName = NSStringFromClass(UserMO.self)

        let userID = NSAttributeDescription()
        userID.name = "id"
        userID.attributeType = .UUIDAttributeType
        userID.isOptional = false

        let nickname = NSAttributeDescription()
        nickname.name = "nickname"
        nickname.attributeType = .stringAttributeType
        nickname.isOptional = false
        nickname.defaultValue = ""

        let targetDailyMinutes = NSAttributeDescription()
        targetDailyMinutes.name = "targetDailyMinutes"
        targetDailyMinutes.attributeType = .integer64AttributeType
        targetDailyMinutes.isOptional = false
        targetDailyMinutes.defaultValue = AppConstants.defaultTargetDailyMinutes

        let targetWeeklyWords = NSAttributeDescription()
        targetWeeklyWords.name = "targetWeeklyWords"
        targetWeeklyWords.attributeType = .integer64AttributeType
        targetWeeklyWords.isOptional = false
        targetWeeklyWords.defaultValue = AppConstants.defaultTargetWeeklyWords

        let cetLevel = NSAttributeDescription()
        cetLevel.name = "cetLevel"
        cetLevel.attributeType = .stringAttributeType
        cetLevel.isOptional = false
        cetLevel.defaultValue = "CET4"

        let currentDifficultyLevel = NSAttributeDescription()
        currentDifficultyLevel.name = "currentDifficultyLevel"
        currentDifficultyLevel.attributeType = .integer64AttributeType
        currentDifficultyLevel.isOptional = false
        currentDifficultyLevel.defaultValue = 1

        let createdAt = NSAttributeDescription()
        createdAt.name = "createdAt"
        createdAt.attributeType = .dateAttributeType
        createdAt.isOptional = false

        userEntity.properties = [
            userID, nickname, targetDailyMinutes, targetWeeklyWords,
            cetLevel, currentDifficultyLevel, createdAt
        ]

        // ---- ArticleMO ----
        let articleEntity = NSEntityDescription()
        articleEntity.name = "ArticleMO"
        articleEntity.managedObjectClassName = NSStringFromClass(ArticleMO.self)

        let articleID = NSAttributeDescription()
        articleID.name = "id"; articleID.attributeType = .UUIDAttributeType; articleID.isOptional = false

        let articleTitle = NSAttributeDescription()
        articleTitle.name = "title"; articleTitle.attributeType = .stringAttributeType; articleTitle.isOptional = false; articleTitle.defaultValue = ""

        let rawContent = NSAttributeDescription()
        rawContent.name = "rawContent"; rawContent.attributeType = .stringAttributeType; rawContent.isOptional = false; rawContent.defaultValue = ""

        let wordCount = NSAttributeDescription()
        wordCount.name = "wordCount"; wordCount.attributeType = .integer64AttributeType; wordCount.isOptional = false; wordCount.defaultValue = 0

        let difficultyLevel = NSAttributeDescription()
        difficultyLevel.name = "difficultyLevel"; difficultyLevel.attributeType = .integer64AttributeType; difficultyLevel.isOptional = false; difficultyLevel.defaultValue = 1

        let source = NSAttributeDescription()
        source.name = "source"; source.attributeType = .stringAttributeType; source.isOptional = false; source.defaultValue = ""

        let publishDate = NSAttributeDescription()
        publishDate.name = "publishDate"; publishDate.attributeType = .dateAttributeType; publishDate.isOptional = false

        let isRead = NSAttributeDescription()
        isRead.name = "isRead"; isRead.attributeType = .booleanAttributeType; isRead.isOptional = false; isRead.defaultValue = false

        articleEntity.properties = [
            articleID, articleTitle, rawContent, wordCount,
            difficultyLevel, source, publishDate, isRead
        ]

        // ---- WordMO ----
        let wordEntity = NSEntityDescription()
        wordEntity.name = "WordMO"
        wordEntity.managedObjectClassName = NSStringFromClass(WordMO.self)

        let wordID = NSAttributeDescription()
        wordID.name = "id"; wordID.attributeType = .UUIDAttributeType; wordID.isOptional = false

        let text = NSAttributeDescription()
        text.name = "text"; text.attributeType = .stringAttributeType; text.isOptional = false; text.defaultValue = ""

        let phonetic = NSAttributeDescription()
        phonetic.name = "phonetic"; phonetic.attributeType = .stringAttributeType; phonetic.isOptional = false; phonetic.defaultValue = ""

        let partOfSpeech = NSAttributeDescription()
        partOfSpeech.name = "partOfSpeech"; partOfSpeech.attributeType = .stringAttributeType; partOfSpeech.isOptional = false; partOfSpeech.defaultValue = ""

        let definition = NSAttributeDescription()
        definition.name = "definition"; definition.attributeType = .stringAttributeType; definition.isOptional = false; definition.defaultValue = ""

        let exampleSentence = NSAttributeDescription()
        exampleSentence.name = "exampleSentence"; exampleSentence.attributeType = .stringAttributeType; exampleSentence.isOptional = false; exampleSentence.defaultValue = ""

        let sentenceStructure = NSAttributeDescription()
        sentenceStructure.name = "sentenceStructure"; sentenceStructure.attributeType = .stringAttributeType; sentenceStructure.isOptional = false; sentenceStructure.defaultValue = ""

        let wordCetLevel = NSAttributeDescription()
        wordCetLevel.name = "cetLevel"; wordCetLevel.attributeType = .stringAttributeType; wordCetLevel.isOptional = false; wordCetLevel.defaultValue = "CET4"

        let frequencyRank = NSAttributeDescription()
        frequencyRank.name = "frequencyRank"; frequencyRank.attributeType = .integer64AttributeType; frequencyRank.isOptional = false; frequencyRank.defaultValue = 0

        wordEntity.properties = [
            wordID, text, phonetic, partOfSpeech, definition,
            exampleSentence, sentenceStructure, wordCetLevel, frequencyRank
        ]

        // ---- UserWordMO ----
        let userWordEntity = NSEntityDescription()
        userWordEntity.name = "UserWordMO"
        userWordEntity.managedObjectClassName = NSStringFromClass(UserWordMO.self)

        let userWordID = NSAttributeDescription()
        userWordID.name = "id"; userWordID.attributeType = .UUIDAttributeType; userWordID.isOptional = false

        let addedAt = NSAttributeDescription()
        addedAt.name = "addedAt"; addedAt.attributeType = .dateAttributeType; addedAt.isOptional = false

        let srsStage = NSAttributeDescription()
        srsStage.name = "srsStage"; srsStage.attributeType = .integer64AttributeType; srsStage.isOptional = false; srsStage.defaultValue = 0

        let nextReviewDate = NSAttributeDescription()
        nextReviewDate.name = "nextReviewDate"; nextReviewDate.attributeType = .dateAttributeType; nextReviewDate.isOptional = false

        let easeFactor = NSAttributeDescription()
        easeFactor.name = "easeFactor"; easeFactor.attributeType = .doubleAttributeType; easeFactor.isOptional = false; easeFactor.defaultValue = AppConstants.defaultEaseFactor

        let reviewCount = NSAttributeDescription()
        reviewCount.name = "reviewCount"; reviewCount.attributeType = .integer64AttributeType; reviewCount.isOptional = false; reviewCount.defaultValue = 0

        let consecutiveCorrect = NSAttributeDescription()
        consecutiveCorrect.name = "consecutiveCorrect"; consecutiveCorrect.attributeType = .integer64AttributeType; consecutiveCorrect.isOptional = false; consecutiveCorrect.defaultValue = 0

        let isMastered = NSAttributeDescription()
        isMastered.name = "isMastered"; isMastered.attributeType = .booleanAttributeType; isMastered.isOptional = false; isMastered.defaultValue = false

        userWordEntity.properties = [
            userWordID, addedAt, srsStage, nextReviewDate,
            easeFactor, reviewCount, consecutiveCorrect, isMastered
        ]

        // ---- LearningRecordMO ----
        let learningRecordEntity = NSEntityDescription()
        learningRecordEntity.name = "LearningRecordMO"
        learningRecordEntity.managedObjectClassName = NSStringFromClass(LearningRecordMO.self)

        let lrID = NSAttributeDescription()
        lrID.name = "id"; lrID.attributeType = .UUIDAttributeType; lrID.isOptional = false

        let lrDate = NSAttributeDescription()
        lrDate.name = "date"; lrDate.attributeType = .dateAttributeType; lrDate.isOptional = false

        let lrStage = NSAttributeDescription()
        lrStage.name = "stage"; lrStage.attributeType = .integer64AttributeType; lrStage.isOptional = false; lrStage.defaultValue = 1

        let lrStageName = NSAttributeDescription()
        lrStageName.name = "stageName"; lrStageName.attributeType = .stringAttributeType; lrStageName.isOptional = false; lrStageName.defaultValue = ""

        let lrDuration = NSAttributeDescription()
        lrDuration.name = "durationSeconds"; lrDuration.attributeType = .integer64AttributeType; lrDuration.isOptional = false; lrDuration.defaultValue = 0

        let lrWPM = NSAttributeDescription()
        lrWPM.name = "wpm"; lrWPM.attributeType = .doubleAttributeType; lrWPM.isOptional = false; lrWPM.defaultValue = 0.0

        let lrComprehension = NSAttributeDescription()
        lrComprehension.name = "comprehensionRate"; lrComprehension.attributeType = .doubleAttributeType; lrComprehension.isOptional = false; lrComprehension.defaultValue = 0.0

        learningRecordEntity.properties = [
            lrID, lrDate, lrStage, lrStageName, lrDuration, lrWPM, lrComprehension
        ]

        // ---- ExamAttemptMO ----
        let examEntity = NSEntityDescription()
        examEntity.name = "ExamAttemptMO"
        examEntity.managedObjectClassName = NSStringFromClass(ExamAttemptMO.self)

        let examID = NSAttributeDescription()
        examID.name = "id"; examID.attributeType = .UUIDAttributeType; examID.isOptional = false

        let examDate = NSAttributeDescription()
        examDate.name = "date"; examDate.attributeType = .dateAttributeType; examDate.isOptional = false

        let examTotal = NSAttributeDescription()
        examTotal.name = "totalQuestions"; examTotal.attributeType = .integer64AttributeType; examTotal.isOptional = false; examTotal.defaultValue = 0

        let examCorrect = NSAttributeDescription()
        examCorrect.name = "correctCount"; examCorrect.attributeType = .integer64AttributeType; examCorrect.isOptional = false; examCorrect.defaultValue = 0

        let examScore = NSAttributeDescription()
        examScore.name = "score"; examScore.attributeType = .doubleAttributeType; examScore.isOptional = false; examScore.defaultValue = 0.0

        let examTime = NSAttributeDescription()
        examTime.name = "timeUsedSeconds"; examTime.attributeType = .integer64AttributeType; examTime.isOptional = false; examTime.defaultValue = 0

        let examResultJSON = NSAttributeDescription()
        examResultJSON.name = "questionResultsJSON"; examResultJSON.attributeType = .stringAttributeType; examResultJSON.isOptional = false; examResultJSON.defaultValue = "[]"

        let examErrorJSON = NSAttributeDescription()
        examErrorJSON.name = "errorCategoriesJSON"; examErrorJSON.attributeType = .stringAttributeType; examErrorJSON.isOptional = false; examErrorJSON.defaultValue = "[]"

        examEntity.properties = [
            examID, examDate, examTotal, examCorrect,
            examScore, examTime, examResultJSON, examErrorJSON
        ]

        // ---- DailyProgressMO ----
        let dailyEntity = NSEntityDescription()
        dailyEntity.name = "DailyProgressMO"
        dailyEntity.managedObjectClassName = NSStringFromClass(DailyProgressMO.self)

        let dpID = NSAttributeDescription()
        dpID.name = "id"; dpID.attributeType = .UUIDAttributeType; dpID.isOptional = false

        let dpDate = NSAttributeDescription()
        dpDate.name = "date"; dpDate.attributeType = .dateAttributeType; dpDate.isOptional = false

        let dpStage = NSAttributeDescription()
        dpStage.name = "currentStage"; dpStage.attributeType = .integer64AttributeType; dpStage.isOptional = false; dpStage.defaultValue = 1

        let s1c = NSAttributeDescription()
        s1c.name = "stage1Completed"; s1c.attributeType = .booleanAttributeType; s1c.isOptional = false; s1c.defaultValue = false

        let s2c = NSAttributeDescription()
        s2c.name = "stage2Completed"; s2c.attributeType = .booleanAttributeType; s2c.isOptional = false; s2c.defaultValue = false

        let s3c = NSAttributeDescription()
        s3c.name = "stage3Completed"; s3c.attributeType = .booleanAttributeType; s3c.isOptional = false; s3c.defaultValue = false

        let s4c = NSAttributeDescription()
        s4c.name = "stage4Completed"; s4c.attributeType = .booleanAttributeType; s4c.isOptional = false; s4c.defaultValue = false

        let isComplete = NSAttributeDescription()
        isComplete.name = "isDayComplete"; isComplete.attributeType = .booleanAttributeType; isComplete.isOptional = false; isComplete.defaultValue = false

        let dpDuration = NSAttributeDescription()
        dpDuration.name = "totalDurationSeconds"; dpDuration.attributeType = .integer64AttributeType; dpDuration.isOptional = false; dpDuration.defaultValue = 0

        dailyEntity.properties = [
            dpID, dpDate, dpStage, s1c, s2c, s3c, s4c, isComplete, dpDuration
        ]

        // ---- Relationships ----
        // UserMO -> UserWordMO (1:N)
        let userToUserWords = NSRelationshipDescription()
        userToUserWords.name = "userWords"
        userToUserWords.destinationEntity = userWordEntity
        userToUserWords.deleteRule = .cascadeDeleteRule
        userToUserWords.maxCount = 0; userToUserWords.minCount = 0

        // UserMO -> LearningRecordMO (1:N)
        let userToRecords = NSRelationshipDescription()
        userToRecords.name = "learningRecords"
        userToRecords.destinationEntity = learningRecordEntity
        userToRecords.deleteRule = .cascadeDeleteRule
        userToRecords.maxCount = 0; userToRecords.minCount = 0

        // UserMO -> ExamAttemptMO (1:N)
        let userToExams = NSRelationshipDescription()
        userToExams.name = "examAttempts"
        userToExams.destinationEntity = examEntity
        userToExams.deleteRule = .cascadeDeleteRule
        userToExams.maxCount = 0; userToExams.minCount = 0

        // UserMO -> DailyProgressMO (1:N)
        let userToDaily = NSRelationshipDescription()
        userToDaily.name = "dailyProgresses"
        userToDaily.destinationEntity = dailyEntity
        userToDaily.deleteRule = .cascadeDeleteRule
        userToDaily.maxCount = 0; userToDaily.minCount = 0

        userEntity.properties += [userToUserWords, userToRecords, userToExams, userToDaily]

        // UserWordMO -> UserMO (N:1 inverse)
        let userWordToUser = NSRelationshipDescription()
        userWordToUser.name = "user"
        userWordToUser.destinationEntity = userEntity
        userWordToUser.deleteRule = .nullifyDeleteRule
        userWordToUser.maxCount = 1; userWordToUser.minCount = 0
        userWordToUser.inverseRelationship = userToUserWords
        userToUserWords.inverseRelationship = userWordToUser

        // UserWordMO -> WordMO (1:1)
        let userWordToWord = NSRelationshipDescription()
        userWordToWord.name = "word"
        userWordToWord.destinationEntity = wordEntity
        userWordToWord.deleteRule = .nullifyDeleteRule
        userWordToWord.maxCount = 1; userWordToWord.minCount = 0

        userWordEntity.properties += [userWordToUser, userWordToWord]

        // WordMO -> UserWordMO (1:1 inverse)
        let wordToUserWord = NSRelationshipDescription()
        wordToUserWord.name = "userWord"
        wordToUserWord.destinationEntity = userWordEntity
        wordToUserWord.deleteRule = .nullifyDeleteRule
        wordToUserWord.maxCount = 1; wordToUserWord.minCount = 0
        wordToUserWord.inverseRelationship = userWordToWord
        userWordToWord.inverseRelationship = wordToUserWord

        wordEntity.properties += [wordToUserWord]

        // ArticleMO -> LearningRecordMO (1:N)
        let articleToRecords = NSRelationshipDescription()
        articleToRecords.name = "learningRecords"
        articleToRecords.destinationEntity = learningRecordEntity
        articleToRecords.deleteRule = .nullifyDeleteRule
        articleToRecords.maxCount = 0; articleToRecords.minCount = 0

        articleEntity.properties += [articleToRecords]

        // LearningRecordMO -> UserMO (N:1 inverse)
        let recordToUser = NSRelationshipDescription()
        recordToUser.name = "user"
        recordToUser.destinationEntity = userEntity
        recordToUser.deleteRule = .nullifyDeleteRule
        recordToUser.maxCount = 1; recordToUser.minCount = 0
        recordToUser.inverseRelationship = userToRecords
        userToRecords.inverseRelationship = recordToUser

        // LearningRecordMO -> ArticleMO (N:1)
        let recordToArticle = NSRelationshipDescription()
        recordToArticle.name = "article"
        recordToArticle.destinationEntity = articleEntity
        recordToArticle.deleteRule = .nullifyDeleteRule
        recordToArticle.maxCount = 1; recordToArticle.minCount = 0
        recordToArticle.inverseRelationship = articleToRecords
        articleToRecords.inverseRelationship = recordToArticle

        // LearningRecordMO -> DailyProgressMO (N:1)
        let recordToDaily = NSRelationshipDescription()
        recordToDaily.name = "dailyProgress"
        recordToDaily.destinationEntity = dailyEntity
        recordToDaily.deleteRule = .nullifyDeleteRule
        recordToDaily.maxCount = 1; recordToDaily.minCount = 0

        learningRecordEntity.properties += [recordToUser, recordToArticle, recordToDaily]

        // DailyProgressMO -> LearningRecordMO (1:N inverse)
        let dailyToRecords = NSRelationshipDescription()
        dailyToRecords.name = "learningRecords"
        dailyToRecords.destinationEntity = learningRecordEntity
        dailyToRecords.deleteRule = .nullifyDeleteRule
        dailyToRecords.maxCount = 0; dailyToRecords.minCount = 0
        dailyToRecords.inverseRelationship = recordToDaily
        recordToDaily.inverseRelationship = dailyToRecords

        // DailyProgressMO -> UserMO (N:1 inverse)
        let dailyToUser = NSRelationshipDescription()
        dailyToUser.name = "user"
        dailyToUser.destinationEntity = userEntity
        dailyToUser.deleteRule = .nullifyDeleteRule
        dailyToUser.maxCount = 1; dailyToUser.minCount = 0
        dailyToUser.inverseRelationship = userToDaily
        userToDaily.inverseRelationship = dailyToUser

        dailyEntity.properties += [dailyToRecords, dailyToUser]

        // ExamAttemptMO -> UserMO (N:1 inverse)
        let examToUser = NSRelationshipDescription()
        examToUser.name = "user"
        examToUser.destinationEntity = userEntity
        examToUser.deleteRule = .nullifyDeleteRule
        examToUser.maxCount = 1; examToUser.minCount = 0
        examToUser.inverseRelationship = userToExams
        userToExams.inverseRelationship = examToUser

        examEntity.properties += [examToUser]

        // 注册所有实体
        model.entities = [
            userEntity, articleEntity, wordEntity, userWordEntity,
            learningRecordEntity, examEntity, dailyEntity
        ]

        return model
    }
}
