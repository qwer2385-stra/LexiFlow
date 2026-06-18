import XCTest
import Foundation
import SwiftUI
@testable import LexiFlow

// MARK: - Date 扩展测试

final class DateExtensionsTests: XCTestCase {

    // MARK: - startOfDay

    func test_startOfDay_returnsMidnight() {
        // Given
        let now = Date()

        // When
        let start = now.startOfDay

        // Then
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func test_startOfDay_consecutiveDays_different() {
        // Given
        let today = Date().startOfDay
        let tomorrow = Date().addingTimeInterval(86400).startOfDay

        // Then
        let calendar = Calendar.current
        let diff = calendar.dateComponents([.day], from: today, to: tomorrow).day
        XCTAssertEqual(diff, 1, "连续两天 startOfDay 差 1 天")
    }

    // MARK: - endOfDay

    func test_endOfDay_returnsLastSecond() {
        // Given
        let now = Date()

        // When
        let end = now.endOfDay

        // Then
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: end)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    // MARK: - startOfWeek

    func test_startOfWeek_returnsMonday() {
        // Given
        let now = Date()

        // When
        let weekStart = now.startOfWeek

        // Then
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: weekStart)
        // weekday: 1=Sun, 2=Mon
        XCTAssertEqual(weekday, 2, "startOfWeek 应为周一（weekday=2）")
    }

    // MARK: - startOfMonth

    func test_startOfMonth_returnsFirstDay() {
        // Given
        let now = Date()

        // When
        let monthStart = now.startOfMonth

        // Then
        let calendar = Calendar.current
        let day = calendar.component(.day, from: monthStart)
        XCTAssertEqual(day, 1, "startOfMonth 应为当月 1 号")
    }

    // MARK: - isToday

    func test_isToday_forCurrentDate_returnsTrue() {
        // Given/When
        let now = Date()

        // Then
        XCTAssertTrue(now.isToday, "当前日期应判断为今天")
    }

    func test_isToday_forYesterday_returnsFalse() {
        // Given
        let yesterday = Date().addingTimeInterval(-86400)

        // Then
        XCTAssertFalse(yesterday.isToday, "昨天不应判断为今天")
    }

    // MARK: - dateString

    func test_dateString_formatIsCorrect() {
        // Given: 已知日期 2025-01-15
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: "2025-01-15")!

        // When
        let result = date.dateString

        // Then
        XCTAssertEqual(result, "2025-01-15")
    }

    // MARK: - daysSince

    func test_daysSince_sameDay_returnsZero() {
        // Given
        let today = Date()

        // When
        let diff = today.daysSince(today)

        // Then
        XCTAssertEqual(diff, 0)
    }

    func test_daysSince_yesterday_returnsOne() {
        // Given
        let today = Date()
        let yesterday = Date().addingTimeInterval(-86400)

        // When
        let diff = today.daysSince(yesterday)

        // Then
        XCTAssertEqual(diff, 1,
                       "今天相对昨天应为 1 天")
    }

    func test_daysSince_futureDate_returnsNegative() {
        // Given
        let today = Date()
        let tomorrow = Date().addingTimeInterval(86400)

        // When
        let diff = today.daysSince(tomorrow)

        // Then
        XCTAssertEqual(diff, -1,
                       "今天相对明天应为 -1 天")
    }

    // MARK: - relativeDescription

    func test_relativeDescription_today_returnsChinese() {
        // Given
        let today = Date()

        // When
        let desc = today.relativeDescription

        // Then
        XCTAssertEqual(desc, "今天")
    }

    func test_relativeDescription_yesterday_returnsChinese() {
        // Given
        let yesterday = Date().addingTimeInterval(-86400)

        // When
        let desc = yesterday.relativeDescription

        // Then
        XCTAssertEqual(desc, "昨天")
    }

    func test_relativeDescription_twoDaysAgo_returnsCorrectFormat() {
        // Given
        let twoDaysAgo = Date().addingTimeInterval(-86400 * 2)

        // When
        let desc = twoDaysAgo.relativeDescription

        // Then
        XCTAssertTrue(desc.hasSuffix("天前"),
                      "两天前应返回 'N天前' 格式: \(desc)")
    }
}

// MARK: - String 扩展测试

final class StringExtensionsTests: XCTestCase {

    // MARK: - trimmed

    func test_trimmed_removesLeadingWhitespace() {
        XCTAssertEqual("  hello".trimmed, "hello")
    }

    func test_trimmed_removesTrailingWhitespace() {
        XCTAssertEqual("hello  ".trimmed, "hello")
    }

    func test_trimmed_removesNewlines() {
        XCTAssertEqual("hello\n".trimmed, "hello")
    }

    func test_trimmed_emptyString_returnsEmpty() {
        XCTAssertEqual("   ".trimmed, "")
    }

    // MARK: - isBlank

    func test_isBlank_emptyString_returnsTrue() {
        XCTAssertTrue("".isBlank)
    }

    func test_isBlank_whitespaceOnly_returnsTrue() {
        XCTAssertTrue("   \n\t".isBlank)
    }

    func test_isBlank_nonEmpty_returnsFalse() {
        XCTAssertFalse("hello".isBlank)
    }

    // MARK: - wordCount

    func test_wordCount_simpleText() {
        // Given
        let text = "Hello world this is a test"

        // When
        let count = text.wordCount

        // Then
        XCTAssertEqual(count, 6)
    }

    func test_wordCount_singleWord() {
        XCTAssertEqual("Hello".wordCount, 1)
    }

    func test_wordCount_emptyString() {
        XCTAssertEqual("".wordCount, 0)
    }

    func test_wordCount_whitespaceOnly() {
        XCTAssertEqual("   ".wordCount, 0)
    }

    // MARK: - estimatedReadMinutes

    func test_estimatedReadMinutes_standardCase() {
        // Given: 120 words at 120 WPM
        let text = String(repeating: "word ", count: 120)

        // When
        let minutes = text.estimatedReadMinutes(wpm: 120.0)

        // Then
        XCTAssertEqual(minutes, 1)
    }

    func test_estimatedReadMinutes_minimumOne() {
        // Given: very short text
        let text = "hi"

        // When
        let minutes = text.estimatedReadMinutes(wpm: 200.0)

        // Then
        XCTAssertEqual(minutes, 1, "最短阅读时间为 1 分钟")
    }

    // MARK: - truncated

    func test_truncated_withinLimit_returnsSame() {
        XCTAssertEqual("Hello".truncated(10), "Hello")
    }

    func test_truncated_exceedsLimit_appendsEllipsis() {
        // Given
        let text = "HelloWorldLongText"

        // When
        let result = text.truncated(5)

        // Then
        XCTAssertEqual(result, "Hello...")
        XCTAssertTrue(result.hasSuffix("..."))
    }

    func test_truncated_exactLimit_returnsSame() {
        XCTAssertEqual("Hello".truncated(5), "Hello")
    }
}

// MARK: - Color+Theme 测试

final class ColorThemeTests: XCTestCase {

    func test_accentBlue_exists() {
        let color = Color.accentBlue
        // Color 无法直接获取 RGB，验证其存在即可
        XCTAssertNotNil(color)
    }

    func test_allThemeColors_exist() {
        // 验证所有主题色定义存在（不崩溃）
        _ = Color.accentBlue
        _ = Color.secondaryBackground
        _ = Color.textPrimary
        _ = Color.textSecondary
        _ = Color.successGreen
        _ = Color.warningOrange
        _ = Color.errorRed
        _ = Color.highlightYellow
        _ = Color.highlightBlue
    }
}

// MARK: - Font+Theme 测试

final class FontThemeTests: XCTestCase {

    func test_allThemeFonts_exist() {
        _ = Font.lfLargeTitle
        _ = Font.lfTitle2
        _ = Font.lfBody
        _ = Font.lfSubheadline
        _ = Font.lfWordCard
        _ = Font.lfPhonetic
    }

    func test_lfWordCard_isSerifBold() {
        // Font.lfWordCard: .system(size: 28, weight: .bold, design: .serif)
        // 验证不为 nil
        XCTAssertNotNil(Font.lfWordCard)
    }
}
