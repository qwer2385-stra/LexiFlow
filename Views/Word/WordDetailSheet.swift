import SwiftUI
import CoreData

/// 单词详情 Sheet — 底部弹出
struct WordDetailSheet: View {

    // MARK: - Properties

    let wordText: String
    @Binding var isPresented: Bool

    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - State

    @StateObject private var ttsManager = TTSManager()
    @State private var isInWordBook = false

    /// 当前单词（从 Core Data 查找）
    @FetchRequest private var words: FetchedResults<WordMO>

    // MARK: - Init

    init(wordText: String, isPresented: Binding<Bool>) {
        self.wordText = wordText
        self._isPresented = isPresented
        self._words = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "text ==[c] %@", wordText)
        )
    }

    private var word: WordMO? {
        words.first
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 拖拽指示条
                    dragIndicator

                    // 单词 + 音标 + 发音按钮
                    wordHeader

                    if let word = word {
                        // 词性 + 释义
                        definitionSection(word: word)

                        // 例句
                        exampleSection(word: word)

                        // 句子结构分析
                        structureSection(word: word)
                    } else {
                        // 单词不在词库中
                        basicInfoSection
                    }

                    // 加入单词本按钮
                    addToWordBookButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Subviews

    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.textSecondary.opacity(0.4))
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    private var wordHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(wordText)
                    .font(.lfWordCard)
                    .foregroundColor(.textPrimary)

                if let phonetic = word?.phonetic {
                    Text(phonetic)
                        .font(.lfPhonetic)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            // 发音按钮
            Button {
                ttsManager.speak(text: wordText)
            } label: {
                Image(systemName: ttsManager.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                    .font(.title2)
                    .foregroundColor(.accentBlue)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.accentBlue.opacity(0.1)))
            }
        }
    }

    private func definitionSection(word: WordMO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 词性标签
            HStack(spacing: 6) {
                Text(word.partOfSpeech)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.accentBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentBlue.opacity(0.1))
                    .clipShape(Capsule())

                Text(word.cetLevel)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondaryBackground)
                    .clipShape(Capsule())
            }

            Text(word.definition)
                .font(.lfBody)
                .foregroundColor(.textPrimary)
        }
    }

    private func exampleSection(word: WordMO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("例句", systemImage: "text.quote")
                .font(.subheadline.bold())
                .foregroundColor(.textPrimary)

            Text(word.exampleSentence)
                .font(.lfBody)
                .foregroundColor(.textPrimary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondaryBackground)
                )
        }
    }

    private func structureSection(word: WordMO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("句子结构分析", systemImage: "list.bullet.indent")
                .font(.subheadline.bold())
                .foregroundColor(.textPrimary)

            Text(word.sentenceStructure)
                .font(.callout)
                .foregroundColor(.textSecondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondaryBackground, lineWidth: 1)
                )
        }
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("该单词暂未收录到词库")
                .font(.lfBody)
                .foregroundColor(.textSecondary)

            Text("您仍然可以将它添加到您的单词本中")
                .font(.lfSubheadline)
                .foregroundColor(.textSecondary)
        }
    }

    private var addToWordBookButton: some View {
        Button {
            addToWordBook()
        } label: {
            HStack {
                Image(systemName: isInWordBook ? "bookmark.fill" : "bookmark")
                Text(isInWordBook ? "已在单词本中" : "加入单词本")
            }
            .font(.body.weight(.semibold))
            .foregroundColor(isInWordBook ? .textSecondary : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isInWordBook ? Color.secondaryBackground : Color.accentBlue)
            )
        }
        .disabled(isInWordBook)
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func addToWordBook() {
        guard !isInWordBook else { return }

        // 获取当前用户
        let userRequest = UserMO.fetchRequest()
        userRequest.fetchLimit = 1
        guard let user = try? viewContext.fetch(userRequest).first else { return }

        // 查找或创建 WordMO
        let existingWord: WordMO
        if let w = word {
            existingWord = w
        } else {
            existingWord = WordMO(context: viewContext)
            existingWord.id = UUID()
            existingWord.text = wordText
            existingWord.phonetic = ""
            existingWord.partOfSpeech = ""
            existingWord.definition = ""
            existingWord.exampleSentence = ""
            existingWord.sentenceStructure = ""
            existingWord.cetLevel = "CET4"
            existingWord.frequencyRank = 999
        }

        // 创建 UserWordMO
        let userWord = UserWordMO(context: viewContext)
        userWord.id = UUID()
        userWord.addedAt = Date()
        userWord.srsStage = 0
        userWord.nextReviewDate = Date().addingTimeInterval(AppConstants.srsIntervals[0] ?? 86400)
        userWord.easeFactor = AppConstants.defaultEaseFactor
        userWord.reviewCount = 0
        userWord.consecutiveCorrect = 0
        userWord.isMastered = false
        userWord.user = user
        userWord.word = existingWord

        do {
            try viewContext.save()
            isInWordBook = true
        } catch {
            print("加入单词本失败: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    WordDetailSheet(wordText: "abandon", isPresented: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
