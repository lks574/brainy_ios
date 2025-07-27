import Foundation
import SwiftUI

/// 로컬 우선 동기화 기능을 관리하는 ViewModel
@MainActor
class SyncViewModel: ObservableObject {
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var pendingSyncCount: Int = 0
    @Published var syncProgress: Double = 0.0
    @Published var showingSyncAlert = false
    @Published var syncMessage = ""
    @Published var isOfflineMode = false
    
    // 리더보드 관련
    @Published var cachedLeaderboard: LeaderboardData?
    @Published var canSyncLeaderboard = true
    @Published var nextLeaderboardSyncTime: Date?
    
    private let localFirstSyncManager: LocalFirstSyncManager
    private let localDataManager: LocalDataManager
    
    init(localFirstSyncManager: LocalFirstSyncManager, localDataManager: LocalDataManager) {
        self.localFirstSyncManager = localFirstSyncManager
        self.localDataManager = localDataManager
        
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Initialization
    
    /// 초기 데이터 로드
    private func loadInitialData() async {
        await updateSyncStatus()
        await loadCachedLeaderboard()
        await updateOfflineMode()
        await updateLeaderboardSyncInfo()
    }
    
    // MARK: - Manual Sync Methods
    
    /// 수동 동기화 실행 (사용자가 버튼 클릭 시)
    func performManualSync(for userId: String) async {
        guard !syncStatus.isInProgress else { return }
        
        do {
            try await localFirstSyncManager.manualSync(for: userId)
            
            await updateSyncStatus()
            await loadCachedLeaderboard()
            await updateLeaderboardSyncInfo()
            
            syncMessage = "동기화가 완료되었습니다."
            showingSyncAlert = true
            
        } catch {
            syncMessage = "동기화 실패: \(error.localizedDescription)"
            showingSyncAlert = true
        }
    }
    
    /// 로컬 데이터 통계 업데이트
    func updateLocalStats(for userId: String) async {
        do {
            let stats = try await localDataManager.calculateLocalStats(for: userId)
            // 통계 업데이트 완료 (UI에서 별도로 관찰)
        } catch {
            print("Failed to update local stats: \(error)")
        }
    }
    
    /// 동기화 상태 업데이트
    private func updateSyncStatus() async {
        syncStatus = await localFirstSyncManager.syncStatus
        lastSyncTime = await localFirstSyncManager.lastSyncTime
        pendingSyncCount = await localFirstSyncManager.pendingSyncCount
        syncProgress = await localFirstSyncManager.syncProgress
    }
    
    /// 캐시된 리더보드 로드
    private func loadCachedLeaderboard() async {
        cachedLeaderboard = await localFirstSyncManager.getCachedLeaderboard()
    }
    
    /// 오프라인 모드 상태 업데이트
    private func updateOfflineMode() async {
        isOfflineMode = await localFirstSyncManager.isOfflineMode()
    }
    
    /// 리더보드 동기화 정보 업데이트
    private func updateLeaderboardSyncInfo() async {
        canSyncLeaderboard = await localFirstSyncManager.canSyncLeaderboard()
        
        let timeUntilNext = await localFirstSyncManager.timeUntilNextLeaderboardSync()
        if timeUntilNext > 0 {
            nextLeaderboardSyncTime = Date().addingTimeInterval(timeUntilNext)
        } else {
            nextLeaderboardSyncTime = nil
        }
    }
    
    // MARK: - Computed Properties
    
    /// 마지막 동기화 시간을 문자열로 포맷
    var lastSyncTimeString: String {
        guard let lastSyncTime = lastSyncTime else {
            return "동기화한 적 없음"
        }
        
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDate(lastSyncTime, inSameDayAs: now) {
            formatter.dateFormat = "오늘 HH:mm"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
                  calendar.isDate(lastSyncTime, inSameDayAs: yesterday) {
            formatter.dateFormat = "어제 HH:mm"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(lastSyncTime) == true {
            formatter.dateFormat = "EEEE HH:mm"
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
        }
        
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: lastSyncTime)
    }
    
    /// 동기화 상태 메시지
    var syncStatusMessage: String {
        switch syncStatus {
        case .idle:
            if pendingSyncCount > 0 {
                return "\(pendingSyncCount)개 항목 동기화 대기 중"
            } else {
                return "최신 상태"
            }
        case .syncing(let progress):
            return "동기화 중... \(Int(progress * 100))%"
        case .completed:
            return "동기화 완료"
        case .failed(let error):
            return "동기화 실패: \(error.localizedDescription)"
        }
    }
    
    /// 리더보드 캐시 나이 문자열
    var leaderboardCacheAgeString: String? {
        return cachedLeaderboard?.cacheAgeString
    }
    
    /// 다음 리더보드 동기화까지 남은 시간 문자열
    var nextLeaderboardSyncString: String? {
        guard let nextTime = nextLeaderboardSyncTime else { return nil }
        
        let timeInterval = nextTime.timeIntervalSinceNow
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분 후"
        } else {
            return "\(minutes)분 후"
        }
    }
    
    /// 동기화 상태 아이콘
    var syncStatusIcon: String {
        switch syncStatus {
        case .idle:
            if pendingSyncCount > 0 {
                return "arrow.triangle.2.circlepath"
            } else {
                return "checkmark.circle"
            }
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
    
    /// 동기화 상태 색상
    var syncStatusColor: Color {
        switch syncStatus {
        case .idle:
            if pendingSyncCount > 0 {
                return .brainySecondary
            } else {
                return .brainySuccess
            }
        case .syncing:
            return .brainyPrimary
        case .completed:
            return .brainySuccess
        case .failed:
            return .red
        }
    }
    
    /// 동기화 버튼 활성화 여부
    var isSyncButtonEnabled: Bool {
        return !syncStatus.isInProgress && !isOfflineMode
    }
    
    // MARK: - Actions
    
    /// 동기화 메시지 초기화
    func clearSyncMessage() {
        syncMessage = ""
        showingSyncAlert = false
    }
    
    /// 상태 새로고침
    func refreshStatus() async {
        await updateSyncStatus()
        await updateOfflineMode()
        await updateLeaderboardSyncInfo()
    }
}