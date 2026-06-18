import Foundation
import CoreData

// MARK: - 统计数据模型

/// 每日统计
struct DailyStats: Identifiable {
    let date: Date
    let durationSeconds: Int
    let wpm: Double
    let comprehensionRate: Double
    let wordsLearned: Int
    let isDayComplete: Bool

    var id: Date { date }
}

/// 每周报告
struct WeeklyReport {
    let weekStartDate: Date
    let totalDurationMinutes: Int
    let totalWordsLearned: Int
    let averageWPM: Double
    let averageComprehension: Double
    let streakDays: Int
    let bestDay: Date?
    let bestDayMinutes: Int
}

// MARK: - 统计服务

/// 数据统计服务：周/月统计、趋势、报告
final class StatsService {

    // MARK: - 周统计

    /// 获取本周每日统计
    func getWeeklyStats(context: NSManagedObjectContext) -> [DailyStats] {
        let weekStart = Date().startOfWeek
        return getDailyStats(from: weekStart, to: Date(), context: context)
    }

    // MARK: - 月统计

    /// 获取本月每日统计
    func getMonthlyStats(context: NSManagedObjectContext) -> [DailyStats] {
        let monthStart = Date().startOfMonth
        return getDailyStats(from: monthStart, to: Date(), context: context)
    }

    // MARK: - 每日统计

    private func getDailyStats(from start: Date, to end: Date, context: NSManagedObjectContext) -> [DailyStats] {
        let request = DailyProgressMO.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", start.startOfDay as NSDate, end.endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        do {
            let progresses = try context.fetch(request)
            return progresses.map { progress in
                let records = progress.learningRecords ?? []
                let totalWPM = records.map(\.wpm).reduce(0, +)
                let avgWPM = records.isEmpty ? 0 : totalWPM / Double(records.count)
                let totalComp = records.map(\.comprehensionRate).reduce(0, +)
                let avgComp = records.isEmpty ? 0 : totalComp / Double(records.count)

                return DailyStats(
                    date: progress.date,
                    durationSeconds: progress.totalDurationSeconds,
                    wpm: avgWPM,
                    comprehensionRate: avgComp,
                    wordsLearned: records.count,
                    isDayComplete: progress.isDayComplete
                )
            }
        } catch {
            print("获取统计失败: \(error)")
            return []
        }
    }

    // MARK: - WPM 趋势

    /// 获取 WPM 趋势数据（日期 → WPM）
    func getWPMTrend(context: NSManagedObjectContext, days: Int = 30) -> [(Date, Double)] {
        let records = fetchRecentRecords(context: context, days: days)
        return records.map { ($0.date, $0.wpm) }
    }

    /// 获取理解率趋势
    func getComprehensionTrend(context: NSManagedObjectContext, days: Int = 30) -> [(Date, Double)] {
        let records = fetchRecentRecords(context: context, days: days)
        return records.map { ($0.date, $0.comprehensionRate) }
    }

    // MARK: - 词汇增长

    /// 获取词汇量增长数据
    func getVocabularyGrowth(context: NSManagedObjectContext, days: Int = 30) -> [(Date, Int)] {
        let request = UserWordMO.fetchRequest()
        let cutoff = Date().addingTimeInterval(Double(-days) * 86400)
        request.predicate = NSPredicate(format: "addedAt >= %@", cutoff.startOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "addedAt", ascending: true)]

        do {
            let userWords = try context.fetch(request)
            // 按日期分组统计累计数量
            var result: [(Date, Int)] = []
            var cumulative = 0
            let calendar = Calendar.current
            var currentDay: Date?

            for word in userWords {
                let day = calendar.startOfDay(for: word.addedAt)
                if currentDay != day {
                    if let day = currentDay {
                        result.append((day, cumulative))
                    }
                    currentDay = day
                }
                cumulative += 1
            }
            if let day = currentDay {
                result.append((day, cumulative))
            }
            return result
        } catch {
            print("获取词汇增长失败: \(error)")
            return []
        }
    }

    // MARK: - 周报

    /// 生成学习周报
    func getWeeklyReport(context: NSManagedObjectContext) -> WeeklyReport {
        let stats = getWeeklyStats(context: context)
        let totalDuration = stats.map(\.durationSeconds).reduce(0, +)
        let totalWords = stats.map(\.wordsLearned).reduce(0, +)
        let avgWPM = stats.isEmpty ? 0 : stats.map(\.wpm).reduce(0, +) / Double(stats.count)
        let avgComp = stats.isEmpty ? 0 : stats.map(\.comprehensionRate).reduce(0, +) / Double(stats.count)
        let streak = calculateStreakDays(context: context)

        var bestDay: Date? = nil
        var bestMinutes = 0
        for stat in stats {
            let mins = stat.durationSeconds / 60
            if mins > bestMinutes {
                bestMinutes = mins
                bestDay = stat.date
            }
        }

        return WeeklyReport(
            weekStartDate: Date().startOfWeek,
            totalDurationMinutes: totalDuration / 60,
            totalWordsLearned: totalWords,
            averageWPM: avgWPM,
            averageComprehension: avgComp,
            streakDays: streak,
            bestDay: bestDay,
            bestDayMinutes: bestMinutes
        )
    }

    // MARK: - 连续打卡天数

    /// 计算连续打卡天数
    func calculateStreakDays(context: NSManagedObjectContext) -> Int {
        let request = DailyProgressMO.fetchRequest()
        request.predicate = NSPredicate(format: "isDayComplete == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let progresses = try context.fetch(request)
            guard !progresses.isEmpty else { return 0 }

            var streak = 1
            let calendar = Calendar.current
            var previousDate = calendar.startOfDay(for: progresses[0].date)

            for i in 1..<progresses.count {
                let currentDate = calendar.startOfDay(for: progresses[i].date)
                let diff = calendar.dateComponents([.day], from: currentDate, to: previousDate).day ?? 0
                if diff == 1 {
                    streak += 1
                    previousDate = currentDate
                } else {
                    break
                }
            }

            // 检查今天是否在连续中
            let today = calendar.startOfDay(for: Date())
            let firstInStreak = calendar.startOfDay(for: progresses[0].date)
            let diffToToday = calendar.dateComponents([.day], from: firstInStreak, to: today).day ?? 0
            if diffToToday <= 1 {
                // 连续到今天或昨天
            } else {
                streak = 0
            }

            return max(0, streak)
        } catch {
            return 0
        }
    }

    // MARK: - Private

    private func fetchRecentRecords(context: NSManagedObjectContext, days: Int) -> [LearningRecordMO] {
        let request = LearningRecordMO.fetchRequest()
        let cutoff = Date().addingTimeInterval(Double(-days) * 86400)
        request.predicate = NSPredicate(format: "date >= %@", cutoff.startOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }
}
