import Foundation
import CoreData

/// SwiftUI Preview 示例数据
enum PreviewSampleData {

    /// 向指定上下文中填充示例数据
    static func populate(context: NSManagedObjectContext) {
        // --- 创建用户 ---
        let user = UserMO(context: context)
        user.id = UUID()
        user.nickname = "寇豆码"
        user.targetDailyMinutes = 30
        user.targetWeeklyWords = 50
        user.cetLevel = "CET4"
        user.currentDifficultyLevel = 2
        user.createdAt = Date().addingTimeInterval(-30 * 86400)

        // --- 创建单词 ---
        let sampleWords: [(String, String, String, String, String, String, String, Int)] = [
            ("abandon", "/əˈbændən/", "v.", "放弃；遗弃",
             "They had to abandon the sinking ship.",
             "主语[They] 谓语[had to abandon] 宾语[the sinking ship]",
             "CET4", 1),
            ("ability", "/əˈbɪləti/", "n.", "能力；才能",
             "She has the ability to solve complex problems.",
             "主语[She] 谓语[has] 宾语[the ability] 定语[to solve complex problems]",
             "CET4", 2),
            ("abstract", "/ˈæbstrækt/", "adj.", "抽象的；理论的",
             "The concept is too abstract for beginners.",
             "主语[The concept] 系动词[is] 表语[too abstract] 状语[for beginners]",
             "CET4", 5),
            ("academic", "/ˌækəˈdemɪk/", "adj.", "学术的；学院的",
             "His academic performance has improved significantly.",
             "主语[His academic performance] 谓语[has improved] 状语[significantly]",
             "CET4", 8),
            ("brilliant", "/ˈbrɪliənt/", "adj.", "杰出的；明亮的",
             "She came up with a brilliant idea during the meeting.",
             "主语[She] 谓语[came up with] 宾语[a brilliant idea] 状语[during the meeting]",
             "CET6", 15),
        ]

        var wordMOs: [WordMO] = []
        for (text, phonetic, pos, definition, example, structure, cetLevel, rank) in sampleWords {
            let word = WordMO(context: context)
            word.id = UUID()
            word.text = text
            word.phonetic = phonetic
            word.partOfSpeech = pos
            word.definition = definition
            word.exampleSentence = example
            word.sentenceStructure = structure
            word.cetLevel = cetLevel
            word.frequencyRank = rank
            wordMOs.append(word)
        }

        // --- 创建 UserWord ---
        for (i, word) in wordMOs.enumerated() {
            let userWord = UserWordMO(context: context)
            userWord.id = UUID()
            userWord.addedAt = Date().addingTimeInterval(Double(-i) * 86400)
            userWord.srsStage = min(i, 4)
            userWord.nextReviewDate = i <= 2 ? Date() : Date().addingTimeInterval(Double(i) * 86400)
            userWord.easeFactor = 2.5
            userWord.reviewCount = i
            userWord.consecutiveCorrect = i
            userWord.isMastered = i >= 4
            userWord.user = user
            userWord.word = word
        }

        // --- 创建文章 ---
        let article = ArticleMO(context: context)
        article.id = UUID()
        article.title = "AI Breakthroughs Transform Language Learning"
        article.rawContent = """
        Artificial intelligence is rapidly changing how people learn new languages. \
        Recent advances in natural language processing have made it possible for \
        applications to provide personalized feedback on pronunciation, grammar, \
        and vocabulary usage. Students can now practice conversations with AI tutors \
        that adapt to their proficiency level and learning style. The technology \
        analyzes speech patterns and provides immediate corrections, helping learners \
        improve their skills more efficiently than traditional methods.
        """
        article.wordCount = article.rawContent?.wordCount ?? 0
        article.difficultyLevel = 2
        article.source = "Tech Daily"
        article.publishDate = Date()
        article.isRead = false

        // --- 创建每日进度 ---
        let todayProgress = DailyProgressMO(context: context)
        todayProgress.id = UUID()
        todayProgress.date = Date().startOfDay
        todayProgress.currentStage = 2
        todayProgress.stage1Completed = true
        todayProgress.stage2Completed = false
        todayProgress.stage3Completed = false
        todayProgress.stage4Completed = false
        todayProgress.isDayComplete = false
        todayProgress.totalDurationSeconds = 600
        todayProgress.user = user

        // --- 创建学习记录 ---
        let record = LearningRecordMO(context: context)
        record.id = UUID()
        record.date = Date()
        record.stage = 1
        record.stageName = "新闻输入"
        record.durationSeconds = 600
        record.wpm = 135.0
        record.comprehensionRate = 0.85
        record.user = user
        record.article = article
        record.dailyProgress = todayProgress

        // --- 创建考试记录 ---
        let exam = ExamAttemptMO(context: context)
        exam.id = UUID()
        exam.date = Date().addingTimeInterval(-86400)
        exam.totalQuestions = 10
        exam.correctCount = 7
        exam.score = 70.0
        exam.timeUsedSeconds = 720
        exam.questionResultsJSON = "[{\"id\":\"1\",\"correct\":true},{\"id\":\"2\",\"correct\":false}]"
        exam.errorCategoriesJSON = "[\"vocabulary\",\"comprehension\"]"
        exam.user = user

        // --- 保存 ---
        do {
            try context.save()
        } catch {
            print("Preview 数据填充失败: \(error)")
        }
    }
}
