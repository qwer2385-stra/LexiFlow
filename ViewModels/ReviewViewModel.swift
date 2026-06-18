import Foundation
import CoreData

// MARK: - 复习会话状态

enum ReviewSessionState {
    case idle      // 未开始
    case active    // 进行中
    case completed // 已完成
}

// MARK: - 复习 ViewModel

final class ReviewViewModel: ObservableObject {

    // MARK: - Published

    /// 卡片栈
    @Published var cardStack: [ReviewCard] = []
    /// 当前卡片索引
    @Published var currentIndex: Int = 0
    /// 总卡片数
    @Published var totalCards: Int = 0
    /// 已复习数量
    @Published var reviewedCount: Int = 0
    /// 会话状态
    @Published var sessionState: ReviewSessionState = .idle

    // MARK: - 统计数据

    var correctCount: Int = 0
    var incorrectCount: Int = 0

    // MARK: - Services

    private let srsService = SRSService()

    // MARK: - 当前卡片

    var currentCard: ReviewCard? {
        guard currentIndex < cardStack.count else { return nil }
        return cardStack[currentIndex]
    }

    var progress: Double {
        guard totalCards > 0 else { return 0 }
        return Double(reviewedCount) / Double(totalCards)
    }

    // MARK: - 加载待复习卡片

    func loadDueCards(context: NSManagedObjectContext) {
        let dueWords = srsService.getDueCards(context: context)

        cardStack = dueWords.compactMap { userWord in
            guard let word = userWord.word else { return nil }
            return ReviewCard(
                userWordID: userWord.id,
                wordText: word.text,
                definition: word.definition,
                exampleSentence: word.exampleSentence,
                phonetic: word.phonetic,
                srsStage: userWord.srsStage,
                isFlipped: false
            )
        }

        totalCards = cardStack.count
        currentIndex = 0
        reviewedCount = 0
        correctCount = 0
        incorrectCount = 0

        sessionState = cardStack.isEmpty ? .completed : .active
    }

    // MARK: - 翻转卡片

    func flipCurrentCard() {
        guard currentIndex < cardStack.count else { return }
        cardStack[currentIndex].isFlipped.toggle()
    }

    // MARK: - 评分

    /// 对当前卡片评分
    func rateCard(_ difficulty: SRSDifficulty, context: NSManagedObjectContext) {
        guard currentIndex < cardStack.count else { return }
        let card = cardStack[currentIndex]

        // 查找对应的 UserWordMO
        let request = UserWordMO.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", card.userWordID as CVarArg)
        request.fetchLimit = 1

        do {
            if let userWord = try context.fetch(request).first {
                srsService.applyReview(userWord: userWord, difficulty: difficulty, context: context)
            }
        } catch {
            print("保存复习结果失败: \(error)")
        }

        // 统计
        if difficulty == .easy || difficulty == .good {
            correctCount += 1
        } else {
            incorrectCount += 1
        }

        reviewedCount += 1
        nextCard()
    }

    // MARK: - 下一张

    func nextCard() {
        currentIndex += 1
        if currentIndex >= cardStack.count {
            sessionState = .completed
        }
    }

    // MARK: - 重置

    func reset() {
        cardStack = []
        currentIndex = 0
        totalCards = 0
        reviewedCount = 0
        correctCount = 0
        incorrectCount = 0
        sessionState = .idle
    }
}
