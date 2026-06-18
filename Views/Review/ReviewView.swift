import SwiftUI
import CoreData

/// 复习页面
struct ReviewView: View {

    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - State

    @StateObject private var viewModel = ReviewViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                switch viewModel.sessionState {
                case .idle:
                    idleView
                case .active:
                    activeReviewView
                case .completed:
                    completedView
                }
            }
            .navigationTitle("复习")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadDueCards(context: viewContext)
            }
        }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: 20) {
            Spacer()

            EmptyStateView(
                icon: "arrow.triangle.2.circlepath",
                title: "准备开始复习",
                description: "加载待复习卡片中...",
                actionTitle: "开始复习",
                action: {
                    viewModel.loadDueCards(context: viewContext)
                }
            )

            Spacer()
        }
    }

    // MARK: - Active Review

    private var activeReviewView: some View {
        VStack(spacing: 0) {
            // 进度条
            progressBar
                .padding(.horizontal)
                .padding(.top, 12)

            Spacer()

            // 翻转卡片
            if let card = viewModel.currentCard {
                FlipCardView(isFlipped: Binding(
                    get: { viewModel.cardStack[viewModel.currentIndex].isFlipped },
                    set: { viewModel.cardStack[viewModel.currentIndex].isFlipped = $0 }
                )) {
                    // 正面：单词 + 音标
                    cardFront(card: card)
                } back: {
                    // 背面：释义 + 例句
                    cardBack(card: card)
                }
                .frame(height: 280)
                .padding(.horizontal, 24)
            }

            Spacer()

            // 难度按钮
            DifficultyButton(selectedDifficulty: .constant(nil)) { difficulty in
                viewModel.rateCard(difficulty, context: viewContext)
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Card Front

    private func cardFront(card: ReviewCard) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            .overlay(
                VStack(spacing: 16) {
                    Text(card.wordText)
                        .font(.lfWordCard)
                        .foregroundColor(.textPrimary)

                    Text(card.phonetic)
                        .font(.lfPhonetic)
                        .foregroundColor(.textSecondary)

                    Text("点击翻转查看释义")
                        .font(.caption)
                        .foregroundColor(.textSecondary.opacity(0.6))
                        .padding(.top, 20)
                }
                .padding(24)
            )
    }

    // MARK: - Card Back

    private func cardBack(card: ReviewCard) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            .overlay(
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "book.pages")
                            .foregroundColor(.accentBlue)
                        Text("释义")
                            .font(.subheadline.bold())
                            .foregroundColor(.textSecondary)
                    }

                    Text(card.definition)
                        .font(.lfBody)
                        .foregroundColor(.textPrimary)

                    Divider()

                    HStack {
                        Image(systemName: "text.quote")
                            .foregroundColor(.accentBlue)
                        Text("例句")
                            .font(.subheadline.bold())
                            .foregroundColor(.textSecondary)
                    }

                    Text(card.exampleSentence)
                        .font(.callout)
                        .foregroundColor(.textPrimary)
                        .italic()
                }
                .padding(24)
            )
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(viewModel.reviewedCount) / \(viewModel.totalCards)")
                    .font(.subheadline.bold())
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("剩余 \(viewModel.totalCards - viewModel.reviewedCount) 张")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondaryBackground)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentBlue)
                        .frame(width: geometry.size.width * viewModel.progress, height: 8)
                        .animation(.easeInOut, value: viewModel.progress)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundColor(.successGreen)

            Text("复习完成！")
                .font(.lfLargeTitle)
                .foregroundColor(.textPrimary)

            VStack(spacing: 8) {
                HStack(spacing: 30) {
                    statItem(value: "\(viewModel.correctCount)", label: "正确", color: .successGreen)
                    statItem(value: "\(viewModel.incorrectCount)", label: "需加强", color: .warningOrange)
                    statItem(value: "\(viewModel.totalCards)", label: "总计", color: .accentBlue)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondaryBackground)
            )
            .padding(.horizontal)

            Button {
                viewModel.reset()
                viewModel.loadDueCards(context: viewContext)
            } label: {
                Text("再来一轮")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentBlue)
                    )
            }

            Spacer()
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
    ReviewView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
