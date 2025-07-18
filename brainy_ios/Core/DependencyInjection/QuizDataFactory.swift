import Foundation
import SwiftData

/// 퀴즈 데이터 관련 의존성을 생성하는 팩토리
@MainActor
class QuizDataFactory {
    
    /// 공유 인스턴스
    static let shared = QuizDataFactory()
    
    private init() {}
    
    /// 퀴즈 데이터 유스케이스를 생성합니다
    static func createQuizDataUseCase(modelContext: ModelContext) -> QuizDataUseCaseProtocol {
        let localDataSource = LocalDataSource(modelContext: modelContext)
        let networkService = NetworkService()
        let quizDataManager = QuizDataManager(networkService: networkService)
        let quizSyncService = QuizSyncService(quizDataManager: quizDataManager, localDataSource: localDataSource)
        let quizRepository = QuizRepositoryImpl(localDataSource: localDataSource, quizSyncService: quizSyncService)
        
        return QuizDataUseCase(quizRepository: quizRepository)
    }
    
    /// 테스트용 Mock 퀴즈 데이터 유스케이스를 생성합니다
    static func createMockQuizDataUseCase(modelContext: ModelContext, shouldHaveUpdates: Bool = false) -> QuizDataUseCaseProtocol {
        let localDataSource = LocalDataSource(modelContext: modelContext)
        let mockQuizDataManager = MockQuizDataManager(shouldHaveUpdates: shouldHaveUpdates)
        let quizSyncService = QuizSyncService(quizDataManager: mockQuizDataManager, localDataSource: localDataSource)
        let quizRepository = QuizRepositoryImpl(localDataSource: localDataSource, quizSyncService: quizSyncService)
        
        return QuizDataUseCase(quizRepository: quizRepository)
    }
    
    /// 퀴즈 리포지토리를 생성합니다
    static func createQuizRepository(modelContext: ModelContext) -> QuizRepositoryProtocol {
        let localDataSource = LocalDataSource(modelContext: modelContext)
        let networkService = NetworkService()
        let quizDataManager = QuizDataManager(networkService: networkService)
        let quizSyncService = QuizSyncService(quizDataManager: quizDataManager, localDataSource: localDataSource)
        
        return QuizRepositoryImpl(localDataSource: localDataSource, quizSyncService: quizSyncService)
    }
    
    /// 네트워크 서비스를 생성합니다
    static func createNetworkService(baseURL: String? = nil) -> NetworkServiceProtocol {
        if let baseURL = baseURL {
            return NetworkService(baseURL: baseURL)
        }
        return NetworkService()
    }
    
    /// 퀴즈 데이터 매니저를 생성합니다
    static func createQuizDataManager(networkService: NetworkServiceProtocol? = nil) -> QuizDataManagerProtocol {
        let service = networkService ?? NetworkService()
        return QuizDataManager(networkService: service)
    }
    
    /// 퀴즈 동기화 서비스를 생성합니다
    static func createQuizSyncService(
        modelContext: ModelContext,
        quizDataManager: QuizDataManagerProtocol? = nil
    ) -> QuizSyncServiceProtocol {
        let localDataSource = LocalDataSource(modelContext: modelContext)
        let dataManager = quizDataManager ?? QuizDataManager()
        
        return QuizSyncService(quizDataManager: dataManager, localDataSource: localDataSource)
    }
    
    /// 인스턴스 메서드로 퀴즈 리포지토리를 생성합니다 (임시 구현)
    func makeQuizRepository() -> QuizRepositoryProtocol {
        // 실제 앱에서는 ModelContext를 주입받아야 하지만, 
        // 임시로 더미 구현을 반환합니다
        return MockQuizRepository()
    }
}

/// 임시 Mock 퀴즈 리포지토리 (Task 10 구현을 위한 임시 구현)
@MainActor
class MockQuizRepository: QuizRepositoryProtocol {
    func getQuestions(category: QuizCategory, excludeCompleted: Bool) async throws -> [QuizQuestion] {
        // 임시 더미 데이터 반환
        return [
            QuizQuestion(
                id: "1",
                question: "대한민국의 수도는 어디인가요?",
                correctAnswer: "서울",
                category: category,
                difficulty: .easy,
                type: .multipleChoice,
                options: ["서울", "부산", "대구", "인천"]
            ),
            QuizQuestion(
                id: "2",
                question: "세종대왕이 만든 문자는 무엇인가요?",
                correctAnswer: "한글",
                category: category,
                difficulty: .medium,
                type: .shortAnswer
            ),
            QuizQuestion(
                id: "3",
                question: "태양계에서 가장 큰 행성은?",
                correctAnswer: "목성",
                category: category,
                difficulty: .medium,
                type: .multipleChoice,
                options: ["지구", "목성", "토성", "화성"]
            )
        ]
    }
    
    func saveQuizResult(_ result: QuizResult) async throws {
        // 임시 구현 - 실제로는 저장하지 않음
    }
    
    func getQuizHistory(userId: String) async throws -> [QuizSession] {
        return []
    }
    
    func markQuestionAsCompleted(questionId: String) async throws {
        // 임시 구현 - 실제로는 저장하지 않음
    }
    
    func getQuizVersion() async throws -> String {
        return "1.0.0"
    }
    
    func downloadQuizData() async throws -> [QuizQuestion] {
        return []
    }
    
    func performInitialDataLoad() async throws {
        // 임시 구현
    }
    
    func forceSync() async throws {
        // 임시 구현
    }
    
    func getSyncStatus() -> QuizSyncStatus {
        return QuizSyncStatus(
          currentVersion: "1.0.0",
          totalQuestions: 100,
          isOffline: false,
          lastSyncDate: Date()
        )
    }
    
    func isOfflineMode() -> Bool {
        return false
    }
}
