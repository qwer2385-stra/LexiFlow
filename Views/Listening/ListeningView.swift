import SwiftUI
import CoreData

/// 听力训练页面
struct ListeningView: View {

    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - State

    @StateObject private var viewModel = ListeningViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 播放器
                    playerSection

                    // 字幕
                    subtitleSection

                    // 理解题
                    if !viewModel.comprehensionQuestions.isEmpty {
                        comprehensionSection
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("听力训练")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.load(context: viewContext)
            }
        }
    }

    // MARK: - Player

    private var playerSection: some View {
        VStack(spacing: 16) {
            // 进度条
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondaryBackground)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.accentBlue)
                            .frame(width: geometry.size.width * viewModel.progress, height: 6)
                            .animation(.linear, value: viewModel.progress)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text(formatTime(viewModel.currentTime))
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    Spacer()

                    Text(formatTime(viewModel.totalDuration))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            // 播放控制
            HStack(spacing: 40) {
                Button {
                    viewModel.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.textSecondary)
                }

                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.accentBlue)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondaryBackground.opacity(0.5))
        )
    }

    // MARK: - Subtitle

    private var subtitleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("字幕", systemImage: "text.bubble")
                .font(.subheadline.bold())
                .foregroundColor(.textPrimary)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(viewModel.subtitleSegments.enumerated()), id: \.offset) { index, segment in
                        Text(segment)
                            .font(.callout)
                            .foregroundColor(index == viewModel.highlightedSubtitleIndex ? .accentBlue : .textPrimary)
                            .fontWeight(index == viewModel.highlightedSubtitleIndex ? .semibold : .regular)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(index == viewModel.highlightedSubtitleIndex
                                          ? Color.accentBlue.opacity(0.08)
                                          : Color.clear)
                            )
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }

    // MARK: - Comprehension

    private var comprehensionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("理解测试", systemImage: "checklist")
                    .font(.subheadline.bold())
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("\(viewModel.correctQuestionCount) / \(viewModel.answeredQuestionCount)")
                    .font(.caption)
                    .foregroundColor(.accentBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentBlue.opacity(0.1))
                    .clipShape(Capsule())
            }

            ForEach(Array(viewModel.comprehensionQuestions.enumerated()), id: \.element.id) { index, question in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(index + 1). \(question.questionText)")
                        .font(.callout)
                        .foregroundColor(.textPrimary)

                    ForEach(Array(question.options.enumerated()), id: \.offset) { optIndex, option in
                        Button {
                            viewModel.answerQuestion(index: index, selectedAnswer: optIndex)
                        } label: {
                            HStack(spacing: 8) {
                                Text(["A", "B", "C", "D"][optIndex])
                                    .font(.caption.bold())
                                    .foregroundColor(optLetterColor(question: question, optIndex: optIndex))
                                    .frame(width: 20, height: 20)
                                    .background(
                                        Circle()
                                            .fill(optBackgroundColor(question: question, optIndex: optIndex))
                                    )

                                Text(option)
                                    .font(.caption)
                                    .foregroundColor(.textPrimary)

                                Spacer()
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(optBorderColor(question: question, optIndex: optIndex), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(question.isAnswered)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(question.isAnswered
                              ? (question.isCorrect ? Color.successGreen.opacity(0.06) : Color.errorRed.opacity(0.06))
                              : Color.secondaryBackground.opacity(0.4))
                )
            }
        }
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func optLetterColor(question: ExamQuestion, optIndex: Int) -> Color {
        if !question.isAnswered { return .accentBlue }
        if optIndex == question.correctIndex { return .white }
        if optIndex == question.userSelectedIndex { return .white }
        return .textSecondary
    }

    private func optBackgroundColor(question: ExamQuestion, optIndex: Int) -> Color {
        if !question.isAnswered { return Color.accentBlue.opacity(0.15) }
        if optIndex == question.correctIndex { return .successGreen }
        if optIndex == question.userSelectedIndex { return .errorRed }
        return Color.secondaryBackground
    }

    private func optBorderColor(question: ExamQuestion, optIndex: Int) -> Color {
        if !question.isAnswered {
            return question.userSelectedIndex == optIndex ? .accentBlue : .clear
        }
        if optIndex == question.correctIndex { return .successGreen }
        if optIndex == question.userSelectedIndex { return .errorRed }
        return .clear
    }
}

// MARK: - Preview

#Preview {
    ListeningView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
