import Foundation
import CoreData

/// 学习记录实体
@objc(LearningRecordMO)
public class LearningRecordMO: NSManagedObject {}

extension LearningRecordMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LearningRecordMO> {
        return NSFetchRequest<LearningRecordMO>(entityName: "LearningRecordMO")
    }

    @NSManaged public var id: UUID
    /// 记录日期
    @NSManaged public var date: Date
    /// 所属学习阶段编号
    @NSManaged public var stage: Int
    /// 阶段名称
    @NSManaged public var stageName: String
    /// 学习时长（秒）
    @NSManaged public var durationSeconds: Int
    /// WPM（每分钟词数）
    @NSManaged public var wpm: Double
    /// 理解率（0.0~1.0）
    @NSManaged public var comprehensionRate: Double

    // MARK: - Relationships

    /// 所属用户
    @NSManaged public var user: UserMO?
    /// 关联文章
    @NSManaged public var article: ArticleMO?
    /// 所属每日进度
    @NSManaged public var dailyProgress: DailyProgressMO?
}

extension LearningRecordMO: Identifiable {}
