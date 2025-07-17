import Foundation
import SwiftData

/// QuizRepository의 구현체
@MainActor
class QuizRepositoryImpl: QuizRepositoryProtocol {
    private let localDataSource: LocalDataSource
    
    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }
    
    func getQuestions(category: QuizCategory, excludeCompleted: Bool) async throws -> [QuizQuestion] {
        if excludeCompleted {
            return try localDataSource.fetchUncompletedQuizQuestions(category: category)
        } else {
            return try localDataSource.fetchQuizQuestions(by: category)
        }
    }
    
    func saveQuizResult(_ result: QuizResult) async throws {
        try localDataSource.saveQuizResult(result)
    }
    
    func getQuizHistory(userId: String) async throws -> [QuizSession] {
        return try localDataSource.fetchCompletedQuizSessions(by: userId)
    }
    
    func markQuestionAsCompleted(questionId: String) async throws {
        guard let question = try localDataSource.fetchQuizQuestion(by: questionId) else {
            throw BrainyError.quizNotFound
        }
        
        question.isCompleted = true
        try localDataSource.update()
    }
    
    func getQuizVersion() async throws -> String {
        // TODO: 실제 서버 API 호출로 대체 필요
        // 현재는 더미 버전 반환
        return "1.0.0"
    }
    
    func downloadQuizData() async throws -> [QuizQuestion] {
        // TODO: 실제 서버 API 호출로 대체 필요
        // 현재는 더미 데이터 반환
        return createSampleQuizData()
    }
    
    // MARK: - Additional Methods
    
    /// 퀴즈 세션을 저장합니다
    func saveQuizSession(_ session: QuizSession) async throws {
        try localDataSource.saveQuizSession(session)
    }
    
    /// 퀴즈 세션을 완료 처리합니다
    func completeQuizSession(sessionId: String, correctAnswers: Int, totalTime: TimeInterval) async throws {
        guard let session = try localDataSource.fetchQuizSession(by: sessionId) else {
            throw BrainyError.quizNotFound
        }
        
        session.correctAnswers = correctAnswers
        session.totalTime = totalTime
        session.completedAt = Date()
        
        try localDataSource.update()
    }
    
    /// 사용자의 퀴즈 통계를 조회합니다
    func getQuizStatistics(userId: String) async throws -> QuizStatistics {
        let results = try localDataSource.fetchQuizResults(by: userId)
        let sessions = try localDataSource.fetchCompletedQuizSessions(by: userId)
        
        let totalQuestions = results.count
        let correctAnswers = results.filter { $0.isCorrect }.count
        let totalSessions = sessions.count
        let averageScore = totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0.0
        
        return QuizStatistics(
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
            totalSessions: totalSessions,
            averageScore: averageScore
        )
    }
    
    /// 카테고리별 진행률을 조회합니다
    func getCategoryProgress(userId: String, category: QuizCategory) async throws -> CategoryProgress {
        let allQuestions = try localDataSource.fetchQuizQuestions(by: category)
        let completedQuestions = allQuestions.filter { $0.isCompleted }
        let results = try localDataSource.fetchQuizResults(by: category, userId: userId)
        let correctResults = results.filter { $0.isCorrect }
        
        return CategoryProgress(
            category: category,
            totalQuestions: allQuestions.count,
            completedQuestions: completedQuestions.count,
            correctAnswers: correctResults.count
        )
    }
    
    /// 퀴즈 데이터를 초기화합니다 (새로운 데이터 다운로드 시)
    func resetQuizData() async throws {
        try localDataSource.deleteAllQuizQuestions()
    }
    
    /// 퀴즈 데이터를 로컬에 저장합니다
    func saveQuizData(_ questions: [QuizQuestion]) async throws {
        try localDataSource.saveQuizQuestions(questions)
    }
}

// MARK: - Helper Methods
extension QuizRepositoryImpl {
    
    /// 샘플 퀴즈 데이터를 생성합니다 (개발/테스트용)
    private func createSampleQuizData() -> [QuizQuestion] {
        return [
            QuizQuestion(
                id: "q1",
                question: "대한민국의 수도는?",
                correctAnswer: "서울",
                category: .general,
                difficulty: .easy,
                type: .shortAnswer
            ),
            QuizQuestion(
                id: "q2",
                question: "다음 중 대한민국의 수도는?",
                correctAnswer: "서울",
                category: .general,
                difficulty: .easy,
                type: .multipleChoice,
                options: ["서울", "부산", "대구", "인천"]
            ),
            QuizQuestion(
                id: "q3",
                question: "세종대왕이 만든 문자는?",
                correctAnswer: "한글",
                category: .person,
                difficulty: .medium,
                type: .shortAnswer
            ),
            QuizQuestion(
                id: "q4",
                question: "다음 중 한국의 전통 음식이 아닌 것은?",
                correctAnswer: "스시",
                category: .general,
                difficulty: .medium,
                type: .multipleChoice,
                options: ["김치", "불고기", "스시", "비빔밥"]
            ),
            QuizQuestion(
                id: "q5",
                question: "태극기의 중앙에 있는 원의 이름은?",
                correctAnswer: "태극",
                category: .country,
                difficulty: .hard,
                type: .shortAnswer
            )
        ]
    }
}

// MARK: - Data Models
struct QuizStatistics {
    let totalQuestions: Int
    let correctAnswers: Int
    let totalSessions: Int
    let averageScore: Double
}

struct CategoryProgress {
    let category: QuizCategory
    let totalQuestions: Int
    let completedQuestions: Int
    let correctAnswers: Int
    
    var completionRate: Double {
        return totalQuestions > 0 ? Double(completedQuestions) / Double(totalQuestions) : 0.0
    }
    
    var accuracyRate: Double {
        return completedQuestions > 0 ? Double(correctAnswers) / Double(completedQuestions) : 0.0
    }
}