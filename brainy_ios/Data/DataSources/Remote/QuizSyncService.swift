import Foundation

/// 퀴즈 동기화 상태 정보
struct QuizSyncStatus: Sendable {
    let currentVersion: String?
    let totalQuestions: Int
    let isOffline: Bool
    let lastSyncDate: Date?
}

/// 퀴즈 동기화 서비스 프로토콜
@MainActor
protocol QuizSyncServiceProtocol {
    func syncQuizData() async throws -> Bool
    func forceSync() async throws
    func isOfflineMode() -> Bool
    func performInitialDataLoad() async throws
    func getSyncStatus() -> QuizSyncStatus
}

/// 퀴즈 동기화 서비스 구현체
@MainActor
class QuizSyncService: QuizSyncServiceProtocol {
    private let quizDataManager: QuizDataManagerProtocol
    private let localDataSource: LocalDataSource
    private var isCurrentlyOffline: Bool = false
    
    init(quizDataManager: QuizDataManagerProtocol, localDataSource: LocalDataSource) {
        self.quizDataManager = quizDataManager
        self.localDataSource = localDataSource
    }
    
    /// 퀴즈 데이터를 동기화합니다
    /// - Returns: 업데이트가 있었는지 여부
    func syncQuizData() async throws -> Bool {
        do {
            // 업데이트 확인
            let hasUpdates = try await quizDataManager.checkForUpdates()
            
            if hasUpdates {
                // 새로운 데이터 다운로드
                let newQuestions = try await quizDataManager.downloadLatestQuizData()
                
                // 기존 데이터 삭제 후 새 데이터 저장
                try await replaceQuizData(with: newQuestions)
                
                // 오프라인 모드 해제
                isCurrentlyOffline = false
                
                return true
            }
            
            // 오프라인 모드 해제
            isCurrentlyOffline = false
            return false
            
        } catch {
            // 네트워크 오류 시 오프라인 모드로 전환
            if case BrainyError.networkUnavailable = error {
                isCurrentlyOffline = true
                
                // 로컬 데이터가 있는지 확인
                let localQuestions = try localDataSource.fetchAllQuizQuestions()
                if localQuestions.isEmpty {
                    throw BrainyError.dataError("오프라인 상태에서 사용할 수 있는 퀴즈 데이터가 없습니다")
                }
                
                return false
            }
            
            throw error
        }
    }
    
    /// 강제로 동기화를 수행합니다 (사용자가 수동으로 요청한 경우)
    func forceSync() async throws {
        let newQuestions = try await quizDataManager.downloadLatestQuizData()
        try await replaceQuizData(with: newQuestions)
        isCurrentlyOffline = false
    }
    
    /// 현재 오프라인 모드인지 확인합니다
    func isOfflineMode() -> Bool {
        return isCurrentlyOffline
    }
    
    /// 기존 퀴즈 데이터를 새 데이터로 교체합니다
    private func replaceQuizData(with newQuestions: [QuizQuestion]) async throws {
        // 기존 퀴즈 데이터 삭제
        try localDataSource.deleteAllQuizQuestions()
        
        // 새 퀴즈 데이터 저장
        try localDataSource.saveQuizQuestions(newQuestions)
    }
    
    /// 초기 데이터 로드를 수행합니다 (앱 최초 실행 시)
    func performInitialDataLoad() async throws {
        let localQuestions = try localDataSource.fetchAllQuizQuestions()
        
        if localQuestions.isEmpty {
            // 로컬 데이터가 없으면 서버에서 다운로드
            do {
                let newQuestions = try await quizDataManager.downloadLatestQuizData()
                try localDataSource.saveQuizQuestions(newQuestions)
                isCurrentlyOffline = false
            } catch {
                if case BrainyError.networkUnavailable = error {
                    isCurrentlyOffline = true
                    throw BrainyError.dataError("초기 퀴즈 데이터를 다운로드할 수 없습니다. 네트워크 연결을 확인해주세요.")
                }
                throw error
            }
        } else {
            // 로컬 데이터가 있으면 백그라운드에서 업데이트 확인
            Task {
                do {
                    _ = try await syncQuizData()
                } catch {
                    // 백그라운드 동기화 실패는 무시 (로컬 데이터로 계속 사용)
                    print("Background sync failed: \(error)")
                }
            }
        }
    }
    
    /// 동기화 상태 정보를 반환합니다
    func getSyncStatus() -> QuizSyncStatus {
        let localVersion = quizDataManager.getCurrentVersion()
        let localQuestionCount = (try? localDataSource.fetchAllQuizQuestions().count) ?? 0
        
        return QuizSyncStatus(
            currentVersion: localVersion,
            totalQuestions: localQuestionCount,
            isOffline: isCurrentlyOffline,
            lastSyncDate: getLastSyncDate()
        )
    }
    
    private func getLastSyncDate() -> Date? {
        return quizDataManager.getLocalVersion()?.lastUpdated
    }
}

