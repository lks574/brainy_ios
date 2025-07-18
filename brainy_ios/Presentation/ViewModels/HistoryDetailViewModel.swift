import Foundation
import SwiftUI

/// 히스토리 상세 화면을 위한 ViewModel
@MainActor
@Observable
class HistoryDetailViewModel {
    private let quizRepository: QuizRepositoryProtocol
    let session: QuizSession
    
    // State
    var quizResults: [QuizResult] = []
    var questions: [String: QuizQuestion] = [:]
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    // Current user (should be injected or retrieved from auth service)
    private var currentUserId: String = "default_user" // TODO: Get from AuthenticationService
    
    // Computed properties
    var correctAnswersCount: Int {
        return quizResults.filter { $0.isCorrect }.count
    }
    
    var incorrectAnswersCount: Int {
        return quizResults.filter { !$0.isCorrect }.count
    }
    
    var averageTimePerQuestion: String {
        guard !quizResults.isEmpty else { return "0초" }
        let totalTime = quizResults.reduce(0) { $0 + $1.timeSpent }
        let averageTime = totalTime / Double(quizResults.count)
        return formatTime(averageTime)
    }
    
    var fastestAnswerTime: String {
        guard !quizResults.isEmpty else { return "0초" }
        let fastestTime = quizResults.min { $0.timeSpent < $1.timeSpent }?.timeSpent ?? 0
        return formatTime(fastestTime)
    }
    
    var slowestAnswerTime: String {
        guard !quizResults.isEmpty else { return "0초" }
        let slowestTime = quizResults.max { $0.timeSpent < $1.timeSpent }?.timeSpent ?? 0
        return formatTime(slowestTime)
    }
    
    init(quizRepository: QuizRepositoryProtocol, session: QuizSession) {
        self.quizRepository = quizRepository
        self.session = session
    }
    
    /// 세션 상세 정보를 로드합니다
    func loadSessionDetails() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 세션에 해당하는 퀴즈 결과들을 로드
            await loadQuizResults()
            
            // 문제 정보들을 로드
            await loadQuestions()
            
        } catch {
            errorMessage = handleError(error)
        }
        
        isLoading = false
    }
    
    /// 퀴즈 결과들을 로드합니다
    private func loadQuizResults() async {
        do {
            // 사용자의 모든 퀴즈 결과를 가져온 후 세션 시간대로 필터링
            let allResults = try await quizRepository.getQuizResults(userId: currentUserId)
            
            // 세션 시작 시간과 완료 시간 사이의 결과들만 필터링
            let sessionStartTime = session.startedAt
            let sessionEndTime = session.completedAt ?? Date()
            
            quizResults = allResults.filter { result in
                result.completedAt >= sessionStartTime && 
                result.completedAt <= sessionEndTime &&
                result.category == session.category
            }
            
            // 완료 시간 순으로 정렬
            quizResults.sort { $0.completedAt < $1.completedAt }
            
        } catch {
            print("Failed to load quiz results: \(error)")
            quizResults = []
        }
    }
    
    /// 문제 정보들을 로드합니다
    private func loadQuestions() async {
        do {
            // 결과에 포함된 문제 ID들을 추출
            let questionIds = Set(quizResults.map { $0.questionId })
            
            // 각 문제 정보를 로드
            for questionId in questionIds {
                if let question = try await quizRepository.getQuestion(by: questionId) {
                    questions[questionId] = question
                }
            }
            
        } catch {
            print("Failed to load questions: \(error)")
        }
    }
    
    /// 특정 문제 ID에 해당하는 문제를 반환합니다
    func getQuestion(for questionId: String) -> QuizQuestion? {
        return questions[questionId]
    }
    
    /// 문제별 성과 분석을 반환합니다
    func getQuestionPerformance() -> [QuestionPerformance] {
        return quizResults.enumerated().map { index, result in
            let question = questions[result.questionId]
            return QuestionPerformance(
                questionNumber: index + 1,
                question: question?.question ?? "문제를 불러올 수 없습니다",
                userAnswer: result.userAnswer,
                correctAnswer: question?.correctAnswer ?? "",
                isCorrect: result.isCorrect,
                timeSpent: result.timeSpent,
                difficulty: question?.difficulty ?? .medium
            )
        }
    }
    
    /// 난이도별 성과를 반환합니다
    func getDifficultyPerformance() -> [DifficultyPerformance] {
        let difficulties = QuizDifficulty.allCases
        
        return difficulties.compactMap { difficulty in
            let difficultyResults = quizResults.filter { result in
                questions[result.questionId]?.difficulty == difficulty
            }
            
            guard !difficultyResults.isEmpty else { return nil }
            
            let correctCount = difficultyResults.filter { $0.isCorrect }.count
            let totalCount = difficultyResults.count
            let averageTime = difficultyResults.reduce(0) { $0 + $1.timeSpent } / Double(totalCount)
            
            return DifficultyPerformance(
                difficulty: difficulty,
                totalQuestions: totalCount,
                correctAnswers: correctCount,
                averageTime: averageTime,
                accuracyRate: Double(correctCount) / Double(totalCount)
            )
        }
    }
    
    /// 시간대별 성과를 반환합니다 (문제 순서별)
    func getTimeBasedPerformance() -> [TimeBasedPerformance] {
        return quizResults.enumerated().map { index, result in
            TimeBasedPerformance(
                questionIndex: index,
                timeSpent: result.timeSpent,
                isCorrect: result.isCorrect,
                cumulativeAccuracy: calculateCumulativeAccuracy(upToIndex: index)
            )
        }
    }
    
    /// 누적 정확도 계산
    private func calculateCumulativeAccuracy(upToIndex: Int) -> Double {
        let resultsUpToIndex = Array(quizResults.prefix(upToIndex + 1))
        let correctCount = resultsUpToIndex.filter { $0.isCorrect }.count
        return Double(correctCount) / Double(resultsUpToIndex.count)
    }
    
    /// 세션 요약 정보를 반환합니다
    func getSessionSummary() -> SessionSummary {
        let totalTime = quizResults.reduce(0) { $0 + $1.timeSpent }
        let averageTime = quizResults.isEmpty ? 0 : totalTime / Double(quizResults.count)
        let fastestTime = quizResults.min { $0.timeSpent < $1.timeSpent }?.timeSpent ?? 0
        let slowestTime = quizResults.max { $0.timeSpent < $1.timeSpent }?.timeSpent ?? 0
        
        return SessionSummary(
            sessionId: session.id,
            category: session.category,
            mode: session.mode,
            startTime: session.startedAt,
            endTime: session.completedAt,
            totalQuestions: session.totalQuestions,
            correctAnswers: session.correctAnswers,
            accuracyRate: session.accuracyRate,
            totalTime: session.totalTime,
            averageTimePerQuestion: averageTime,
            fastestAnswer: fastestTime,
            slowestAnswer: slowestTime
        )
    }
    
    /// 시간 포맷팅
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let seconds = Int(timeInterval)
        if seconds < 60 {
            return "\(seconds)초"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)분 \(remainingSeconds)초"
        }
    }
    
    /// 에러 처리
    private func handleError(_ error: Error) -> String {
        if let brainyError = error as? BrainyError {
            return brainyError.localizedDescription
        }
        return error.localizedDescription
    }
    
    /// 에러 메시지를 클리어합니다
    func clearError() {
        errorMessage = nil
    }
    
    /// 세션 데이터를 새로고침합니다
    func refreshSessionData() async {
        await loadSessionDetails()
    }
}

// MARK: - Supporting Data Structures

/// 문제별 성과
struct QuestionPerformance {
    let questionNumber: Int
    let question: String
    let userAnswer: String
    let correctAnswer: String
    let isCorrect: Bool
    let timeSpent: TimeInterval
    let difficulty: QuizDifficulty
}

/// 난이도별 성과
struct DifficultyPerformance {
    let difficulty: QuizDifficulty
    let totalQuestions: Int
    let correctAnswers: Int
    let averageTime: TimeInterval
    let accuracyRate: Double
}

/// 시간대별 성과
struct TimeBasedPerformance {
    let questionIndex: Int
    let timeSpent: TimeInterval
    let isCorrect: Bool
    let cumulativeAccuracy: Double
}

/// 세션 요약
struct SessionSummary {
    let sessionId: String
    let category: QuizCategory
    let mode: QuizMode
    let startTime: Date
    let endTime: Date?
    let totalQuestions: Int
    let correctAnswers: Int
    let accuracyRate: Double
    let totalTime: TimeInterval
    let averageTimePerQuestion: TimeInterval
    let fastestAnswer: TimeInterval
    let slowestAnswer: TimeInterval
}

