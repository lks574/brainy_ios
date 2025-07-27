import Foundation

/// 동기화 가능한 엔티티를 위한 프로토콜
protocol Syncable {
    var id: String { get }
    var lastModified: Date { get set }
    var needsSync: Bool { get set }
    var syncedAt: Date? { get set }
}

/// 동기화 상태
enum SyncStatus {
    case idle
    case syncing(progress: Double)
    case completed
    case failed(Error)
    
    var isInProgress: Bool {
        if case .syncing = self {
            return true
        }
        return false
    }
    
    var progressValue: Double {
        if case .syncing(let progress) = self {
            return progress
        }
        return 0.0
    }
}

/// 동기화 통계
struct SyncStatistics {
    let totalItems: Int
    let pendingItems: Int
    let syncedItems: Int
    let failedItems: Int
    let lastSyncTime: Date?
    
    var syncProgress: Double {
        guard totalItems > 0 else { return 1.0 }
        return Double(syncedItems) / Double(totalItems)
    }
    
    var hasPendingItems: Bool {
        return pendingItems > 0
    }
}

/// 배치 동기화 요청
struct BatchSyncRequest {
    let sessions: [QuizSession]
    let results: [QuizResult]
    let lastSyncAt: Date?
    
    var totalItems: Int {
        return sessions.count + results.count
    }
    
    var isEmpty: Bool {
        return sessions.isEmpty && results.isEmpty
    }
}

/// 배치 동기화 응답
struct BatchSyncResponse {
    let syncedSessions: Int
    let syncedResults: Int
    let failedSessions: Int
    let failedResults: Int
    let syncedAt: Date
    
    var totalSynced: Int {
        return syncedSessions + syncedResults
    }
    
    var totalFailed: Int {
        return failedSessions + failedResults
    }
    
    var isSuccess: Bool {
        return totalFailed == 0
    }
}