import SwiftUI
import CoreData

/// 首页 — 学习概览与阶段入口
struct HomeView: View {

    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - State

    @StateObject private var viewModel = HomeViewModel()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserMO.createdAt, ascending: true)],
        animation: .default
    ) private var users: FetchedResults<UserMO>

    // MARK: - Computed

    private var currentUser: UserMO? {
        users.first
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    progressSection
                    modulesSection
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("LexiFlow")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                ensureUserExists()
            }
            .refreshable {
                refreshData()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().shortChinese)
                    .font(.lfSubheadline)
                    .foregroundColor(.textSecondary)

                HStack(spacing: 4) {
                    Text("🔥 连续打卡")
                        .font(.lfTitle2)
                    Text("\(viewModel.streakDays) 天")
                        .font(.lfTitle2)
                        .foregroundColor(.accentBlue)
                }
            }

            Spacer()

            // 词汇量
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(viewModel.vocabularyCount)")
                    .font(.title2.bold())
                    .foregroundColor(.textPrimary)
                Text("词汇量")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 8) {
            ProgressRing(
                progress: viewModel.completionPercent,
                lineWidth: 14,
                size: 180,
                centerText: "\(Int(viewModel.completionPercent * 100))%"
            )
            .padding(.vertical, 8)

            // 阶段完成小圆点
            HStack(spacing: 12) {
                ForEach(AppConstants.LearningStage.allCases, id: \.rawValue) { stage in
                    Circle()
                        .fill(dotColor(for: stage))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondaryBackground.opacity(0.5))
        )
    }

    // MARK: - Modules

    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日学习")
                .font(.lfTitle2)
                .padding(.leading, 4)

            ForEach(AppConstants.LearningStage.allCases, id: \.rawValue) { stage in
                ModuleCard(
                    stage: stage.rawValue,
                    icon: stage.icon,
                    name: stage.name,
                    suggestedMinutes: stage.suggestedMinutes,
                    isCompleted: isStageCompleted(stage),
                    isLocked: isStageLocked(stage),
                    isActive: isStageActive(stage),
                    action: { handleStageTap(stage) }
                )
            }
        }
    }

    // MARK: - State Helpers

    private func isStageCompleted(_ stage: AppConstants.LearningStage) -> Bool {
        guard let progress = viewModel.todayProgress else { return false }
        switch stage {
        case .input:       return progress.stage1Completed
        case .interaction: return progress.stage2Completed
        case .memory:      return progress.stage3Completed
        case .output:      return progress.stage4Completed
        }
    }

    private func isStageActive(_ stage: AppConstants.LearningStage) -> Bool {
        guard let progress = viewModel.todayProgress else { return stage == .input }
        return stage.rawValue == progress.currentStage && !isStageCompleted(stage)
    }

    private func isStageLocked(_ stage: AppConstants.LearningStage) -> Bool {
        guard let progress = viewModel.todayProgress else { return stage != .input }
        return stage.rawValue > progress.currentStage
    }

    private func dotColor(for stage: AppConstants.LearningStage) -> Color {
        if isStageCompleted(stage) { return .successGreen }
        if isStageActive(stage) { return .accentBlue }
        return .textSecondary.opacity(0.3)
    }

    // MARK: - Actions

    private func handleStageTap(_ stage: AppConstants.LearningStage) {
        guard !isStageLocked(stage) else { return }
        // 导航由 ContentView 中的 TabView 处理
        // HomeView 本身是首页概览
    }

    // MARK: - Data

    private func ensureUserExists() {
        guard currentUser == nil else {
            if let user = currentUser {
                viewModel.loadTodayProgress(context: viewContext, user: user)
            }
            return
        }

        let newUser = UserMO(context: viewContext)
        newUser.id = UUID()
        newUser.nickname = "学习者"
        newUser.targetDailyMinutes = AppConstants.defaultTargetDailyMinutes
        newUser.targetWeeklyWords = AppConstants.defaultTargetWeeklyWords
        newUser.cetLevel = "CET4"
        newUser.currentDifficultyLevel = 1
        newUser.createdAt = Date()

        do {
            try viewContext.save()
            viewModel.loadTodayProgress(context: viewContext, user: newUser)
        } catch {
            print("创建用户失败: \(error)")
        }
    }

    private func refreshData() {
        if let user = currentUser {
            viewModel.loadTodayProgress(context: viewContext, user: user)
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
