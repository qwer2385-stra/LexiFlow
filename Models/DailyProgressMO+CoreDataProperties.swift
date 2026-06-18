import Foundation
import CoreData

/// 每日进度实体
@objc(DailyProgressMO)
public class DailyProgressMO: NSManagedObject {}

extension DailyProgressMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyProgressMO> {
        return NSFetchRequest<DailyProgressMO>(entityName: "DailyProgressMO")
    }

    @NSManaged public var id: UUID
    /// 日期
    @NSManaged public var date: Date
    /// 当前阶段
    @NSManaged public var currentStage: Int
    /// 阶段 1（新闻输入）是否完成
    @NSManaged public var stage1Completed: Bool
    /// 阶段 2（精读拆解）是否完成
    @NSManaged public var stage2Completed: Bool
    /// 阶段 3（四六级训练）是否完成
    @NSManaged public var stage3Completed: Bool
    /// 阶段 4（英文输出）是否完成
    @NSManaged public var stage4Completed: Bool
    /// 当日是否全部完成
    @NSManaged public var isDayComplete: Bool
    /// 总学习时长（秒）
    @NSManaged public var totalDurationSeconds: Int

    // MARK: - Relationships

    /// 所属用户
    @NSManaged public var user: UserMO?
    /// 关联的学习记录
    @NSManaged public var learningRecords: Set<LearningRecordMO>?
}

extension DailyProgressMO: Identifiable {}
