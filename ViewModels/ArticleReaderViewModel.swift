import Foundation
import CoreData
import SwiftUI

/// 文章阅读器 ViewModel
final class ArticleReaderViewModel: ObservableObject {

    // MARK: - Published

    /// 解析后的文章内容
    @Published var articleContent: ArticleContent?
    /// 当前 WPM
    @Published var wpm: Double = AppConstants.defaultWPM
    /// 是否正在阅读计时
    @Published var isReading: Bool = false
    /// 选中的单词 ID（用于弹出详情）
    @Published var selectedWordID: String?
    /// 是否显示单词详情 Sheet
    @Published var showWordDetail: Bool = false

    // MARK: - Services

    private let articleService = ArticleService()

    // MARK: - 计时

    private var startTime: Date?
    private var elapsedSeconds: Int = 0

    // MARK: - 加载文章

    /// 加载并解析文章
    func loadArticle(article: ArticleMO, cetLevel: String = "CET4") {
        let content = articleService.parseArticle(
            rawContent: article.rawContent,
            articleID: article.id,
            title: article.title,
            cetLevel: cetLevel
        )
        articleContent = content
    }

    /// 通过 rawContent 加载文章
    func loadRawContent(_ content: String, articleID: UUID, title: String, cetLevel: String = "CET4") {
        articleContent = articleService.parseArticle(
            rawContent: content,
            articleID: articleID,
            title: title,
            cetLevel: cetLevel
        )
    }

    // MARK: - 阅读控制

    /// 开始计时阅读
    func startReading() {
        isReading = true
        startTime = Date()
    }

    /// 暂停计时
    func pauseReading() {
        isReading = false
        if let start = startTime {
            elapsedSeconds += Int(Date().timeIntervalSince(start))
        }
        startTime = nil
    }

    /// 完成阅读并记录
    func completeReadingAndRecord(
        stage: Int,
        context: NSManagedObjectContext,
        user: UserMO,
        todayProgress: DailyProgressMO?
    ) {
        pauseReading()

        guard let content = articleContent else { return }

        // 计算 WPM
        let totalSeconds = elapsedSeconds
        wpm = articleService.calculateWPM(wordCount: content.wordCount, seconds: totalSeconds)

        // 创建学习记录
        let record = LearningRecordMO(context: context)
        record.id = UUID()
        record.date = Date()
        record.stage = stage
        record.stageName = AppConstants.LearningStage(rawValue: stage)?.name ?? ""
        record.durationSeconds = totalSeconds
        record.wpm = wpm
        record.comprehensionRate = 0.8 // 默认理解率
        record.user = user
        record.dailyProgress = todayProgress

        // 将文章标记为已读
        markArticleAsRead(articleID: content.articleID, context: context)

        // 更新今日进度时长
        if let progress = todayProgress {
            progress.totalDurationSeconds += totalSeconds
        }

        do {
            try context.save()
        } catch {
            print("保存阅读记录失败: \(error)")
        }
    }

    // MARK: - 单词选择

    /// 选中一个高亮单词
    func selectWord(_ wordID: String) {
        selectedWordID = wordID
        showWordDetail = true
    }

    /// 取消选中
    func dismissWordDetail() {
        showWordDetail = false
        selectedWordID = nil
    }

    // MARK: - Private

    private func markArticleAsRead(articleID: UUID, context: NSManagedObjectContext) {
        let request = ArticleMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", articleID as CVarArg)
        request.fetchLimit = 1
        do {
            if let article = try context.fetch(request).first {
                article.isRead = true
            }
        } catch {
            print("标记已读失败: \(error)")
        }
    }
}
