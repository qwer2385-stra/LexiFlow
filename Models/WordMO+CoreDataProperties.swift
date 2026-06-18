import Foundation
import CoreData

/// 单词实体（词库）
@objc(WordMO)
public class WordMO: NSManagedObject {}

extension WordMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WordMO> {
        return NSFetchRequest<WordMO>(entityName: "WordMO")
    }

    @NSManaged public var id: UUID
    /// 单词文本
    @NSManaged public var text: String
    /// 音标
    @NSManaged public var phonetic: String
    /// 词性（n./v./adj./adv. 等）
    @NSManaged public var partOfSpeech: String
    /// 释义
    @NSManaged public var definition: String
    /// 例句
    @NSManaged public var exampleSentence: String
    /// 句子结构分析
    @NSManaged public var sentenceStructure: String
    /// CET 等级
    @NSManaged public var cetLevel: String
    /// 频率排名
    @NSManaged public var frequencyRank: Int

    // MARK: - Relationships

    /// 关联的用户单词（一对一）
    @NSManaged public var userWord: UserWordMO?
}

extension WordMO: Identifiable {}
