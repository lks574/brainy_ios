import Foundation
import SwiftData

@Model
final class QuizSession: @unchecked Sendable {
    @Attribute(.unique) var id: String
    var userId: String
    var category: QuizCategory
    var mode: QuizMode
    var totalQuestions: Int
    var correctAnswers: Int
    var totalTime: TimeInterval
    var startedAt: Date
    var completedAt: Date?
    
    @Relationship var results: [QuizResult] = []
    
    init(id: String, userId: String, category: QuizCategory, mode: QuizMode, totalQuestions: Int) {
        self.id = id
        self.userId = userId
        self.category = category
        self.mode = mode
        self.totalQuestions = totalQuestions
        self.correctAnswers = 0
        self.totalTime = 0
        self.startedAt = Date()
    }
}
