import Foundation
import SwiftData

/// 퀴즈 데이터 관련 의존성을 생성하는 팩토리
@MainActor
class QuizDataFactory {
    
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
}