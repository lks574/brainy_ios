import Foundation

/// 퀴즈 버전 응답 모델
struct QuizVersionResponse: Codable, Sendable {
    let version: String
    let lastUpdated: Date
    let totalQuestions: Int
    let categories: [String]
}

/// 퀴즈 데이터 응답 모델
struct QuizDataResponse: Codable, Sendable {
    let version: String
    let questions: [QuizQuestionDTO]
    let metadata: QuizMetadata
}

/// 퀴즈 문제 DTO (Data Transfer Object)
struct QuizQuestionDTO: Codable, Sendable {
    let id: String
    let question: String
    let correctAnswer: String
    let options: [String]?
    let category: String
    let difficulty: String
    let type: String
    let audioURL: String?
    
    /// QuizQuestion 엔티티로 변환
    func toEntity() -> QuizQuestion {
        return QuizQuestion(
            id: id,
            question: question,
            correctAnswer: correctAnswer,
            category: QuizCategory(rawValue: category) ?? .general,
            difficulty: QuizDifficulty(rawValue: difficulty) ?? .medium,
            type: QuizType(rawValue: type) ?? .shortAnswer,
            options: options,
            audioURL: audioURL
        )
    }
}

/// 퀴즈 메타데이터
struct QuizMetadata: Codable, Sendable {
    let totalQuestions: Int
    let categoryCounts: [String: Int]
    let difficultyDistribution: [String: Int]
    let typeDistribution: [String: Int]
}

/// 로컬 퀴즈 버전 정보
struct LocalQuizVersion: Codable, Sendable {
    let version: String
    let lastUpdated: Date
    let totalQuestions: Int
    
    init(version: String, lastUpdated: Date = Date(), totalQuestions: Int) {
        self.version = version
        self.lastUpdated = lastUpdated
        self.totalQuestions = totalQuestions
    }
}

/// 퀴즈 동기화 상태 정보
struct QuizSyncStatus: Sendable {
    let currentVersion: String?
    let totalQuestions: Int
    let isOffline: Bool
    let lastSyncDate: Date?
    
    var statusDescription: String {
        if isOffline {
            return "오프라인 모드"
        } else if let version = currentVersion {
            return "버전 \(version)"
        } else {
            return "데이터 없음"
        }
    }
}