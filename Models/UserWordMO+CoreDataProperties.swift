import Foundation
import CoreData

/// 用户单词（用户与单词的关联，含 SRS 状态）
@objc(UserWordMO)
public class UserWordMO: NSManagedObject {}

extension UserWordMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserWordMO> {
        return NSFetchRequest<UserWordMO>(entityName: "UserWordMO")
    }

    @NSManaged public var id: UUID
    /// 加入时间
    @NSManaged public var addedAt: Date
    /// SRS 阶段
    @NSManaged public var srsStage: Int
    /// 下次复习日期
    @NSManaged public var nextReviewDate: Date
    /// 简易因子（默认 2.5）
    @NSManaged public var easeFactor: Double
    /// 复习次数
    @NSManaged public var reviewCount: Int
    /// 连续正确次数
    @NSManaged public var consecutiveCorrect: Int
    /// 是否已掌握
    @NSManaged public var isMastered: Bool

    // MARK: - Relationships

    /// 所属用户
    @NSManaged public var user: UserMO?
    /// 关联的单词
    @NSManaged public var word: WordMO?
}

extension UserWordMO: Identifiable {}
