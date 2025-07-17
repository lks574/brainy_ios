import Foundation

enum QuizCategory: String, CaseIterable, Codable {
    case person = "인물"
    case general = "상식"
    case country = "나라"
    case drama = "드라마"
    case music = "음악"
}