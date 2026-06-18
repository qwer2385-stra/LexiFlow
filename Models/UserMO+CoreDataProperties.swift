import Foundation
import CoreData

/// 用户实体
@objc(UserMO)
public class UserMO: NSManagedObject {}

extension UserMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserMO> {
        return NSFetchRequest<UserMO>(entityName: "UserMO")
    }

    /// 唯一标识
    @NSManaged public var id: UUID
    /// 昵称
    @NSManaged public var nickname: String
    /// 每日目标时长（分钟）
    @NSManaged public var targetDailyMinutes: Int
    /// 每周目标单词数
    @NSManaged public var targetWeeklyWords: Int
    /// CET 等级（"CET4" / "CET6"）
    @NSManaged public var cetLevel: String
    /// 当前难度等级
    @NSManaged public var currentDifficultyLevel: Int
    /// 创建时间
    @NSManaged public var createdAt: Date

    // MARK: - Relationships

    /// 用户单词本
    @NSManaged public var userWords: Set<UserWordMO>?
    /// 学习记录
    @NSManaged public var learningRecords: Set<LearningRecordMO>?
    /// 考试记录
    @NSManaged public var examAttempts: Set<ExamAttemptMO>?
    /// 每日进度
    @NSManaged public var dailyProgresses: Set<DailyProgressMO>?
}

// MARK: - Identifiable

extension UserMO: Identifiable {}
