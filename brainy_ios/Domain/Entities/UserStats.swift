import Foundation

/// 로컬에서 계산되는 사용자 통계
struct UserStats: Codable {
    let totalQuizzes: Int
    let totalCorrectAnswers: Int
    let totalQuestions: Int
    let averageAccuracy: Double
    let totalTimeSpent: TimeInterval
    let categoryStats: [QuizCategory: CategoryStats]
    let streakDays: Int
    let lastPlayedAt: Date?
    let calculatedAt: Date
    
    init(totalQuizzes: Int = 0,
         totalCorrectAnswers: Int = 0,
         totalQuestions: Int = 0,
         averageAccuracy: Double = 0.0,
         totalTimeSpent: TimeInterval = 0,
         categoryStats: [QuizCategory: CategoryStats] = [:],
         streakDays: Int = 0,
         lastPlayedAt: Date? = nil) {
        self.totalQuizzes = totalQuizzes
        self.totalCorrectAnswers = totalCorrectAnswers
        self.totalQuestions = totalQuestions
        self.averageAccuracy = averageAccuracy
        self.totalTimeSpent = totalTimeSpent
        self.categoryStats = categoryStats
        self.streakDays = streakDays
        self.lastPlayedAt = lastPlayedAt
        self.calculatedAt = Date()
    }
    
    /// 로컬 데이터로부터 통계 계산
    static func calculate(from sessions: [QuizSession]) -> UserStats {
        guard !sessions.isEmpty else {
            return UserStats()
        }
        
        let completedSessions = sessions.filter { $0.completedAt != nil }
        
        let totalQuizzes = completedSessions.count
        let totalCorrectAnswers = completedSessions.reduce(0) { $0 + $1.correctAnswers }
        let totalQuestions = completedSessions.reduce(0) { $0 + $1.totalQuestions }
        let averageAccuracy = totalQuestions > 0 ? Double(totalCorrectAnswers) / Double(totalQuestions) : 0.0
        let totalTimeSpent = completedSessions.reduce(0) { $0 + $1.totalTime }
        
        // 카테고리별 통계 계산
        var categoryStats: [QuizCategory: CategoryStats] = [:]
        for category in QuizCategory.allCases {
            let categorySessions = completedSessions.filter { $0.category == category }
            if !categorySessions.isEmpty {
                categoryStats[category] = CategoryStats.calculate(from: categorySessions)
            }
        }
        
        // 연속 플레이 일수 계산
        let streakDays = calculateStreakDays(from: completedSessions)
        
        // 마지막 플레이 시간
        let lastPlayedAt = completedSessions.compactMap { $0.completedAt }.max()
        
        return UserStats(
            totalQuizzes: totalQuizzes,
            totalCorrectAnswers: totalCorrectAnswers,
            totalQuestions: totalQuestions,
            averageAccuracy: averageAccuracy,
            totalTimeSpent: totalTimeSpent,
            categoryStats: categoryStats,
            streakDays: streakDays,
            lastPlayedAt: lastPlayedAt
        )
    }
    
    /// 연속 플레이 일수 계산
    private static func calculateStreakDays(from sessions: [QuizSession]) -> Int {
        let completedDates = sessions
            .compactMap { $0.completedAt }
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted(by: >)
        
        guard !completedDates.isEmpty else { return 0 }
        
        var streak = 1
        let calendar = Calendar.current
        
        for i in 1..<completedDates.count {
            let currentDate = completedDates[i-1]
            let previousDate = completedDates[i]
            
            if let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day,
               daysBetween == 1 {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
}

/// 카테고리별 통계
struct CategoryStats: Codable {
    let totalQuizzes: Int
    let correctAnswers: Int
    let totalQuestions: Int
    let accuracy: Double
    let bestStreak: Int
    let averageTime: TimeInterval
    let lastPlayedAt: Date?
    
    init(totalQuizzes: Int = 0,
         correctAnswers: Int = 0,
         totalQuestions: Int = 0,
         accuracy: Double = 0.0,
         bestStreak: Int = 0,
         averageTime: TimeInterval = 0,
         lastPlayedAt: Date? = nil) {
        self.totalQuizzes = totalQuizzes
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        self.accuracy = accuracy
        self.bestStreak = bestStreak
        self.averageTime = averageTime
        self.lastPlayedAt = lastPlayedAt
    }
    
    /// 세션들로부터 카테고리 통계 계산
    static func calculate(from sessions: [QuizSession]) -> CategoryStats {
        guard !sessions.isEmpty else {
            return CategoryStats()
        }
        
        let totalQuizzes = sessions.count
        let correctAnswers = sessions.reduce(0) { $0 + $1.correctAnswers }
        let totalQuestions = sessions.reduce(0) { $0 + $1.totalQuestions }
        let accuracy = totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0.0
        let averageTime = sessions.reduce(0) { $0 + $1.totalTime } / Double(sessions.count)
        let lastPlayedAt = sessions.compactMap { $0.completedAt }.max()
        
        // 최고 연속 정답 계산 (간단한 구현)
        let bestStreak = sessions.map { $0.correctAnswers }.max() ?? 0
        
        return CategoryStats(
            totalQuizzes: totalQuizzes,
            correctAnswers: correctAnswers,
            totalQuestions: totalQuestions,
            accuracy: accuracy,
            bestStreak: bestStreak,
            averageTime: averageTime,
            lastPlayedAt: lastPlayedAt
        )
    }
}

/// 리더보드 캐시 데이터
struct LeaderboardData: Codable {
    let rankings: [LeaderboardEntry]
    let userRank: Int?
    let lastUpdated: Date
    let cacheExpiresAt: Date
    
    init(rankings: [LeaderboardEntry] = [],
         userRank: Int? = nil,
         lastUpdated: Date = Date(),
         cacheExpiresAt: Date = Date().addingTimeInterval(86400)) { // 24시간 후 만료
        self.rankings = rankings
        self.userRank = userRank
        self.lastUpdated = lastUpdated
        self.cacheExpiresAt = cacheExpiresAt
    }
    
    /// 캐시가 만료되었는지 확인
    var isExpired: Bool {
        return Date() > cacheExpiresAt
    }
    
    /// 캐시 나이 (시간)
    var cacheAge: TimeInterval {
        return Date().timeIntervalSince(lastUpdated)
    }
    
    /// 캐시 나이를 사람이 읽기 쉬운 형태로 반환
    var cacheAgeString: String {
        let hours = Int(cacheAge / 3600)
        let minutes = Int((cacheAge.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분 전"
        } else {
            return "\(minutes)분 전"
        }
    }
}

/// 리더보드 항목
struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let score: Int
    let accuracy: Double
    let rank: Int
    let totalQuizzes: Int
    let lastPlayedAt: Date?
    
    init(userId: String,
         displayName: String,
         score: Int,
         accuracy: Double,
         rank: Int,
         totalQuizzes: Int = 0,
         lastPlayedAt: Date? = nil) {
        self.id = userId
        self.userId = userId
        self.displayName = displayName
        self.score = score
        self.accuracy = accuracy
        self.rank = rank
        self.totalQuizzes = totalQuizzes
        self.lastPlayedAt = lastPlayedAt
    }
}