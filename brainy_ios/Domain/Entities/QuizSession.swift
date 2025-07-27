import Foundation
import SwiftData

@Model
final class QuizSession: @unchecked Sendable, Syncable {
    @Attribute(.unique) var id: String
    var userId: String
    var category: QuizCategory
    var mode: QuizMode
    var totalQuestions: Int
    var correctAnswers: Int
    var totalTime: TimeInterval
    var startedAt: Date
    var completedAt: Date?
    
    // 동기화 관련 필드
    var needsSync: Bool = true
    var lastModified: Date = Date()
    var syncedAt: Date?
    
    @Relationship var results: [QuizResult] = []
    @Relationship var user: User?
    
    init(id: String, userId: String, category: QuizCategory, mode: QuizMode, totalQuestions: Int) {
        self.id = id
        self.userId = userId
        self.category = category
        self.mode = mode
        self.totalQuestions = totalQuestions
        self.correctAnswers = 0
        self.totalTime = 0
        self.startedAt = Date()
        self.needsSync = true
        self.lastModified = Date()
    }
    
    /// 로컬 통계 계산용 정확도
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions)
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
    
    /// 세션 완료 처리
    func complete() {
        completedAt = Date()
        markForSync()
    }
}
