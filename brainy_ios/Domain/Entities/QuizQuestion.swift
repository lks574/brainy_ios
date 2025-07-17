import Foundation
import SwiftData

@Model
class QuizQuestion {
    @Attribute(.unique) var id: String
    var question: String
    var correctAnswer: String
    var options: [String]? // 객관식인 경우
    var category: QuizCategory
    var difficulty: QuizDifficulty
    var type: QuizType
    var audioURL: String? // 음성모드인 경우
    var isCompleted: Bool = false
    
    init(id: String, question: String, correctAnswer: String, category: QuizCategory, difficulty: QuizDifficulty, type: QuizType, options: [String]? = nil, audioURL: String? = nil) {
        self.id = id
        self.question = question
        self.correctAnswer = correctAnswer
        self.category = category
        self.difficulty = difficulty
        self.type = type
        self.options = options
        self.audioURL = audioURL
    }
}