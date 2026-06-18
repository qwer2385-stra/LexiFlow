import Foundation
import CoreData

/// 文章实体
@objc(ArticleMO)
public class ArticleMO: NSManagedObject {}

extension ArticleMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArticleMO> {
        return NSFetchRequest<ArticleMO>(entityName: "ArticleMO")
    }

    @NSManaged public var id: UUID
    /// 文章标题
    @NSManaged public var title: String
    /// 原始内容（纯文本）
    @NSManaged public var rawContent: String
    /// 单词数
    @NSManaged public var wordCount: Int
    /// 难度等级
    @NSManaged public var difficultyLevel: Int
    /// 来源
    @NSManaged public var source: String
    /// 发布日期
    @NSManaged public var publishDate: Date
    /// 是否已读
    @NSManaged public var isRead: Bool

    // MARK: - Relationships

    /// 关联的学习记录
    @NSManaged public var learningRecords: Set<LearningRecordMO>?
}

extension ArticleMO: Identifiable {}
