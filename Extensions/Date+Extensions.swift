import Foundation

// MARK: - Date 扩展

extension Date {

    /// 获取当天零点
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 获取当天 23:59:59
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// 本周起始（周一）
    var startOfWeek: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        components.weekday = 2 // 周一
        return calendar.date(from: components) ?? self
    }

    /// 本月起始
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// 是否为今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 格式化：yyyy-MM-dd
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    /// 格式化：MM月dd日
    var shortChinese: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: self)
    }

    /// 相对时间描述（今天 / 昨天 / N天前）
    var relativeDescription: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "今天"
        } else if calendar.isDateInYesterday(self) {
            return "昨天"
        } else {
            let days = calendar.dateComponents([.day], from: startOfDay, to: Date().startOfDay).day ?? 0
            return "\(days)天前"
        }
    }

    /// 计算与另一个日期的天数差
    func daysSince(_ other: Date) -> Int {
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: other)
        let to = calendar.startOfDay(for: self)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }
}
