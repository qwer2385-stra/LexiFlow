import Foundation
import CoreData

/// 考试记录实体
@objc(ExamAttemptMO)
public class ExamAttemptMO: NSManagedObject {}

extension ExamAttemptMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExamAttemptMO> {
        return NSFetchRequest<ExamAttemptMO>(entityName: "ExamAttemptMO")
    }

    @NSManaged public var id: UUID
    /// 考试日期
    @NSManaged public var date: Date
    /// 总题数
    @NSManaged public var totalQuestions: Int
    /// 正确数
    @NSManaged public var correctCount: Int
    /// 得分（百分制）
    @NSManaged public var score: Double
    /// 用时（秒）
    @NSManaged public var timeUsedSeconds: Int
    /// 题目结果 JSON
    @NSManaged public var questionResultsJSON: String
    /// 错题分类 JSON
    @NSManaged public var errorCategoriesJSON: String

    // MARK: - Relationships

    /// 所属用户
    @NSManaged public var user: UserMO?
}

extension ExamAttemptMO: Identifiable {}
