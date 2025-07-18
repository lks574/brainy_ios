import Foundation

/// 퀴즈 데이터 관리자 프로토콜
@MainActor
protocol QuizDataManagerProtocol {
    func checkForUpdates() async throws -> Bool
    func downloadLatestQuizData() async throws -> [QuizQuestion]
    func getCurrentVersion() -> String?
    func getLocalVersion() -> LocalQuizVersion?
    func saveLocalVersion(_ version: LocalQuizVersion) throws
}

/// 퀴즈 데이터 관리자 구현체
@MainActor
class QuizDataManager: QuizDataManagerProtocol {
    private let networkService: NetworkServiceProtocol
    private let userDefaults: UserDefaults
    private let localVersionKey = "local_quiz_version"
    
    init(networkService: NetworkServiceProtocol = NetworkService(), userDefaults: UserDefaults = .standard) {
        self.networkService = networkService
        self.userDefaults = userDefaults
    }
    
    /// 서버에서 업데이트가 있는지 확인합니다
    func checkForUpdates() async throws -> Bool {
        do {
            let serverVersion: QuizVersionResponse = try await networkService.request(QuizAPIEndpoint.getVersion)
            let currentVersion = getCurrentVersion()
            
            // 현재 버전이 없거나 서버 버전과 다르면 업데이트 필요
            return currentVersion == nil || currentVersion != serverVersion.version
            
        } catch {
            // 네트워크 오류 시 업데이트 불필요로 처리 (오프라인 모드)
            if case BrainyError.networkUnavailable = error {
                return false
            }
            throw error
        }
    }
    
    /// 최신 퀴즈 데이터를 다운로드합니다
    func downloadLatestQuizData() async throws -> [QuizQuestion] {
        // 먼저 서버 버전 정보를 가져옵니다
        let versionResponse: QuizVersionResponse = try await networkService.request(QuizAPIEndpoint.getVersion)
        
        // 퀴즈 데이터를 다운로드합니다
        let dataResponse: QuizDataResponse = try await networkService.request(
            QuizAPIEndpoint.downloadQuizData(version: versionResponse.version)
        )
        
        // DTO를 엔티티로 변환합니다
        let questions = dataResponse.questions.map { $0.toEntity() }
        
        // 로컬 버전 정보를 저장합니다
        let localVersion = LocalQuizVersion(
            version: dataResponse.version,
            lastUpdated: Date(),
            totalQuestions: questions.count
        )
        try saveLocalVersion(localVersion)
        
        return questions
    }
    
    /// 현재 로컬 버전을 반환합니다
    func getCurrentVersion() -> String? {
        guard let data = userDefaults.data(forKey: localVersionKey),
              let localVersion = try? JSONDecoder().decode(LocalQuizVersion.self, from: data) else {
            return nil
        }
        return localVersion.version
    }
    
    /// 로컬 버전 정보를 저장합니다
    func saveLocalVersion(_ version: LocalQuizVersion) throws {
        let data = try JSONEncoder().encode(version)
        userDefaults.set(data, forKey: localVersionKey)
    }
    
    /// 로컬 버전 정보를 조회합니다
    func getLocalVersion() -> LocalQuizVersion? {
        guard let data = userDefaults.data(forKey: localVersionKey),
              let localVersion = try? JSONDecoder().decode(LocalQuizVersion.self, from: data) else {
            return nil
        }
        return localVersion
    }
    
    /// 로컬 버전 정보를 삭제합니다 (초기화 시 사용)
    func clearLocalVersion() {
        userDefaults.removeObject(forKey: localVersionKey)
    }
}

/// 개발/테스트용 Mock 구현체
@MainActor
class MockQuizDataManager: QuizDataManagerProtocol {
    private var mockVersion: String = "1.0.0"
    private var shouldHaveUpdates: Bool = false
    private var mockQuestions: [QuizQuestion] = []
    
    init(mockVersion: String = "1.0.0", shouldHaveUpdates: Bool = false) {
        self.mockVersion = mockVersion
        self.shouldHaveUpdates = shouldHaveUpdates
        self.mockQuestions = createMockQuizData()
    }
    
    func checkForUpdates() async throws -> Bool {
        return shouldHaveUpdates
    }
    
    func downloadLatestQuizData() async throws -> [QuizQuestion] {
        return mockQuestions
    }
    
    func getCurrentVersion() -> String? {
        return mockVersion
    }
    
    func saveLocalVersion(_ version: LocalQuizVersion) throws {
        // Mock implementation - do nothing
    }
    
    func getLocalVersion() -> LocalQuizVersion? {
        return LocalQuizVersion(version: mockVersion, totalQuestions: mockQuestions.count)
    }
    
    private func createMockQuizData() -> [QuizQuestion] {
        return [
            QuizQuestion(
                id: "mock_q1",
                question: "대한민국의 수도는?",
                correctAnswer: "서울",
                category: .general,
                difficulty: .easy,
                type: .shortAnswer
            ),
            QuizQuestion(
                id: "mock_q2",
                question: "다음 중 대한민국의 수도는?",
                correctAnswer: "서울",
                category: .general,
                difficulty: .easy,
                type: .multipleChoice,
                options: ["서울", "부산", "대구", "인천"]
            ),
            QuizQuestion(
                id: "mock_q3",
                question: "세종대왕이 만든 문자는?",
                correctAnswer: "한글",
                category: .person,
                difficulty: .medium,
                type: .shortAnswer
            )
        ]
    }
}