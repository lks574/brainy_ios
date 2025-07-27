import Foundation
import SwiftData

/// 로컬 우선 데이터 관리자
actor LocalDataManager {
    // MARK: - Properties
    private let modelContext: ModelContext
    private let userDefaults = UserDefaults.standard
    
    // Cache keys
    private let userStatsKey = "user_stats_cache"
    private let leaderboardKey = "leaderboard_cache"
    private let lastSyncKey = "last_sync_time"
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Quiz Result Management
    
    /// 퀴즈 결과를 로컬에 저장하고 동기화 대기 상태로 표시
    func saveQuizResult(_ result: QuizResult) async throws {
        result.markForSync()
        modelContext.insert(result)
        try modelContext.save()
        
        // 통계 캐시 무효화
        await invalidateUserStatsCache()
    }
    
    /// 퀴즈 세션을 로컬에 저장하고 동기화 대기 상태로 표시
    func saveQuizSession(_ session: QuizSession) async throws {
        session.markForSync()
        modelContext.insert(session)
        try modelContext.save()
        
        // 통계 캐시 무효화
        await invalidateUserStatsCache()
    }
    
    /// 로컬 퀴즈 히스토리 로드
    func loadLocalQuizHistory(for userId: String, limit: Int = 50) async throws -> [QuizSession] {
        let descriptor = FetchDescriptor<QuizSession>(
            predicate: #Predicate<QuizSession> { session in
                session.userId == userId && session.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        var fetchDescriptor = descriptor
        fetchDescriptor.fetchLimit = limit
        
        return try modelContext.fetch(fetchDescriptor)
    }
    
    /// 특정 기간의 퀴즈 히스토리 로드
    func loadQuizHistory(for userId: String, from startDate: Date, to endDate: Date) async throws -> [QuizSession] {
        let descriptor = FetchDescriptor<QuizSession>(
            predicate: #Predicate<QuizSession> { session in
                session.userId == userId &&
                session.completedAt != nil &&
                session.completedAt! >= startDate &&
                session.completedAt! <= endDate
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 카테고리별 퀴즈 히스토리 로드
    func loadQuizHistory(for userId: String, category: QuizCategory) async throws -> [QuizSession] {
        let descriptor = FetchDescriptor<QuizSession>(
            predicate: #Predicate<QuizSession> { session in
                session.userId == userId &&
                session.category == category &&
                session.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Local Statistics
    
    /// 로컬 데이터로 사용자 통계 계산
    func calculateLocalStats(for userId: String) async throws -> UserStats {
        // 캐시된 통계 확인
        if let cachedStats = getCachedUserStats(),
           cachedStats.calculatedAt.timeIntervalSinceNow > -300 { // 5분 캐시
            return cachedStats
        }
        
        // 모든 완료된 세션 로드
        let descriptor = FetchDescriptor<QuizSession>(
            predicate: #Predicate<QuizSession> { session in
                session.userId == userId && session.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        
        let sessions = try modelContext.fetch(descriptor)
        let stats = UserStats.calculate(from: sessions)
        
        // 통계 캐시
        await cacheUserStats(stats)
        
        return stats
    }
    
    /// 캐시된 사용자 통계 반환
    private func getCachedUserStats() -> UserStats? {
        guard let data = userDefaults.data(forKey: userStatsKey) else { return nil }
        return try? JSONDecoder().decode(UserStats.self, from: data)
    }
    
    /// 사용자 통계 캐시
    private func cacheUserStats(_ stats: UserStats) async {
        if let data = try? JSONEncoder().encode(stats) {
            userDefaults.set(data, forKey: userStatsKey)
        }
    }
    
    /// 사용자 통계 캐시 무효화
    private func invalidateUserStatsCache() async {
        userDefaults.removeObject(forKey: userStatsKey)
    }
    
    // MARK: - Sync Management
    
    /// 동기화가 필요한 항목들을 반환
    func getPendingSyncItems(for userId: String) async throws -> BatchSyncRequest {
        // 동기화 필요한 세션들
        let sessionDescriptor = FetchDescriptor<QuizSession>(
            predicate: #Predicate<QuizSession> { session in
                session.userId == userId && session.needsSync
            }
        )
        let pendingSessions = try modelContext.fetch(sessionDescriptor)
        
        // 동기화 필요한 결과들
        let resultDescriptor = FetchDescriptor<QuizResult>(
            predicate: #Predicate<QuizResult> { result in
                result.userId == userId && result.needsSync
            }
        )
        let pendingResults = try modelContext.fetch(resultDescriptor)
        
        let lastSyncTime = getLastSyncTime()
        
        return BatchSyncRequest(
            sessions: pendingSessions,
            results: pendingResults,
            lastSyncAt: lastSyncTime
        )
    }
    
    /// 동기화 완료 표시
    func markItemsAsSynced(sessionIds: [String], resultIds: [String]) async throws {
        // 세션들 동기화 완료 표시
        for sessionId in sessionIds {
            let descriptor = FetchDescriptor<QuizSession>(
                predicate: #Predicate<QuizSession> { $0.id == sessionId }
            )
            if let session = try modelContext.fetch(descriptor).first {
                session.markAsSynced()
            }
        }
        
        // 결과들 동기화 완료 표시
        for resultId in resultIds {
            let descriptor = FetchDescriptor<QuizResult>(
                predicate: #Predicate<QuizResult> { $0.id == resultId }
            )
            if let result = try modelContext.fetch(descriptor).first {
                result.markAsSynced()
            }
        }
        
        try modelContext.save()
        
        // 마지막 동기화 시간 업데이트
        setLastSyncTime(Date())
    }
    
    /// 동기화 통계 반환
    func getSyncStatistics(for userId: String) async throws -> SyncStatistics {
        let sessionDescriptor = FetchDescriptor<QuizSession>(
            predicate: #Predicate<QuizSession> { $0.userId == userId }
        )
        let allSessions = try modelContext.fetch(sessionDescriptor)
        
        let resultDescriptor = FetchDescriptor<QuizResult>(
            predicate: #Predicate<QuizResult> { $0.userId == userId }
        )
        let allResults = try modelContext.fetch(resultDescriptor)
        
        let totalItems = allSessions.count + allResults.count
        let pendingSessions = allSessions.filter { $0.needsSync }.count
        let pendingResults = allResults.filter { $0.needsSync }.count
        let pendingItems = pendingSessions + pendingResults
        let syncedItems = totalItems - pendingItems
        
        return SyncStatistics(
            totalItems: totalItems,
            pendingItems: pendingItems,
            syncedItems: syncedItems,
            failedItems: 0, // 실패한 항목은 별도 추적 필요
            lastSyncTime: getLastSyncTime()
        )
    }
    
    // MARK: - Leaderboard Cache
    
    /// 캐시된 리더보드 데이터 반환
    func getCachedLeaderboard() -> LeaderboardData? {
        guard let data = userDefaults.data(forKey: leaderboardKey) else { return nil }
        let leaderboard = try? JSONDecoder().decode(LeaderboardData.self, from: data)
        
        // 만료된 캐시는 nil 반환
        if let leaderboard = leaderboard, !leaderboard.isExpired {
            return leaderboard
        }
        
        return nil
    }
    
    /// 리더보드 데이터 캐시
    func cacheLeaderboard(_ leaderboard: LeaderboardData) async {
        if let data = try? JSONEncoder().encode(leaderboard) {
            userDefaults.set(data, forKey: leaderboardKey)
        }
    }
    
    /// 리더보드 캐시 무효화
    func invalidateLeaderboardCache() async {
        userDefaults.removeObject(forKey: leaderboardKey)
    }
    
    // MARK: - Offline Support
    
    /// 오프라인에서 데이터 사용 가능 여부 확인
    func isDataAvailableOffline(for userId: String) async -> Bool {
        do {
            let sessionDescriptor = FetchDescriptor<QuizSession>(
                predicate: #Predicate<QuizSession> { $0.userId == userId }
            )
            let sessions = try modelContext.fetch(sessionDescriptor)
            
            let questionDescriptor = FetchDescriptor<QuizQuestion>()
            let questions = try modelContext.fetch(questionDescriptor)
            
            return !sessions.isEmpty && !questions.isEmpty
        } catch {
            return false
        }
    }
    
    /// 로컬 캐시 데이터 업데이트
    func updateLocalCache<T: Codable>(_ data: T, for key: String) async {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    /// 로컬 캐시 데이터 로드
    func loadFromLocalCache<T: Codable>(_ type: T.Type, for key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - Private Helpers
    
    private func getLastSyncTime() -> Date? {
        return userDefaults.object(forKey: lastSyncKey) as? Date
    }
    
    private func setLastSyncTime(_ date: Date) {
        userDefaults.set(date, forKey: lastSyncKey)
    }
}