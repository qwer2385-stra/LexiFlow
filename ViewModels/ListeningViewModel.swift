import Foundation
import CoreData

/// 听力训练 ViewModel
final class ListeningViewModel: ObservableObject {

    // MARK: - Published

    /// 音频是否正在播放
    @Published var isPlaying: Bool = false
    /// 播放进度（0.0 ~ 1.0）
    @Published var progress: Double = 0
    /// 当前时间（秒）
    @Published var currentTime: TimeInterval = 0
    /// 总时长（秒）
    @Published var totalDuration: TimeInterval = 0
    /// 字幕文本
    @Published var subtitle: String = ""
    /// 高亮字幕索引
    @Published var highlightedSubtitleIndex: Int = 0
    /// 理解题列表
    @Published var comprehensionQuestions: [ExamQuestion] = []
    /// 已答题目数
    @Published var answeredQuestionCount: Int = 0
    /// 正确题目数
    @Published var correctQuestionCount: Int = 0
    /// 是否加载中
    @Published var isLoading: Bool = false

    // MARK: - TTS

    private let ttsManager = TTSManager()

    // MARK: - 听力内容

    /// 当前听力文本
    var listeningText: String = """
    Good morning, everyone. Today we're going to talk about the importance of \
    daily practice in language learning. Research shows that consistent, short \
    practice sessions are more effective than long, infrequent ones. The key is \
    to make language learning a habit, just like brushing your teeth. Even fifteen \
    minutes a day can make a significant difference over time. Let's explore some \
    practical strategies to incorporate English learning into your daily routine.
    """

    /// 字幕分段
    var subtitleSegments: [String] {
        listeningText.components(separatedBy: ". ")
            .filter { !$0.isEmpty }
            .map { $0.hasSuffix(".") ? $0 : $0 + "." }
    }

    // MARK: - 播放控制

    func togglePlayback() {
        if isPlaying {
            ttsManager.pause()
        } else {
            if currentTime == 0 {
                ttsManager.speak(text: listeningText)
            } else {
                ttsManager.resume()
            }
        }
        isPlaying.toggle()
    }

    func stop() {
        ttsManager.stop()
        isPlaying = false
        currentTime = 0
        progress = 0
        highlightedSubtitleIndex = 0
    }

    // MARK: - 进度更新

    /// 模拟更新播放进度
    func updateProgress(elapsed: TimeInterval) {
        currentTime = elapsed
        if totalDuration > 0 {
            progress = min(1.0, elapsed / totalDuration)
        }
        // 更新高亮字幕
        let segmentProgress = subtitleSegments.isEmpty ? 0 : Double(subtitleSegments.count) * progress
        highlightedSubtitleIndex = min(Int(segmentProgress), subtitleSegments.count - 1)
    }

    // MARK: - 理解题

    /// 生成理解题
    func loadComprehensionQuestions() {
        comprehensionQuestions = [
            ExamQuestion(
                id: UUID(),
                questionText: "According to the passage, which type of practice is most effective?",
                options: [
                    "Long, infrequent sessions",
                    "Consistent, short sessions",
                    "Weekend-only study",
                    "Monthly intensive courses"
                ],
                correctIndex: 1,
                explanation: "The passage states that 'consistent, short practice sessions are more effective than long, infrequent ones.'",
                category: "comprehension"
            ),
            ExamQuestion(
                id: UUID(),
                questionText: "How much daily practice time is suggested as beneficial?",
                options: ["5 minutes", "15 minutes", "1 hour", "2 hours"],
                correctIndex: 1,
                explanation: "The passage mentions 'Even fifteen minutes a day can make a significant difference.'",
                category: "comprehension"
            ),
            ExamQuestion(
                id: UUID(),
                questionText: "Language learning should be made into a ______.",
                options: ["game", "habit", "challenge", "competition"],
                correctIndex: 1,
                explanation: "The passage says 'make language learning a habit, just like brushing your teeth.'",
                category: "comprehension"
            ),
        ]
        answeredQuestionCount = 0
        correctQuestionCount = 0
    }

    /// 回答问题
    func answerQuestion(index: Int, selectedAnswer: Int) {
        guard index < comprehensionQuestions.count else { return }
        guard !comprehensionQuestions[index].isAnswered else { return }

        comprehensionQuestions[index].userSelectedIndex = selectedAnswer
        answeredQuestionCount += 1
        if comprehensionQuestions[index].isCorrect {
            correctQuestionCount += 1
        }
    }

    // MARK: - 模拟时长

    func estimateTotalDuration() {
        // 粗略估计：每分钟约 150 词
        let wordCount = listeningText.wordCount
        totalDuration = Double(wordCount) / 150.0 * 60.0
    }

    // MARK: - 加载

    func load(context: NSManagedObjectContext) {
        isLoading = true
        estimateTotalDuration()
        loadComprehensionQuestions()
        isLoading = false
    }
}
