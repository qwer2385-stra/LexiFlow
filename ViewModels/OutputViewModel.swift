import Foundation
import CoreData

/// 输出（写作）ViewModel
final class OutputViewModel: ObservableObject {

    // MARK: - Published

    /// 用户输入
    @Published var userInput: String = ""
    /// 字数统计
    @Published var wordCount: Int = 0
    /// 是否正在提交
    @Published var isSubmitting: Bool = false
    /// 反馈信息
    @Published var feedback: String?

    // MARK: - 写作提示

    /// 基于当日文章主题的写作提示
    @Published var writingPrompt: String = "Write a short paragraph about how technology helps you learn English. What tools or apps do you use, and how have they improved your skills?"

    // MARK: - 更新字数

    /// 实时统计输入字数
    func updateWordCount() {
        wordCount = userInput.wordCount
    }

    // MARK: - 提交

    /// 提交写作内容并记录
    func submit(context: NSManagedObjectContext, user: UserMO, todayProgress: DailyProgressMO?) {
        guard !userInput.isBlank else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        // 记录学习数据
        let record = LearningRecordMO(context: context)
        record.id = UUID()
        record.date = Date()
        record.stage = 4
        record.stageName = "英文输出"
        record.durationSeconds = max(60, wordCount * 3) // 估计用时
        record.wpm = 0
        record.comprehensionRate = 0
        record.user = user
        record.dailyProgress = todayProgress

        // 更新今日进度
        if let progress = todayProgress {
            progress.totalDurationSeconds += record.durationSeconds
            progress.stage4Completed = true
            progress.isDayComplete = true
        }

        do {
            try context.save()
            feedback = "✅ 提交成功！今天已完成了所有学习阶段，继续保持！"
        } catch {
            feedback = "提交失败，请重试。"
            print("保存输出记录失败: \(error)")
        }
    }

    // MARK: - 清除

    func clear() {
        userInput = ""
        wordCount = 0
        feedback = nil
    }
}
