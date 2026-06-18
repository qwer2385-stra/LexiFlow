import Foundation
import CoreData
import Combine

// MARK: - 考试会话状态

enum ExamSessionState {
    case idle
    case inProgress
    case submitted
    case timeout
}

// MARK: - 考试 ViewModel

final class ExamViewModel: ObservableObject {

    // MARK: - Published

    /// 题目列表
    @Published var questions: [ExamQuestion] = []
    /// 当前题目索引
    @Published var currentQuestionIndex: Int = 0
    /// 剩余时间（秒）
    @Published var remainingSeconds: Int = AppConstants.examTimeLimitSeconds
    /// 会话状态
    @Published var sessionState: ExamSessionState = .idle
    /// 得分
    @Published var score: Double = 0

    // MARK: - 计时器

    private var timer: AnyCancellable?
    private var startTime: Date?

    // MARK: - Core Data 引用（用于超时自动提交）

    /// 考试上下文（weak 避免循环引用）
    private weak var examContext: NSManagedObjectContext?
    /// 考试用户（weak 避免循环引用）
    private weak var examUser: UserMO?

    // MARK: - 当前题目

    var currentQuestion: ExamQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var totalQuestions: Int { questions.count }

    var answeredCount: Int {
        questions.filter { $0.isAnswered }.count
    }

    var correctCount: Int {
        questions.filter { $0.isCorrect }.count
    }

    var progress: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(answeredCount) / Double(totalQuestions)
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 是否时间紧迫（< 60秒）
    var isTimeUrgent: Bool {
        remainingSeconds <= 60
    }

    // MARK: - 开始考试

    /// 生成模拟题目并开始计时
    func startExam(context: NSManagedObjectContext, user: UserMO) {
        questions = generateSampleQuestions()
        currentQuestionIndex = 0
        remainingSeconds = AppConstants.examTimeLimitSeconds
        sessionState = .inProgress
        startTime = Date()

        // 保存上下文引用，供超时自动提交使用
        examContext = context
        examUser = user

        // 启动倒计时
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    // MARK: - 答题

    /// 选择答案
    func selectAnswer(index: Int) {
        guard currentQuestionIndex < questions.count else { return }
        guard !questions[currentQuestionIndex].isAnswered else { return }
        questions[currentQuestionIndex].userSelectedIndex = index
    }

    /// 下一题
    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        }
    }

    /// 上一题
    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }

    /// 跳转到指定题目
    func goToQuestion(_ index: Int) {
        guard index >= 0, index < questions.count else { return }
        currentQuestionIndex = index
    }

    // MARK: - 提交

    /// 手动提交
    func submitExam(context: NSManagedObjectContext, user: UserMO) {
        timer?.cancel()
        calculateScore()
        saveExamAttempt(context: context, user: user)
        sessionState = .submitted
    }

    /// 超时自动提交
    private func timeout() {
        timer?.cancel()
        calculateScore()
        // 超时也要保存考试记录
        if let context = examContext, let user = examUser {
            saveExamAttempt(context: context, user: user)
        }
        sessionState = .timeout
    }

    // MARK: - Private

    private func tick() {
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            timeout()
        }
    }

    private func calculateScore() {
        guard !questions.isEmpty else { score = 0; return }
        score = Double(correctCount) / Double(totalQuestions) * 100.0
    }

    /// 将考试记录保存到 Core Data
    private func saveExamAttempt(context: NSManagedObjectContext, user: UserMO) {
        let attempt = ExamAttemptMO(context: context)
        attempt.id = UUID()
        attempt.date = Date()
        attempt.totalQuestions = totalQuestions
        attempt.correctCount = correctCount
        attempt.score = score
        let elapsed = startTime.map { Int(Date().timeIntervalSince($0)) } ?? 0
        attempt.timeUsedSeconds = elapsed

        // 序列化结果
        let results: [[String: Any]] = questions.map { q in
            return [
                "id": q.id.uuidString,
                "correct": q.isCorrect,
                "category": q.category
            ]
        }
        if let jsonData = try? JSONSerialization.data(withJSONObject: results),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            attempt.questionResultsJSON = jsonString
        } else {
            attempt.questionResultsJSON = "[]"
        }

        // 错误分类统计
        let incorrectCategories = questions
            .filter { !$0.isCorrect }
            .map { $0.category }
        let uniqueCategories = Array(Set(incorrectCategories))
        if let jsonData = try? JSONSerialization.data(withJSONObject: uniqueCategories),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            attempt.errorCategoriesJSON = jsonString
        } else {
            attempt.errorCategoriesJSON = "[]"
        }

        attempt.user = user

        do {
            try context.save()
        } catch {
            print("保存考试记录失败: \(error)")
        }
    }

    // MARK: - 模拟题目生成

    private func generateSampleQuestions() -> [ExamQuestion] {
        return [
            ExamQuestion(
                id: UUID(),
                questionText: "What does the word \"abandon\" mean?",
                options: ["To give up completely", "To join together", "To build something", "To make louder"],
                correctIndex: 0,
                explanation: "\"abandon\" means to give up or leave behind completely.",
                category: "vocabulary"
            ),
            ExamQuestion(
                id: UUID(),
                questionText: "Choose the correct sentence:",
                options: [
                    "She have been to London.",
                    "She has been to London.",
                    "She were been to London.",
                    "She are been to London."
                ],
                correctIndex: 1,
                explanation: "Third person singular uses \"has\", not \"have\".",
                category: "sentence"
            ),
            ExamQuestion(
                id: UUID(),
                questionText: "What is the synonym of \"brilliant\"?",
                options: ["Dull", "Excellent", "Ordinary", "Slow"],
                correctIndex: 1,
                explanation: "\"brilliant\" means exceptionally clever or talented, similar to \"excellent\".",
                category: "vocabulary"
            ),
            ExamQuestion(
                id: UUID(),
                questionText: "______ the weather was bad, we went for a walk.",
                options: ["Because", "Although", "Since", "Unless"],
                correctIndex: 1,
                explanation: "\"Although\" is used to show contrast between two clauses.",
                category: "sentence"
            ),
            ExamQuestion(
                id: UUID(),
                questionText: "AI in language learning helps students by providing ______ feedback.",
                options: ["generic", "personalized", "delayed", "manual"],
                correctIndex: 1,
                explanation: "The passage mentions \"personalized feedback\" as a key benefit of AI.",
                category: "comprehension"
            ),
            ExamQuestion(
                id: UUID(),
                questionText: "What does \"adapt\" mean in the context of learning?",
                options: [
                    "To stay the same",
                    "To adjust to new conditions",
                    "To give up learning",
                    "To memorize everything"
                ],
                correctIndex: 1,
                explanation: "\"adapt\" means to change or adjust to fit new circumstances.",
                category: "vocabulary"
            ),
            ExamQuestion(
                id: UUID(),
                questionText: "The technology analyzes ______ and provides corrections.",
                options: ["emails", "speech patterns", "test scores", "attendance records"],
                correctIndex: 1,
                explanation: "According to the passage, AI analyzes speech patterns.",
                category: "comprehension"
            ),
            ExamQuestion(
                id: UUID(),
                questionText: "Find the error: \"Neither the teacher nor the students was ready.\"",
                options: [
                    "\"Neither\" should be \"Either\"",
                    "\"was\" should be \"were\"",
                    "\"the students\" should be \"students\"",
                    "No error"
                ],
                correctIndex: 1,
                explanation: "With \"neither...nor\", the verb agrees with the nearest subject \"students\" (plural), so \"were\" is correct.",
                category: "sentence"
            ),
            ExamQuestion(
                id: UUID(),
                questionText: "What is the main idea of the AI language learning passage?",
                options: [
                    "AI will replace human teachers completely",
                    "AI provides tools that make language learning more efficient",
                    "Traditional methods are better than AI",
                    "AI only helps with vocabulary"
                ],
                correctIndex: 1,
                explanation: "The passage discusses how AI enhances language learning efficiency.",
                category: "comprehension"
            ),
            ExamQuestion(
                id: UUID(),
                questionText: "\"Efficiency\" in the passage most closely means:",
                options: ["Speed only", "Cost reduction", "Effectiveness with minimum waste", "Complexity"],
                correctIndex: 2,
                explanation: "Efficiency means achieving results with minimal wasted effort or resources.",
                category: "vocabulary"
            ),
        ]
    }
}
