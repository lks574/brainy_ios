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