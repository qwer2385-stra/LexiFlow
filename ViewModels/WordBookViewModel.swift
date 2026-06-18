import Foundation
import CoreData

// MARK: - 单词筛选

enum WordFilter: String, CaseIterable {
    case all = "全部"
    case todayAdded = "今日新增"
    case dueForReview = "待复习"
    case mastered = "已掌握"
}

// MARK: - 单词本 ViewModel

final class WordBookViewModel: ObservableObject {

    // MARK: - Published

    /// 单词列表
    @Published var words: [UserWordMO] = []
    /// 搜索关键词
    @Published var searchQuery: String = ""
    /// 当前筛选
    @Published var filter: WordFilter = .all
    /// 是否加载中
    @Published var isLoading: Bool = false

    // MARK: - Services

    private let srsService = SRSService()

    // MARK: - 加载单词

    func loadWords(context: NSManagedObjectContext, user: UserMO) {
        isLoading = true
        defer { isLoading = false }

        let request = UserWordMO.fetchRequest()
        var predicates: [NSPredicate] = [
            NSPredicate(format: "user == %@", user)
        ]

        // 根据筛选添加条件
        switch filter {
        case .all:
            break
        case .todayAdded:
            let todayStart = Date().startOfDay
            predicates.append(NSPredicate(format: "addedAt >= %@", todayStart as NSDate))
        case .dueForReview:
            predicates.append(NSPredicate(format: "nextReviewDate <= %@ AND isMastered == NO", Date() as NSDate))
        case .mastered:
            predicates.append(NSPredicate(format: "isMastered == YES"))
        }

        // 搜索关键词
        if !searchQuery.isBlank {
            predicates.append(NSPredicate(format: "word.text CONTAINS[cd] %@", searchQuery.trimmed))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(key: "addedAt", ascending: false)
        ]

        do {
            words = try context.fetch(request)
        } catch {
            print("加载单词失败: \(error)")
            words = []
        }
    }

    // MARK: - 搜索

    func search(context: NSManagedObjectContext, user: UserMO) {
        loadWords(context: context, user: user)
    }

    // MARK: - 操作

    /// 切换掌握状态
    func toggleMastered(wordID: UUID, context: NSManagedObjectContext) {
        guard let index = words.firstIndex(where: { $0.id == wordID }) else { return }
        words[index].isMastered.toggle()
        do {
            try context.save()
            words.remove(at: index)
        } catch {
            print("切换掌握状态失败: \(error)")
        }
    }

    /// 删除单词
    func removeWord(wordID: UUID, context: NSManagedObjectContext) {
        guard let index = words.firstIndex(where: { $0.id == wordID }) else { return }
        let word = words[index]
        context.delete(word)
        do {
            try context.save()
            words.remove(at: index)
        } catch {
            print("删除单词失败: \(error)")
        }
    }

    /// 切换筛选并重新加载
    func changeFilter(_ newFilter: WordFilter, context: NSManagedObjectContext, user: UserMO) {
        filter = newFilter
        loadWords(context: context, user: user)
    }

    /// 获取待复习数量
    func getDueCount(context: NSManagedObjectContext) -> Int {
        return srsService.getDueCount(context: context)
    }
}
