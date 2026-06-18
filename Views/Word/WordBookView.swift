import SwiftUI
import CoreData

/// 单词本页面
struct WordBookView: View {

    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - State

    @StateObject private var viewModel = WordBookViewModel()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserMO.createdAt, ascending: true)],
        animation: .default
    ) private var users: FetchedResults<UserMO>

    private var currentUser: UserMO? { users.first }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $viewModel.searchQuery) {
                    if let user = currentUser {
                        viewModel.search(context: viewContext, user: user)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // 分段筛选器
                Picker("筛选", selection: $viewModel.filter) {
                    ForEach(WordFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .onChange(of: viewModel.filter) { newFilter in
                    if let user = currentUser {
                        viewModel.changeFilter(newFilter, context: viewContext, user: user)
                    }
                }

                // 单词列表
                if viewModel.words.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: emptyTitle,
                        description: emptyDescription
                    )
                } else {
                    List {
                        ForEach(viewModel.words) { userWord in
                            WordCard(
                                wordText: userWord.word?.text ?? "",
                                definition: userWord.word?.definition ?? "",
                                phonetic: userWord.word?.phonetic,
                                date: userWord.addedAt,
                                srsStage: userWord.srsStage,
                                isMastered: userWord.isMastered
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.removeWord(wordID: userWord.id, context: viewContext)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }

                                Button {
                                    viewModel.toggleMastered(wordID: userWord.id, context: viewContext)
                                } label: {
                                    Label(
                                        userWord.isMastered ? "取消掌握" : "已掌握",
                                        systemImage: "checkmark.seal"
                                    )
                                }
                                .tint(.successGreen)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        if let user = currentUser {
                            viewModel.loadWords(context: viewContext, user: user)
                        }
                    }
                }
            }
            .navigationTitle("单词本")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let user = currentUser {
                    viewModel.loadWords(context: viewContext, user: user)
                }
            }
            .onChange(of: viewModel.searchQuery) { _ in
                if let user = currentUser {
                    viewModel.search(context: viewContext, user: user)
                }
            }
        }
    }

    // MARK: - Empty state text

    private var emptyTitle: String {
        switch viewModel.filter {
        case .all: return "还没有单词"
        case .todayAdded: return "今日暂无新增"
        case .dueForReview: return "暂无待复习单词"
        case .mastered: return "暂无已掌握单词"
        }
    }

    private var emptyDescription: String {
        switch viewModel.filter {
        case .all: return "阅读文章时点击高亮单词，即可加入单词本。"
        case .todayAdded: return "今天阅读文章并添加新单词吧！"
        case .dueForReview: return "所有单词都已复习完毕，真棒！"
        case .mastered: return "继续学习，掌握更多单词！"
        }
    }
}

// MARK: - Preview

#Preview {
    WordBookView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
