import Foundation
import SwiftUI

/// 퀴즈 데이터 관리를 위한 ViewModel
@MainActor
@Observable
class QuizDataViewModel {
    private let quizDataUseCase: QuizDataUseCaseProtocol
    
    // Published properties
    var isLoading: Bool = false
    var isSyncing: Bool = false
    var errorMessage: String?
    var syncStatus: QuizSyncStatus?
    var dataStatistics: QuizDataStatistics?
    
    init(quizDataUseCase: QuizDataUseCaseProtocol) {
        self.quizDataUseCase = quizDataUseCase
        updateSyncStatus()
    }
    
    /// 앱 시작 시 퀴즈 데이터를 초기화합니다
    func initializeData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await quizDataUseCase.initializeQuizData()
            updateSyncStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// 퀴즈 데이터를 동기화합니다
    func syncData() async {
        isSyncing = true
        errorMessage = nil
        
        do {
            let hasUpdates = try await quizDataUseCase.syncQuizData()
            updateSyncStatus()
            
            if hasUpdates {
                // 업데이트가 있었음을 사용자에게 알림
                showSuccessMessage("퀴즈 데이터가 업데이트되었습니다.")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    /// 강제 동기화를 수행합니다
    func forceSync() async {
        isSyncing = true
        errorMessage = nil
        
        do {
            try await quizDataUseCase.forceSync()
            updateSyncStatus()
            showSuccessMessage("퀴즈 데이터가 강제 동기화되었습니다.")
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    /// 업데이트 확인
    func checkForUpdates() async -> Bool {
        do {
            return try await quizDataUseCase.checkForUpdates()
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// 동기화 상태를 업데이트합니다
    private func updateSyncStatus() {
        syncStatus = quizDataUseCase.getSyncStatus()
        dataStatistics = quizDataUseCase.getQuizDataStatistics()
    }
    
    /// 성공 메시지를 표시합니다 (임시 구현)
    private func showSuccessMessage(_ message: String) {
        // TODO: 실제 앱에서는 토스트 메시지나 알림으로 표시
        print("Success: \(message)")
    }
    
    /// 오프라인 모드인지 확인합니다
    var isOfflineMode: Bool {
        return quizDataUseCase.isOfflineMode()
    }
    
    /// 에러 메시지를 클리어합니다
    func clearError() {
        errorMessage = nil
    }
    
    /// 동기화 상태 설명을 반환합니다
    var syncStatusDescription: String {
        return syncStatus?.statusDescription ?? "알 수 없음"
    }
    
    /// 마지막 동기화 시간 설명을 반환합니다
    var lastSyncDescription: String {
        return dataStatistics?.lastSyncDescription ?? "동기화된 적 없음"
    }
    
    /// 총 퀴즈 문제 수를 반환합니다
    var totalQuestions: Int {
        return syncStatus?.totalQuestions ?? 0
    }
    
    /// 현재 버전을 반환합니다
    var currentVersion: String {
        return syncStatus?.currentVersion ?? "알 수 없음"
    }
}
