import SwiftUI
import CoreData

/// 考试页面
struct ExamView: View {

    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - State

    @StateObject private var viewModel = ExamViewModel()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserMO.createdAt, ascending: true)],
        animation: .default
    ) private var users: FetchedResults<UserMO>

    private var currentUser: UserMO? { users.first }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch viewModel.sessionState {
                case .idle:
                    idleView
                case .inProgress:
                    examInProgressView
                case .submitted, .timeout:
                    resultView
                }
            }
            .navigationTitle("模拟考试")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.accentBlue)

            Text("四六级模拟考试")
                .font(.lfLargeTitle)
                .foregroundColor(.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                infoRow(icon: "questionmark.circle", label: "共 \(AppConstants.examQuestionsCount) 题")
                infoRow(icon: "clock", label: "限时 15 分钟")
                infoRow(icon: "tag", label: "涵盖词汇 / 语法 / 阅读理解")
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondaryBackground)
            )

            Button {
                if let user = currentUser {
                    viewModel.startExam(context: viewContext, user: user)
                }
            } label: {
                Text("开始考试")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentBlue)
                    )
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    // MARK: - In Progress

    private var examInProgressView: some View {
        VStack(spacing: 0) {
            // 顶部计时 + 进度
            timerHeader
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            // 题目区域
            if let question = viewModel.currentQuestion {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 题目编号
                        HStack {
                            Text("第 \(viewModel.currentQuestionIndex + 1) 题")
                                .font(.subheadline.bold())
                                .foregroundColor(.accentBlue)

                            Spacer()

                            Text(question.category == "vocabulary" ? "词汇" :
                                 question.category == "sentence" ? "语法" : "理解")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.secondaryBackground)
                                .clipShape(Capsule())
                        }

                        // 题目文字
                        Text(question.questionText)
                            .font(.lfBody)
                            .foregroundColor(.textPrimary)
                            .padding(.vertical, 4)

                        // 选项
                        VStack(spacing: 10) {
                            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                optionButton(index: index, option: option, question: question)
                            }
                        }

                        // 答案解析（已作答后显示）
                        if question.isAnswered {
                            explanationView(question: question)
                        }
                    }
                    .padding()
                }

                // 导航按钮
                navigationButtons
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
            }
        }
    }

    // MARK: - Timer Header

    private var timerHeader: some View {
        HStack {
            // 进度圆点
            HStack(spacing: 6) {
                ForEach(0..<viewModel.totalQuestions, id: \.self) { index in
                    Circle()
                        .fill(dotColor(for: index))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            // 倒计时
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.subheadline)
                Text(viewModel.formattedTime)
                    .font(.title3.bold().monospacedDigit())
            }
            .foregroundColor(viewModel.isTimeUrgent ? .errorRed : .accentBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill((viewModel.isTimeUrgent ? Color.errorRed : Color.accentBlue).opacity(0.1))
            )
        }
    }

    // MARK: - Option Button

    private func optionButton(index: Int, option: String, question: ExamQuestion) -> some View {
        Button {
            viewModel.selectAnswer(index: index)
        } label: {
            HStack(spacing: 12) {
                Text(["A", "B", "C", "D"][index])
                    .font(.subheadline.bold())
                    .foregroundColor(optionLetterColor(index: index, question: question))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(optionBackgroundColor(index: index, question: question))
                    )

                Text(option)
                    .font(.lfBody)
                    .foregroundColor(.textPrimary)

                Spacer()

                if question.isAnswered {
                    if index == question.correctIndex {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.successGreen)
                    } else if index == question.userSelectedIndex {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.errorRed)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(optionBorderColor(index: index, question: question), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(question.isAnswered)
    }

    private func optionLetterColor(index: Int, question: ExamQuestion) -> Color {
        if !question.isAnswered { return .accentBlue }
        if index == question.correctIndex { return .white }
        if index == question.userSelectedIndex && index != question.correctIndex { return .white }
        return .textSecondary
    }

    private func optionBackgroundColor(index: Int, question: ExamQuestion) -> Color {
        if !question.isAnswered { return Color.accentBlue.opacity(0.1) }
        if index == question.correctIndex { return .successGreen }
        if index == question.userSelectedIndex && index != question.correctIndex { return .errorRed }
        return Color.secondaryBackground
    }

    private func optionBorderColor(index: Int, question: ExamQuestion) -> Color {
        if !question.isAnswered {
            return question.userSelectedIndex == index ? .accentBlue : Color.secondaryBackground
        }
        if index == question.correctIndex { return .successGreen }
        if index == question.userSelectedIndex && index != question.correctIndex { return .errorRed }
        return .secondaryBackground
    }

    // MARK: - Explanation

    private func explanationView(question: ExamQuestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: question.isCorrect ? "lightbulb.fill" : "lightbulb.fill")
                    .foregroundColor(question.isCorrect ? .successGreen : .warningOrange)
                Text("解析")
                    .font(.subheadline.bold())
            }

            Text(question.explanation)
                .font(.callout)
                .foregroundColor(.textSecondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(question.isCorrect ? Color.successGreen.opacity(0.08) : Color.warningOrange.opacity(0.08))
        )
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack {
            Button {
                viewModel.previousQuestion()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("上一题")
                }
                .font(.subheadline)
                .foregroundColor(viewModel.currentQuestionIndex > 0 ? .accentBlue : .textSecondary)
            }
            .disabled(viewModel.currentQuestionIndex == 0)

            Spacer()

            if viewModel.currentQuestionIndex < viewModel.totalQuestions - 1 {
                Button {
                    viewModel.nextQuestion()
                } label: {
                    HStack {
                        Text("下一题")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.accentBlue)
                }
            } else {
                Button {
                    if let user = currentUser {
                        viewModel.submitExam(context: viewContext, user: user)
                    }
                } label: {
                    HStack {
                        Text("提交")
                        Image(systemName: "paperplane.fill")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(viewModel.answeredCount == viewModel.totalQuestions ? Color.successGreen : Color.accentBlue)
                    )
                }
            }
        }
    }

    // MARK: - Dot Color

    private func dotColor(for index: Int) -> Color {
        guard index < viewModel.questions.count else { return .textSecondary.opacity(0.2) }
        let question = viewModel.questions[index]
        if question.isAnswered {
            return question.isCorrect ? .successGreen : .errorRed
        }
        if index == viewModel.currentQuestionIndex { return .accentBlue }
        return .textSecondary.opacity(0.3)
    }

    // MARK: - Result View

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // 分数圆环
                ZStack {
                    ProgressRing(
                        progress: viewModel.score / 100.0,
                        lineWidth: 14,
                        size: 160,
                        centerText: "\(Int(viewModel.score))"
                    )
                }

                Text(viewModel.sessionState == .timeout ? "⏰ 时间到！" : "考试完成！")
                    .font(.lfTitle2)
                    .foregroundColor(.textPrimary)

                // 统计
                HStack(spacing: 30) {
                    statItem(value: "\(viewModel.correctCount)/\(viewModel.totalQuestions)", label: "正确率",
                             color: viewModel.score >= 60 ? .successGreen : .errorRed)
                    statItem(value: "\(Int(viewModel.score))分", label: "得分",
                             color: .accentBlue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondaryBackground)
                )

                // 错题列表
                if viewModel.correctCount < viewModel.totalQuestions {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("错题归因", systemImage: "exclamationmark.triangle")
                            .font(.subheadline.bold())
                            .foregroundColor(.warningOrange)

                        let categories = Set(viewModel.questions
                            .filter { !$0.isCorrect }
                            .map { $0.category })

                        ForEach(Array(categories), id: \.self) { category in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.warningOrange)
                                Text(category == "vocabulary" ? "词汇理解" :
                                     category == "sentence" ? "语法结构" : "阅读理解")
                                    .font(.callout)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.warningOrange.opacity(0.06))
                    )
                }

                // 重新开始
                Button {
                    if let user = currentUser {
                        viewModel.startExam(context: viewContext, user: user)
                    }
                } label: {
                    Text("重新开始")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentBlue)
                        )
                }
            }
            .padding()
        }
    }

    private func infoRow(icon: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.accentBlue)
                .frame(width: 20)
            Text(label)
                .font(.callout)
                .foregroundColor(.textPrimary)
        }
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ExamView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
