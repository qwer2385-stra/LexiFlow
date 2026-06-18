import SwiftUI
import CoreData
import Charts

/// 统计页面 — 学习数据可视化
struct StatsView: View {

    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - State

    @StateObject private var viewModel = StatsViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 时间范围切换
                    timeRangePicker

                    // 概览卡片
                    overviewCards

                    // 学习时长柱状图
                    durationChartSection

                    // WPM 趋势
                    wpmChartSection

                    // 词汇增长
                    vocabularyChartSection
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("学习统计")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadStats(context: viewContext)
            }
        }
    }

    // MARK: - Time Range

    private var timeRangePicker: some View {
        Picker("时间范围", selection: $viewModel.timeRange) {
            ForEach(StatsTimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.timeRange) { newRange in
            viewModel.changeTimeRange(newRange, context: viewContext)
        }
    }

    // MARK: - Overview Cards

    private var overviewCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            overviewCard(
                title: "总时长",
                value: "\(viewModel.totalMinutes) 分钟",
                icon: "clock.fill",
                color: .accentBlue
            )
            overviewCard(
                title: "日均",
                value: String(format: "%.0f 分钟", viewModel.averageDailyMinutes),
                icon: "calendar",
                color: .successGreen
            )
            overviewCard(
                title: "打卡",
                value: "\(viewModel.completedDays) 天",
                icon: "flame.fill",
                color: .warningOrange
            )
            overviewCard(
                title: "连续",
                value: "\(viewModel.weeklyReport?.streakDays ?? 0) 天",
                icon: "arrow.triangle.2.circlepath",
                color: .errorRed
            )
        }
    }

    private func overviewCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondaryBackground.opacity(0.6))
        )
    }

    // MARK: - Duration Chart

    private var durationChartSection: some View {
        chartSection(title: "学习时长（分钟）", icon: "clock") {
            if #available(iOS 16.0, *) {
                Chart(viewModel.dailyStats) { stat in
                    BarMark(
                        x: .value("日期", stat.date, unit: .day),
                        y: .value("时长", stat.durationSeconds / 60)
                    )
                    .foregroundStyle(Color.accentBlue.gradient)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
            } else {
                Text("需要 iOS 16+")
                    .foregroundColor(.textSecondary)
            }
        }
    }

    // MARK: - WPM Chart

    private var wpmChartSection: some View {
        chartSection(title: "阅读速度 (WPM)", icon: "speedometer") {
            if #available(iOS 16.0, *) {
                Chart(viewModel.wpmTrend, id: \.0) { item in
                    LineMark(
                        x: .value("日期", item.0, unit: .day),
                        y: .value("WPM", item.1)
                    )
                    .foregroundStyle(Color.successGreen.gradient)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("日期", item.0, unit: .day),
                        y: .value("WPM", item.1)
                    )
                    .foregroundStyle(Color.successGreen)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
            }
        }
    }

    // MARK: - Vocabulary Chart

    private var vocabularyChartSection: some View {
        chartSection(title: "词汇量增长", icon: "text.book.closed") {
            if #available(iOS 16.0, *) {
                Chart(viewModel.vocabularyGrowth, id: \.0) { item in
                    AreaMark(
                        x: .value("日期", item.0, unit: .day),
                        y: .value("词汇量", item.1)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.warningOrange.opacity(0.4), Color.warningOrange.opacity(0.0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("日期", item.0, unit: .day),
                        y: .value("词汇量", item.1)
                    )
                    .foregroundStyle(Color.warningOrange.gradient)
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
            }
        }
    }

    // MARK: - Chart Section Wrapper

    private func chartSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentBlue)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.textPrimary)
            }

            content()
                .frame(height: 160)

            if viewModel.dailyStats.isEmpty {
                Text("暂无数据")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    StatsView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
