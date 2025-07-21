import Foundation

@MainActor
protocol QuizRepositoryProtocol {
    func getQuestions(category: QuizCategory, excludeCompleted: Bool) async throws -> [QuizQuestion]
    func saveQuizResult(_ result: QuizResult) async throws
    func getQuizHistory(userId: String) async throws -> [QuizSession]
    func markQuestionAsCompleted(questionId: String) async throws
    func getQuizVersion() async throws -> String
    func downloadQuizData() async throws -> [QuizQuestion]
    func performInitialDataLoad() async throws
    func forceSync() async throws
    func getSyncStatus() -> QuizSyncStatus
    func isOfflineMode() -> Bool
    func getQuizResults(userId: String) async throws -> [QuizResult]
    func getQuestion(by id: String) async throws -> QuizQuestion?
}

// MARK: - Extensions for Voice Mode Support
extension QuizRepositoryProtocol {
    /// 음성 모드용 퀴즈 문제 조회 (오디오 URL이 있는 문제만)
    func getVoiceQuestions(category: QuizCategory, excludeCompleted: Bool) async throws -> [QuizQuestion] {
        let allQuestions = try await getQuestions(category: category, excludeCompleted: excludeCompleted)
        return allQuestions.filter { $0.type == .voice && $0.audioURL != nil && !$0.audioURL!.isEmpty }
    }
}