import Foundation

enum QuizType: String, CaseIterable, Codable {
    case multipleChoice = "객관식"
    case shortAnswer = "주관식"
    case voice = "음성모드"
    case ai = "AI모드"
}

enum QuizMode: String, CaseIterable, Codable {
    case stage = "스테이지"
    case individual = "개별"
}

enum QuizDifficulty: String, CaseIterable, Codable {
    case easy = "쉬움"
    case medium = "보통"
    case hard = "어려움"
}