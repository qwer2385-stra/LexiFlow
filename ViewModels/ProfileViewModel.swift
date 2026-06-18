import Foundation
import CoreData
import SwiftUI

/// 个人设置 ViewModel
final class ProfileViewModel: ObservableObject {

    // MARK: - Published

    /// 昵称
    @Published var nickname: String = ""
    /// 每日目标时长（分钟）
    @Published var targetDailyMinutes: Int = AppConstants.defaultTargetDailyMinutes
    /// 每周目标单词数
    @Published var targetWeeklyWords: Int = AppConstants.defaultTargetWeeklyWords
    /// CET 等级
    @Published var cetLevel: String = "CET4"
    /// 提醒是否开启
    @Published var reminderEnabled: Bool = false
    /// 提醒时间（小时）
    @Published var reminderHour: Int = 9
    /// 提醒时间（分钟）
    @Published var reminderMinute: Int = 0
    /// 词汇总量
    @Published var totalWords: Int = 0
    /// 已掌握词汇
    @Published var masteredWords: Int = 0
    /// 总学习天数
    @Published var totalStudyDays: Int = 0

    // MARK: - Services

    private let notificationService = NotificationService()
    private let statsService = StatsService()

    // MARK: - 加载用户数据

    func loadProfile(context: NSManagedObjectContext, user: UserMO?) {
        guard let user = user else { return }
        nickname = user.nickname
        targetDailyMinutes = user.targetDailyMinutes
        targetWeeklyWords = user.targetWeeklyWords
        cetLevel = user.cetLevel

        // 加载统计数据
        let wordRequest = UserWordMO.fetchRequest()
        wordRequest.predicate = NSPredicate(format: "user == %@", user)
        do {
            let allWords = try context.fetch(wordRequest)
            totalWords = allWords.count
            masteredWords = allWords.filter { $0.isMastered }.count
        } catch {
            totalWords = 0
            masteredWords = 0
        }

        totalStudyDays = statsService.calculateStreakDays(context: context)
    }

    // MARK: - 保存

    func saveProfile(context: NSManagedObjectContext, user: UserMO?) {
        guard let user = user else { return }
        user.nickname = nickname
        user.targetDailyMinutes = targetDailyMinutes
        user.targetWeeklyWords = targetWeeklyWords
        user.cetLevel = cetLevel

        do {
            try context.save()
        } catch {
            print("保存用户设置失败: \(error)")
        }
    }

    // MARK: - 通知

    /// 切换提醒
    func toggleReminder() {
        if reminderEnabled {
            notificationService.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
        } else {
            notificationService.cancelAllNotifications()
        }
    }

    /// 更新提醒时间
    func updateReminderTime() {
        guard reminderEnabled else { return }
        notificationService.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
    }

    /// 请求通知权限
    func requestNotificationPermission() {
        notificationService.requestAuthorization { [weak self] granted in
            self?.reminderEnabled = granted
        }
    }

    // MARK: - 清除数据

    /// 清除所有学习进度
    func clearAllProgress(context: NSManagedObjectContext, user: UserMO?) {
        guard let user = user else { return }

        // 删除用户相关的所有数据
        if let progresses = user.dailyProgresses {
            for progress in progresses {
                context.delete(progress)
            }
        }
        if let records = user.learningRecords {
            for record in records {
                context.delete(record)
            }
        }
        if let attempts = user.examAttempts {
            for attempt in attempts {
                context.delete(attempt)
            }
        }
        if let userWords = user.userWords {
            for uw in userWords {
                context.delete(uw)
            }
        }

        do {
            try context.save()
            totalWords = 0
            masteredWords = 0
            totalStudyDays = 0
        } catch {
            print("清除进度失败: \(error)")
        }
    }
}
