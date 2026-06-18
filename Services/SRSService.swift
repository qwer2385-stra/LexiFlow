import Foundation
import CoreData

// MARK: - SRS 难度评级

enum SRSDifficulty {
    case easy    // 简单：stage+1, ef×1.3
    case good    // 良好：stage+1, ef×1
    case hard    // 困难：stage-1(min 0), ef×0.85(min 1.3)

    var label: String {
        switch self {
        case .easy: return "简单"
        case .good: return "良好"
        case .hard: return "困难"
        }
    }
}

// MARK: - SRS 计算结果

struct SRSResult {
    let newStage: Int
    let newEaseFactor: Double
    let nextReviewDate: Date
    let isMastered: Bool
}

// MARK: - SRS 服务

/// 间隔重复系统服务，管理复习计划和难度调整
final class SRSService {

    // MARK: - 获取待复习卡片

    /// 获取当前到期的所有用户单词
    func getDueCards(context: NSManagedObjectContext) -> [UserWordMO] {
        let request = UserWordMO.fetchRequest()
        request.predicate = NSPredicate(format: "nextReviewDate <= %@ AND isMastered == NO", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "nextReviewDate", ascending: true)]
        do {
            return try context.fetch(request)
        } catch {
            print("获取待复习卡片失败: \(error)")
            return []
        }
    }

    /// 获取待复习卡片数量
    func getDueCount(context: NSManagedObjectContext) -> Int {
        let request = UserWordMO.fetchRequest()
        request.predicate = NSPredicate(format: "nextReviewDate <= %@ AND isMastered == NO", Date() as NSDate)
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }

    // MARK: - 判断是否到期

    /// 检查用户单词是否需要复习
    func isDueForReview(_ userWord: UserWordMO) -> Bool {
        guard !userWord.isMastered else { return false }
        return userWord.nextReviewDate <= Date()
    }

    // MARK: - 计算下次复习

    /// 根据当前阶段、难度和简易因子计算下次复习时间
    func calculateNextReview(
        currentStage: Int,
        difficulty: SRSDifficulty,
        easeFactor: Double
    ) -> SRSResult {
        var newStage = currentStage
        var newEF = easeFactor
        var isMastered = false

        switch difficulty {
        case .easy:
            newStage = currentStage + 1
            newEF = easeFactor * 1.3
        case .good:
            newStage = currentStage + 1
            // ef 不变
        case .hard:
            newStage = max(0, currentStage - 1)
            newEF = max(AppConstants.minEaseFactor, easeFactor * 0.85)
        }

        // stage >= 6 视为已掌握
        if newStage >= 6 {
            isMastered = true
        }

        // 计算下次复习日期
        let interval = AppConstants.srsIntervals[newStage] ?? AppConstants.defaultSRSInterval
        let adjustedInterval = interval * newEF
        let nextDate = Date().addingTimeInterval(adjustedInterval)

        return SRSResult(
            newStage: newStage,
            newEaseFactor: newEF,
            nextReviewDate: nextDate,
            isMastered: isMastered
        )
    }

    // MARK: - 应用复习结果

    /// 更新用户单词的 SRS 状态
    func applyReview(
        userWord: UserWordMO,
        difficulty: SRSDifficulty,
        context: NSManagedObjectContext
    ) {
        let result = calculateNextReview(
            currentStage: userWord.srsStage,
            difficulty: difficulty,
            easeFactor: userWord.easeFactor
        )

        userWord.srsStage = result.newStage
        userWord.easeFactor = result.newEaseFactor
        userWord.nextReviewDate = result.nextReviewDate
        userWord.reviewCount += 1

        if difficulty == .easy || difficulty == .good {
            userWord.consecutiveCorrect += 1
        } else {
            userWord.consecutiveCorrect = 0
        }

        if result.isMastered {
            userWord.isMastered = true
        }

        do {
            try context.save()
        } catch {
            print("保存 SRS 结果失败: \(error)")
        }
    }
}
