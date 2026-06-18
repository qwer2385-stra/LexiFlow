import Foundation

/// 应用全局常量配置
enum AppConstants {

    // MARK: - CET 等级

    /// CET 等级列表
    static let cetLevels = ["CET4", "CET6"]

    // MARK: - SRS 间隔映射（秒）

    /// SRS 阶段 → 间隔天数（秒）
    static let srsIntervals: [Int: TimeInterval] = [
        0: 86_400,       // 1 天
        1: 259_200,      // 3 天
        2: 604_800,      // 7 天
        3: 1_296_000,    // 15 天
        4: 2_592_000,    // 30 天
    ]

    /// 5 阶段及以上默认为 60 天
    static let defaultSRSInterval: TimeInterval = 5_184_000

    // MARK: - 每日目标默认值

    /// 默认每日学习时长（分钟）
    static let defaultTargetDailyMinutes: Int = 30
    /// 默认每周目标单词数
    static let defaultTargetWeeklyWords: Int = 50

    // MARK: - 考试配置

    /// 考试限时（秒），15 分钟
    static let examTimeLimitSeconds: Int = 900
    /// 每场考试题目数
    static let examQuestionsCount: Int = 10

    // MARK: - 学习阶段

    enum LearningStage: Int, CaseIterable {
        case input = 1
        case interaction = 2
        case memory = 3
        case output = 4

        /// 阶段中文名称
        var name: String {
            switch self {
            case .input:       return "新闻输入"
            case .interaction: return "精读拆解"
            case .memory:      return "四六级训练"
            case .output:      return "英文输出"
            }
        }

        /// SF Symbol 图标名
        var icon: String {
            switch self {
            case .input:       return "newspaper.fill"
            case .interaction: return "text.magnifyingglass"
            case .memory:      return "brain.head.profile"
            case .output:      return "pencil.and.outline"
            }
        }

        /// 建议时长（分钟）
        var suggestedMinutes: Int {
            switch self {
            case .input:       return 10
            case .interaction: return 8
            case .memory:      return 7
            case .output:      return 5
            }
        }
    }

    // MARK: - 通知

    static let notificationCategoryIdentifier = "LEXIFLOW_REMINDER"

    // MARK: - SRS 默认值

    /// 默认 easeFactor
    static let defaultEaseFactor: Double = 2.5
    /// 最小 easeFactor
    static let minEaseFactor: Double = 1.3
    /// 默认 WPM
    static let defaultWPM: Double = 120.0

    // MARK: - Core Data 模型名

    static let coreDataModelName = "LexiFlow"
}
