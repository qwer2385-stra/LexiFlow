import SwiftUI
import CoreData

/// 文章阅读器页面
struct ArticleReaderView: View {

    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @StateObject private var viewModel = ArticleReaderViewModel()
    @State private var showTranslation = false
    @State private var showWordBook = false

    /// 传入的文章（如果从列表进入）
    let article: ArticleMO?

    // MARK: - Init

    init(article: ArticleMO? = nil) {
        self.article = article
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 文章头部信息
                articleHeader

                Divider()

                // 正文内容
                if let content = viewModel.articleContent {
                    // 使用预构建的 AttributedString 渲染
                    Text(content.attributedBody)
                        .font(.lfBody)
                        .lineSpacing(6)
                        .textSelection(.enabled)
                        .padding(.horizontal, 4)
                } else {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "暂无文章",
                        description: "请选择一篇文章开始阅读"
                    )
                }

                // 阅读统计
                if viewModel.isReading || viewModel.wpm > 0 {
                    readingStats
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.articleContent?.title ?? "文章阅读")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                bottomToolbar
            }
        }
        .sheet(isPresented: $viewModel.showWordDetail) {
            WordDetailSheet(
                wordText: viewModel.selectedWordID ?? "",
                isPresented: $viewModel.showWordDetail
            )
        }
        .onAppear {
            loadArticle()
        }
    }

    // MARK: - Article Header

    private var articleHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let article = article {
                HStack {
                    Label(article.source, systemImage: "newspaper")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    Spacer()

                    Label("Lv.\(article.difficultyLevel)", systemImage: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(.accentBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentBlue.opacity(0.1))
                        .clipShape(Capsule())
                }

                if let content = viewModel.articleContent {
                    HStack(spacing: 16) {
                        Label("\(content.wordCount) 词", systemImage: "text.word.spacing")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Label("约 \(content.estimatedReadMinutes) 分钟", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Reading Stats

    private var readingStats: some View {
        HStack(spacing: 20) {
            VStack(spacing: 2) {
                Text(String(format: "%.0f", viewModel.wpm))
                    .font(.title2.bold())
                    .foregroundColor(.accentBlue)
                Text("WPM")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }

            Divider().frame(height: 30)

            VStack(spacing: 2) {
                Text(viewModel.isReading ? "阅读中..." : "已暂停")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text("速度")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondaryBackground)
        )
    }

    // MARK: - Bottom Toolbar

    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        ToolbarItem(placement: .status) {
            HStack(spacing: 24) {
                // 开始/暂停阅读
                Button {
                    if viewModel.isReading {
                        viewModel.pauseReading()
                    } else {
                        viewModel.startReading()
                    }
                } label: {
                    Label(
                        viewModel.isReading ? "暂停" : "开始计时",
                        systemImage: viewModel.isReading ? "pause.circle.fill" : "play.circle.fill"
                    )
                    .font(.subheadline)
                }

                Spacer()

                // 完成阅读
                Button {
                    completeReading()
                } label: {
                    Label("完成阅读", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentBlue)
                }
                .disabled(viewModel.articleContent == nil)
            }
        }
    }

    // MARK: - Actions

    private func loadArticle() {
        guard let article = article else {
            // 加载示例文章
            viewModel.loadRawContent(
                content: """
                Artificial intelligence is rapidly changing how people learn new languages. \
                Recent advances in natural language processing have made it possible for \
                applications to provide personalized feedback on pronunciation, grammar, \
                and vocabulary usage. Students can now practice conversations with AI tutors \
                that adapt to their proficiency level and learning style. The technology \
                analyzes speech patterns and provides immediate corrections, helping learners \
                improve their skills more efficiently than traditional methods.
                """,
                articleID: UUID(),
                title: "AI Breakthroughs in Language Learning",
                cetLevel: "CET4"
            )
            return
        }
        viewModel.loadArticle(article: article)
    }

    private func completeReading() {
        // 获取当前用户
        let userRequest = UserMO.fetchRequest()
        userRequest.fetchLimit = 1
        guard let user = try? viewContext.fetch(userRequest).first else { return }

        // 获取今日进度
        let progressRequest = DailyProgressMO.fetchRequest()
        progressRequest.predicate = NSPredicate(format: "date == %@", Date().startOfDay as NSDate)
        progressRequest.fetchLimit = 1
        let todayProgress = try? viewContext.fetch(progressRequest).first

        viewModel.completeReadingAndRecord(
            stage: 1,
            context: viewContext,
            user: user,
            todayProgress: todayProgress
        )
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ArticleReaderView()
            .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
    }
}
