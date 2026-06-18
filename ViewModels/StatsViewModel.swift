import Foundation
import CoreData

// MARK: - 统计时间范围

enum StatsTimeRange: String, CaseIterable {
    case week = "本周"
    case month = "本月"
    case all = "全部"
}

// MARK: - 统计 ViewModel

final class StatsViewModel: ObservableObject {

    // MARK: - Published

    /// 每日统计数据
    @Published var dailyStats: [DailyStats] = []
    /// WPM 趋势
    @Published var wpmTrend: [(Date, Double)] = []
    /// 理解率趋势
    @Published var comprehensionTrend: [(Date, Double)] = []
    /// 词汇增长数据
    @Published var vocabularyGrowth: [(Date, Int)] = []
    /// 周报
    @Published var weeklyReport: WeeklyReport?
    /// 当前时间范围
    @Published var timeRange: StatsTimeRange = .week
    /// 是否加载中
    @Published var isLoading: Bool = false

    // MARK: - Services

    private let statsService = StatsService()

    // MARK: - 加载

    func loadStats(context: NSManagedObjectContext) {
        isLoading = true
        defer { isLoading = false }

        switch timeRange {
        case .week:
            dailyStats = statsService.getWeeklyStats(context: context)
        case .month:
            dailyStats = statsService.getMonthlyStats(context: context)
        case .all:
            dailyStats = statsService.getMonthlyStats(context: context)
        }

        wpmTrend = statsService.getWPMTrend(context: context)
        comprehensionTrend = statsService.getComprehensionTrend(context: context)
        vocabularyGrowth = statsService.getVocabularyGrowth(context: context)
        weeklyReport = statsService.getWeeklyReport(context: context)
    }

    func changeTimeRange(_ range: StatsTimeRange, context: NSManagedObjectContext) {
        timeRange = range
        loadStats(context: context)
    }

    // MARK: - 聚合指标

    /// 总学习时长（分钟）
    var totalMinutes: Int {
        dailyStats.map(\.durationSeconds).reduce(0, +) / 60
    }

    /// 平均每日时长（分钟）
    var averageDailyMinutes: Double {
        guard !dailyStats.isEmpty else { return 0 }
        return Double(totalMinutes) / Double(dailyStats.count)
    }

    /// 打卡天数
    var completedDays: Int {
        dailyStats.filter(\.isDayComplete).count
    }
}
