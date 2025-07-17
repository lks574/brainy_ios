import Foundation
import SwiftData

@Model
class QuizResult {
    @Attribute(.unique) var id: String
    var userId: String
    var questionId: String
    var userAnswer: String
    var isCorrect: Bool
    var timeSpent: TimeInterval
    var completedAt: Date
    var category: QuizCategory
    var quizMode: QuizMode
    
    @Relationship var user: User?
    
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
    }
}