import Foundation
import SwiftUI

/// 동기화 기능을 관리하는 ViewModel
@MainActor
class SyncViewModel: ObservableObject {
    @Published var isSyncing = false
    @Published var syncStatus: String = ""
    @Published var lastSyncDate: Date?
    @Published var showingSyncAlert = false
    @Published var syncMessage = ""
    @Published var syncError: BrainyError?
    
    private let syncManager: SyncManager
    private let localDataSource: LocalDataSource
    
    init(syncManager: SyncManager, localDataSource: LocalDataSource) {
        self.syncManager = syncManager
        self.localDataSource = localDataSource
    }
    
    // MARK: - Public Methods
    
    /// 사용자 데이터를 동기화합니다
    func syncUserData(userId: String) async {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncStatus = "동기화 중..."
        syncError = nil
        
        do {
            // 동기화 실행
            try await syncManager.syncUserProgress(userId: userId)
            
            // 성공 시 UI 업데이트
            await updateLastSyncDate(userId: userId)
            syncMessage = "데이터 동기화가 완료되었습니다."
            syncStatus = "동기화 완료"
            showingSyncAlert = true
            
        } catch let error as BrainyError {
            // 에러 처리
            syncError = error
            syncMessage = error.localizedDescription
            syncStatus = "동기화 실패"
            showingSyncAlert = true
            
        } catch {
            // 예상치 못한 에러
            let brainyError = BrainyError.syncFailed(error.localizedDescription)
            syncError = brainyError
            syncMessage = brainyError.localizedDescription
            syncStatus = "동기화 실패"
            showingSyncAlert = true
        }
        
        isSyncing = false
    }
    
    /// 서버에서 사용자 데이터를 복원합니다
    func restoreUserData(userId: String) async {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncStatus = "데이터 복원 중..."
        syncError = nil
        
        do {
            // 데이터 복원 실행
            try await syncManager.restoreUserData(userId: userId)
            
            // 성공 시 UI 업데이트
            await updateLastSyncDate(userId: userId)
            syncMessage = "데이터 복원이 완료되었습니다."
            syncStatus = "복원 완료"
            showingSyncAlert = true
            
        } catch let error as BrainyError {
            // 에러 처리
            syncError = error
            syncMessage = error.localizedDescription
            syncStatus = "복원 실패"
            showingSyncAlert = true
            
        } catch {
            // 예상치 못한 에러
            let brainyError = BrainyError.syncFailed(error.localizedDescription)
            syncError = brainyError
            syncMessage = brainyError.localizedDescription
            syncStatus = "복원 실패"
            showingSyncAlert = true
        }
        
        isSyncing = false
    }
    
    /// 동기화 상태를 확인합니다
    func checkSyncStatus(userId: String) async {
        do {
            let status = try await syncManager.getSyncStatus(userId: userId)
            
            if status.isUpToDate {
                syncStatus = "최신 상태"
            } else if status.pendingChanges > 0 {
                syncStatus = "\(status.pendingChanges)개 변경사항 대기 중"
            } else {
                syncStatus = "동기화 필요"
            }
            
            lastSyncDate = status.lastSyncAt
            
        } catch {
            syncStatus = "상태 확인 실패"
        }
    }
    
    /// 마지막 동기화 날짜를 업데이트합니다
    func updateLastSyncDate(userId: String) async {
        do {
            let user = try localDataSource.fetchUser(byId: userId)
            lastSyncDate = user?.lastSyncAt
        } catch {
            // 에러 무시 (UI 업데이트만 실패)
        }
    }
    
    /// 동기화 진행 상태를 확인합니다
    func checkSyncProgress() async -> Bool {
        return await syncManager.syncInProgress
    }
    
    // MARK: - Helper Methods
    
    /// 마지막 동기화 날짜를 문자열로 포맷합니다
    var lastSyncDateString: String {
        guard let lastSyncDate = lastSyncDate else {
            return "동기화한 적 없음"
        }
        
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        // 오늘인지 확인
        if calendar.isDate(lastSyncDate, inSameDayAs: now) {
            formatter.dateFormat = "오늘 HH:mm"
        } 
        // 어제인지 확인
        else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
                calendar.isDate(lastSyncDate, inSameDayAs: yesterday) {
            formatter.dateFormat = "'어제' HH:mm"
        } 
        // 이번 주인지 확인
        else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(lastSyncDate) == true {
            formatter.dateFormat = "EEEE HH:mm"
        } 
        // 그 외의 경우
        else {
            formatter.dateFormat = "MM/dd HH:mm"
        }
        
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: lastSyncDate)
    }
    
    /// 동기화 상태 아이콘을 반환합니다
    var syncStatusIcon: String {
        if isSyncing {
            return "arrow.triangle.2.circlepath"
        } else if syncError != nil {
            return "exclamationmark.triangle"
        } else if lastSyncDate != nil {
            return "checkmark.circle"
        } else {
            return "arrow.triangle.2.circlepath"
        }
    }
    
    /// 동기화 상태 색상을 반환합니다
    var syncStatusColor: Color {
        if isSyncing {
            return .brainyPrimary
        } else if syncError != nil {
            return .red
        } else if lastSyncDate != nil {
            return .brainySuccess
        } else {
            return .brainyTextSecondary
        }
    }
    
    /// 알림 메시지를 초기화합니다
    func clearSyncMessage() {
        syncMessage = ""
        syncError = nil
        showingSyncAlert = false
    }
}