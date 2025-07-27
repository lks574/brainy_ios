import Foundation
import SwiftData

@Model
final class QuizResult: @unchecked Sendable, Syncable {
    @Attribute(.unique) var id: String
    var userId: String
    var questionId: String
    var userAnswer: String
    var isCorrect: Bool
    var timeSpent: TimeInterval
    var completedAt: Date
    var category: QuizCategory
    var quizMode: QuizMode
    
    // 동기화 관련 필드
    var needsSync: Bool = true
    var lastModified: Date = Date()
    var syncedAt: Date?
    
    @Relationship var user: User?
    @Relationship var session: QuizSession?
    
    init(id: String, userId: String, questionId: String, userAnswer: String, isCorrect: Bool, timeSpent: TimeInterval, category: QuizCategory, quizMode: QuizMode) {
        self.id = id
        self.userId = userId
        self.questionId = questionId
        self.userAnswer = userAnswer
        self.isCorrect = isCorrect
        self.timeSpent = timeSpent
        self.category = category
        self.quizMode = quizMode
        self.completedAt = Date()
        self.needsSync = true
        self.lastModified = Date()
    }
    
    /// 동기화 완료 표시
    func markAsSynced() {
        needsSync = false
        syncedAt = Date()
    }
    
    /// 동기화 필요 표시
    func markForSync() {
        needsSync = true
        lastModified = Date()
    }
}
