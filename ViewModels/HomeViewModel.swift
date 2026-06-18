import Foundation
import CoreData
import SwiftUI

/// 首页 ViewModel
final class HomeViewModel: ObservableObject {

    // MARK: - Published

    /// 今日进度
    @Published var todayProgress: DailyProgressMO?
    /// 完成百分比（0~1）
    @Published var completionPercent: Double = 0
    /// 连续打卡天数
    @Published var streakDays: Int = 0
    /// 词汇量
    @Published var vocabularyCount: Int = 0
    /// 是否加载中
    @Published var isLoading: Bool = false

    // MARK: - Services

    private let statsService = StatsService()

    // MARK: - 加载今日进度

    /// 加载（或创建）今日进度
    func loadTodayProgress(context: NSManagedObjectContext, user: UserMO) {
        isLoading = true
        defer { isLoading = false }

        let today = Date().startOfDay
        let request = DailyProgressMO.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@ AND user == %@", today as NSDate, user)
        request.fetchLimit = 1

        do {
            let results = try context.fetch(request)
            if let existing = results.first {
                todayProgress = existing
            } else {
                // 创建当日进度
                let newProgress = DailyProgressMO(context: context)
                newProgress.id = UUID()
                newProgress.date = today
                newProgress.currentStage = 1
                newProgress.stage1Completed = false
                newProgress.stage2Completed = false
                newProgress.stage3Completed = false
                newProgress.stage4Completed = false
                newProgress.isDayComplete = false
                newProgress.totalDurationSeconds = 0
                newProgress.user = user
                try context.save()
                todayProgress = newProgress
            }
            updateCompletionPercent()
        } catch {
            print("加载今日进度失败: \(error)")
        }

        // 加载词汇量
        loadVocabularyCount(context: context, user: user)
        // 加载连续打卡
        loadStreakDays(context: context)
    }

    // MARK: - 解锁下一阶段

    /// 解锁下一个学习阶段
    func unlockNextStage() {
        guard let progress = todayProgress else { return }
        let nextStage = progress.currentStage + 1
        guard nextStage <= 4 else { return }

        switch nextStage {
        case 2: progress.stage1Completed = true
        case 3: progress.stage2Completed = true
        case 4: progress.stage3Completed = true
        default: break
        }

        progress.currentStage = nextStage
        if nextStage == 4 {
            progress.stage4Completed = true
            progress.isDayComplete = true
        }

        do {
            try progress.managedObjectContext?.save()
            updateCompletionPercent()
        } catch {
            print("解锁阶段失败: \(error)")
        }
    }

    /// 标记当日全部完成
    func completeDay() {
        guard let progress = todayProgress else { return }
        progress.stage1Completed = true
        progress.stage2Completed = true
        progress.stage3Completed = true
        progress.stage4Completed = true
        progress.isDayComplete = true
        do {
            try progress.managedObjectContext?.save()
            updateCompletionPercent()
            if let context = progress.managedObjectContext {
                loadStreakDays(context: context)
            }
        } catch {
            print("标记完成失败: \(error)")
        }
    }

    // MARK: - Private

    private func updateCompletionPercent() {
        guard let progress = todayProgress else {
            completionPercent = 0
            return
        }
        var completed = 0
        if progress.stage1Completed { completed += 1 }
        if progress.stage2Completed { completed += 1 }
        if progress.stage3Completed { completed += 1 }
        if progress.stage4Completed { completed += 1 }
        completionPercent = Double(completed) / 4.0
    }

    private func loadVocabularyCount(context: NSManagedObjectContext, user: UserMO) {
        let request = UserWordMO.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        do {
            vocabularyCount = try context.count(for: request)
        } catch {
            vocabularyCount = 0
        }
    }

    private func loadStreakDays(context: NSManagedObjectContext) {
        streakDays = statsService.calculateStreakDays(context: context)
    }
}
