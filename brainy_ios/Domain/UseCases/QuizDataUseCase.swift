import Foundation

/// 퀴즈 데이터 관리 유스케이스 프로토콜
@MainActor
protocol QuizDataUseCaseProtocol {
    func initializeQuizData() async throws
    func checkForUpdates() async throws -> Bool
    func syncQuizData() async throws -> Bool
    func forceSync() async throws
    func getSyncStatus() -> QuizSyncStatus
    func isOfflineMode() -> Bool
    func getQuizDataStatistics() -> QuizDataStatistics
}

/// 퀴즈 데이터 관리 유스케이스 구현체
@MainActor
class QuizDataUseCase: QuizDataUseCaseProtocol {
    private let quizRepository: QuizRepositoryProtocol
    
    init(quizRepository: QuizRepositoryProtocol) {
        self.quizRepository = quizRepository
    }
    
    /// 퀴즈 데이터를 초기화합니다 (앱 시작 시 호출)
    /// - 로컬 데이터가 없으면 서버에서 다운로드
    /// - 로컬 데이터가 있으면 백그라운드에서 업데이트 확인
    func initializeQuizData() async throws {
        try await quizRepository.performInitialDataLoad()
    }
    
    /// 서버에 업데이트가 있는지 확인합니다
    func checkForUpdates() async throws -> Bool {
        let currentVersion = try await quizRepository.getQuizVersion()
        let syncStatus = quizRepository.getSyncStatus()
        
        // 현재 버전과 로컬 버전을 비교
        if let localVersion = syncStatus.currentVersion {
            return currentVersion != localVersion
        }
        
        // 로컬 버전이 없으면 업데이트 필요
        return true
    }
    
    /// 퀴즈 데이터를 동기화합니다
    /// - Returns: 업데이트가 있었는지 여부
    func syncQuizData() async throws -> Bool {
        _ = try await quizRepository.downloadQuizData()
        return true
    }
    
    /// 강제로 동기화를 수행합니다 (사용자가 수동으로 요청)
    func forceSync() async throws {
        try await quizRepository.forceSync()
    }
    
    /// 동기화 상태를 확인합니다
    func getSyncStatus() -> QuizSyncStatus {
        return quizRepository.getSyncStatus()
    }
    
    /// 오프라인 모드인지 확인합니다
    func isOfflineMode() -> Bool {
        return quizRepository.isOfflineMode()
    }
    
    /// 퀴즈 데이터 통계를 반환합니다
    func getQuizDataStatistics() -> QuizDataStatistics {
        let syncStatus = getSyncStatus()
        
        return QuizDataStatistics(
            totalQuestions: syncStatus.totalQuestions,
            currentVersion: syncStatus.currentVersion ?? "알 수 없음",
            lastSyncDate: syncStatus.lastSyncDate,
            isOffline: syncStatus.isOffline
        )
    }
}

/// 퀴즈 데이터 통계 정보
struct QuizDataStatistics: Sendable {
    let totalQuestions: Int
    let currentVersion: String
    let lastSyncDate: Date?
    let isOffline: Bool
    
    var lastSyncDescription: String {
        guard let lastSyncDate = lastSyncDate else {
            return "동기화된 적 없음"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.localizedString(for: lastSyncDate, relativeTo: Date())
    }
    
    var statusDescription: String {
        if isOffline {
            return "오프라인 모드 - 로컬 데이터 사용 중"
        } else {
            return "온라인 모드 - 최신 데이터 사용 중"
        }
    }
}
