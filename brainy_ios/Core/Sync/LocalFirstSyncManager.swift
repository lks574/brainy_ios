import Foundation
import SwiftData

/// 로컬 우선 동기화 관리자
actor LocalFirstSyncManager: ObservableObject {
    // MARK: - Properties
    private let localDataManager: LocalDataManager
    private let networkService: NetworkService
    private let configManager = StaticConfigManager.shared
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var pendingSyncCount: Int = 0
    @Published var syncProgress: Double = 0.0
    
    // 동기화 제한 (하루 1회)
    private let leaderboardSyncInterval: TimeInterval = 86400 // 24시간
    private let leaderboardSyncKey = "last_leaderboard_sync"
    
    // MARK: - Initialization
    init(localDataManager: LocalDataManager, networkService: NetworkService) {
        self.localDataManager = localDataManager
        self.networkService = networkService
    }
    
    // MARK: - Local-First Data Management
    
    /// 로컬 데이터 초기화 (앱 시작 시)
    func initializeLocalData() async {
        // 로컬 데이터 우선 로드
        // 백그라운드에서 설정 확인만 수행
        Task {
            do {
                _ = try await configManager.loadStaticConfig()
            } catch {
                print("Failed to load static config: \(error)")
            }
        }
    }
    
    /// 퀴즈 결과를 로컬에 저장하고 동기화 대기 상태로 표시
    func markPendingSync(for results: [QuizResult]) async {
        for result in results {
            result.markForSync()
        }
        
        await updatePendingSyncCount()
    }
    
    /// 퀴즈 세션을 로컬에 저장하고 동기화 대기 상태로 표시
    func markPendingSync(for sessions: [QuizSession]) async {
        for session in sessions {
            session.markForSync()
        }
        
        await updatePendingSyncCount()
    }
    
    // MARK: - Manual Sync (사용자가 버튼 클릭 시에만)
    
    /// 수동 동기화 실행
    func manualSync(for userId: String) async throws {
        guard syncStatus != .syncing(progress: 0) else {
            throw SyncError.syncInProgress
        }
        
        await MainActor.run {
            syncStatus = .syncing(progress: 0.0)
        }
        
        do {
            // 1. 대기 중인 데이터 업로드 (70%)
            try await uploadPendingResults(for: userId)
            await updateProgress(0.7)
            
            // 2. 리더보드 업데이트 (하루 1회만) (30%)
            try await updateLeaderboardIfNeeded()
            await updateProgress(1.0)
            
            // 3. 동기화 완료
            await MainActor.run {
                syncStatus = .completed
                lastSyncTime = Date()
            }
            
            await updatePendingSyncCount()
            
        } catch {
            await MainActor.run {
                syncStatus = .failed(error)
            }
            throw error
        }
    }
    
    /// 대기 중인 퀴즈 결과들을 배치로 업로드
    private func uploadPendingResults(for userId: String) async throws {
        let pendingData = try await localDataManager.getPendingSyncItems(for: userId)
        
        guard !pendingData.isEmpty else { return }
        
        // 배치 업로드 실행
        let response = try await networkService.batchSyncData(pendingData)
        
        // 성공한 항목들을 동기화 완료로 표시
        let syncedSessionIds = pendingData.sessions.prefix(response.syncedSessions).map { $0.id }
        let syncedResultIds = pendingData.results.prefix(response.syncedResults).map { $0.id }
        
        try await localDataManager.markItemsAsSynced(
            sessionIds: Array(syncedSessionIds),
            resultIds: Array(syncedResultIds)
        )
    }
    
    /// 리더보드 업데이트 (하루 1회만)
    private func updateLeaderboardIfNeeded() async throws {
        let lastLeaderboardSync = UserDefaults.standard.object(forKey: leaderboardSyncKey) as? Date
        
        // 하루가 지나지 않았다면 스킵
        if let lastSync = lastLeaderboardSync,
           Date().timeIntervalSince(lastSync) < leaderboardSyncInterval {
            return
        }
        
        // 리더보드 데이터 다운로드
        let leaderboardData = try await networkService.fetchLeaderboard()
        
        // 로컬 캐시 업데이트
        await localDataManager.cacheLeaderboard(leaderboardData)
        
        // 마지막 동기화 시간 업데이트
        UserDefaults.standard.set(Date(), forKey: leaderboardSyncKey)
    }
    
    // MARK: - Offline Support
    
    /// 오프라인 모드 여부 확인
    func isOfflineMode() -> Bool {
        // 네트워크 상태 확인 로직
        return !networkService.isConnected
    }
    
    /// 캐시된 데이터 반환
    func getCachedData<T>(_ type: T.Type, for key: String) -> T? {
        return localDataManager.loadFromLocalCache(type, for: key)
    }
    
    /// 캐시된 리더보드 데이터 반환
    func getCachedLeaderboard() async -> LeaderboardData? {
        return await localDataManager.getCachedLeaderboard()
    }
    
    // MARK: - Sync Statistics
    
    /// 동기화 통계 반환
    func getSyncStatistics(for userId: String) async throws -> SyncStatistics {
        return try await localDataManager.getSyncStatistics(for: userId)
    }
    
    /// 대기 중인 동기화 항목 수 업데이트
    private func updatePendingSyncCount() async {
        // 현재 사용자 ID 가져오기 (실제 구현에서는 AuthManager에서 가져와야 함)
        guard let currentUserId = getCurrentUserId() else { return }
        
        do {
            let stats = try await localDataManager.getSyncStatistics(for: currentUserId)
            await MainActor.run {
                pendingSyncCount = stats.pendingItems
            }
        } catch {
            print("Failed to update pending sync count: \(error)")
        }
    }
    
    /// 동기화 진행률 업데이트
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            syncProgress = progress
            if case .syncing = syncStatus {
                syncStatus = .syncing(progress: progress)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 현재 사용자 ID 반환 (임시 구현)
    private func getCurrentUserId() -> String? {
        // 실제 구현에서는 AuthManager에서 가져와야 함
        return "current_user_id"
    }
    
    /// 마지막 리더보드 동기화 시간 반환
    func getLastLeaderboardSyncTime() -> Date? {
        return UserDefaults.standard.object(forKey: leaderboardSyncKey) as? Date
    }
    
    /// 리더보드 동기화 가능 여부 확인
    func canSyncLeaderboard() -> Bool {
        guard let lastSync = getLastLeaderboardSyncTime() else { return true }
        return Date().timeIntervalSince(lastSync) >= leaderboardSyncInterval
    }
    
    /// 다음 리더보드 동기화까지 남은 시간
    func timeUntilNextLeaderboardSync() -> TimeInterval {
        guard let lastSync = getLastLeaderboardSyncTime() else { return 0 }
        let elapsed = Date().timeIntervalSince(lastSync)
        return max(0, leaderboardSyncInterval - elapsed)
    }
}

// MARK: - Sync Error

enum SyncError: LocalizedError {
    case syncInProgress
    case networkUnavailable
    case uploadFailed(String)
    case downloadFailed(String)
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .syncInProgress:
            return "이미 동기화가 진행 중입니다."
        case .networkUnavailable:
            return "네트워크에 연결할 수 없습니다."
        case .uploadFailed(let message):
            return "업로드 실패: \(message)"
        case .downloadFailed(let message):
            return "다운로드 실패: \(message)"
        case .dataCorrupted:
            return "데이터가 손상되었습니다."
        }
    }
}

// MARK: - Network Service Protocol

protocol NetworkService {
    var isConnected: Bool { get }
    func batchSyncData(_ request: BatchSyncRequest) async throws -> BatchSyncResponse
    func fetchLeaderboard() async throws -> LeaderboardData
}

// MARK: - Mock Network Service (임시 구현)

class MockNetworkService: NetworkService {
    var isConnected: Bool = true
    
    func batchSyncData(_ request: BatchSyncRequest) async throws -> BatchSyncResponse {
        // 임시 구현
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
        
        return BatchSyncResponse(
            syncedSessions: request.sessions.count,
            syncedResults: request.results.count,
            failedSessions: 0,
            failedResults: 0,
            syncedAt: Date()
        )
    }
    
    func fetchLeaderboard() async throws -> LeaderboardData {
        // 임시 구현
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
        
        let mockEntries = [
            LeaderboardEntry(userId: "user1", displayName: "플레이어1", score: 1000, accuracy: 0.95, rank: 1),
            LeaderboardEntry(userId: "user2", displayName: "플레이어2", score: 950, accuracy: 0.92, rank: 2),
            LeaderboardEntry(userId: "user3", displayName: "플레이어3", score: 900, accuracy: 0.90, rank: 3)
        ]
        
        return LeaderboardData(
            rankings: mockEntries,
            userRank: 5,
            lastUpdated: Date(),
            cacheExpiresAt: Date().addingTimeInterval(86400)
        )
    }
}