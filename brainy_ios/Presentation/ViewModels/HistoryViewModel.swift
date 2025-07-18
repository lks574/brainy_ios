import Foundation
import SwiftUI

/// 히스토리 화면을 위한 ViewModel
@MainActor
@Observable
class HistoryViewModel {
    private let quizRepository: QuizRepositoryProtocol
    
    // State
    var quizSessions: [QuizSession] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var selectedSession: QuizSession? = nil
    
    // Filter state
    var selectedCategory: QuizCategory? = nil
    var selectedMode: QuizMode? = nil
    var sortOrder: HistorySortOrder = .dateDescending
    
    // Current user (should be injected or retrieved from auth service)
    private var currentUserId: String = "default_user" // TODO: Get from AuthenticationService
    
    // Computed properties
    var filteredSessions: [QuizSession] {
        var filtered = quizSessions
        
        // Category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Mode filter
        if let mode = selectedMode {
            filtered = filtered.filter { $0.mode == mode }
        }
        
        // Sort
        switch sortOrder {
        case .dateDescending:
            filtered.sort { ($0.completedAt ?? $0.startedAt) > ($1.completedAt ?? $1.startedAt) }
        case .dateAscending:
            filtered.sort { ($0.completedAt ?? $0.startedAt) < ($1.completedAt ?? $1.startedAt) }
        case .scoreDescending:
            filtered.sort { $0.accuracyRate > $1.accuracyRate }
        case .scoreAscending:
            filtered.sort { $0.accuracyRate < $1.accuracyRate }
        }
        
        return filtered
    }
    
    var totalQuizzes: Int {
        return quizSessions.count
    }
    
    var averageScore: Double {
        guard !quizSessions.isEmpty else { return 0 }
        let totalAccuracy = quizSessions.reduce(0) { $0 + $1.accuracyRate }
        return totalAccuracy / Double(quizSessions.count)
    }
    
    var totalTimeSpent: TimeInterval {
        return quizSessions.reduce(0) { $0 + $1.totalTime }
    }
    
    init(quizRepository: QuizRepositoryProtocol) {
        self.quizRepository = quizRepository
    }
    
    /// 히스토리 데이터를 로드합니다
    func loadHistory() async {
        isLoading = true
        errorMessage = nil
        
        do {
            quizSessions = try await quizRepository.getQuizHistory(userId: currentUserId)
        } catch {
            errorMessage = handleError(error)
        }
        
        isLoading = false
    }
    
    /// 히스토리를 새로고침합니다
    func refreshHistory() async {
        await loadHistory()
    }
    
    /// 특정 세션을 선택합니다
    func selectSession(_ session: QuizSession) {
        selectedSession = session
    }
    
    /// 세션 선택을 해제합니다
    func deselectSession() {
        selectedSession = nil
    }
    
    /// 카테고리 필터를 설정합니다
    func setCategory(_ category: QuizCategory?) {
        selectedCategory = category
    }
    
    /// 모드 필터를 설정합니다
    func setMode(_ mode: QuizMode?) {
        selectedMode = mode
    }
    
    /// 정렬 순서를 설정합니다
    func setSortOrder(_ order: HistorySortOrder) {
        sortOrder = order
    }
    
    /// 모든 필터를 초기화합니다
    func clearFilters() {
        selectedCategory = nil
        selectedMode = nil
        sortOrder = .dateDescending
    }
    
    /// 세션을 삭제합니다 (향후 구현)
    func deleteSession(_ session: QuizSession) async {
        // TODO: Implement session deletion
        // This would require adding a delete method to the repository
    }
    
    /// 에러 처리
    private func handleError(_ error: Error) -> String {
        if let brainyError = error as? BrainyError {
            return brainyError.localizedDescription
        }
        return error.localizedDescription
    }
    
    /// 에러 메시지를 클리어합니다
    func clearError() {
        errorMessage = nil
    }
    
    /// 카테고리별 통계를 반환합니다
    func getCategoryStatistics() -> [CategoryStatistics] {
        let categories = QuizCategory.allCases
        
        return categories.map { category in
            let categorySessions = quizSessions.filter { $0.category == category }
            let totalQuestions = categorySessions.reduce(0) { $0 + $1.totalQuestions }
            let correctAnswers = categorySessions.reduce(0) { $0 + $1.correctAnswers }
            let averageAccuracy = categorySessions.isEmpty ? 0 : 
                categorySessions.reduce(0) { $0 + $1.accuracyRate } / Double(categorySessions.count)
            
            return CategoryStatistics(
                category: category,
                totalSessions: categorySessions.count,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                averageAccuracy: averageAccuracy
            )
        }.filter { $0.totalSessions > 0 }
    }
    
    /// 최근 활동 정보를 반환합니다
    func getRecentActivity() -> RecentActivity? {
        guard let latestSession = quizSessions.max(by: { 
            ($0.completedAt ?? $0.startedAt) < ($1.completedAt ?? $1.startedAt) 
        }) else { return nil }
        
        let daysSinceLastQuiz = Calendar.current.dateComponents(
            [.day], 
            from: latestSession.completedAt ?? latestSession.startedAt, 
            to: Date()
        ).day ?? 0
        
        return RecentActivity(
            lastQuizDate: latestSession.completedAt ?? latestSession.startedAt,
            daysSinceLastQuiz: daysSinceLastQuiz,
            lastCategory: latestSession.category,
            lastScore: latestSession.accuracyRate
        )
    }
}

// MARK: - Supporting Data Structures

/// 히스토리 정렬 순서
enum HistorySortOrder: String, CaseIterable {
    case dateDescending = "최신순"
    case dateAscending = "오래된순"
    case scoreDescending = "점수 높은순"
    case scoreAscending = "점수 낮은순"
}

/// 카테고리별 통계
struct CategoryStatistics {
    let category: QuizCategory
    let totalSessions: Int
    let totalQuestions: Int
    let correctAnswers: Int
    let averageAccuracy: Double
    
    var accuracyRate: Double {
        return totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0
    }
}

/// 최근 활동 정보
struct RecentActivity {
    let lastQuizDate: Date
    let daysSinceLastQuiz: Int
    let lastCategory: QuizCategory
    let lastScore: Double
}

// MARK: - Extensions

extension QuizSession {
    /// 정확도 비율 계산
    var accuracyRate: Double {
        return totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0
    }
    
    /// 완료 여부
    var isCompleted: Bool {
        return completedAt != nil
    }
    
    /// 표시용 날짜 문자열
    var displayDate: String {
        let date = completedAt ?? startedAt
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    /// 표시용 소요 시간 문자열
    var displayDuration: String {
        let minutes = Int(totalTime) / 60
        let seconds = Int(totalTime) % 60
        return String(format: "%d분 %d초", minutes, seconds)
    }
    
    /// 표시용 점수 문자열
    var displayScore: String {
        return "\(correctAnswers)/\(totalQuestions)"
    }
    
    /// 표시용 정확도 문자열
    var displayAccuracy: String {
        return String(format: "%.1f%%", accuracyRate * 100)
    }
}