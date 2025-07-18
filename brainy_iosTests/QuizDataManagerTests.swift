import XCTest
import SwiftData
@testable import brainy_ios

@MainActor
final class QuizDataManagerTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var quizDataUseCase: QuizDataUseCaseProtocol!

    override func setUp() async throws {
        // 인메모리 모델 컨테이너 생성
        let schema = Schema([User.self, QuizQuestion.self, QuizResult.self, QuizSession.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)

        // Mock 퀴즈 데이터 유스케이스 생성
        quizDataUseCase = QuizDataFactory.createMockQuizDataUseCase(modelContext: modelContext)
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        quizDataUseCase = nil
    }

    func testInitializeQuizData() async throws {
        // Given
        let initialSyncStatus = quizDataUseCase.getSyncStatus()
        XCTAssertEqual(initialSyncStatus.totalQuestions, 0)

        // When
        try await quizDataUseCase.initializeQuizData()

        // Then
        let finalSyncStatus = quizDataUseCase.getSyncStatus()
        XCTAssertGreaterThan(finalSyncStatus.totalQuestions, 0)
        XCTAssertNotNil(finalSyncStatus.currentVersion)
    }

    func testSyncQuizData() async throws {
        // Given
        try await quizDataUseCase.initializeQuizData()
        let initialSyncStatus = quizDataUseCase.getSyncStatus()

        // When
        let hasUpdates = try await quizDataUseCase.syncQuizData()

        // Then
        XCTAssertTrue(hasUpdates)
        let finalSyncStatus = quizDataUseCase.getSyncStatus()
        XCTAssertEqual(finalSyncStatus.totalQuestions, initialSyncStatus.totalQuestions)
    }

    func testOfflineMode() async throws {
        // Given
        let isOfflineInitially = quizDataUseCase.isOfflineMode()

        // When
        try await quizDataUseCase.initializeQuizData()

        // Then
        let isOfflineAfterInit = quizDataUseCase.isOfflineMode()
        XCTAssertFalse(isOfflineAfterInit) // Mock은 항상 온라인 모드
    }

    func testGetSyncStatus() async throws {
        // Given
        try await quizDataUseCase.initializeQuizData()

        // When
        let syncStatus = quizDataUseCase.getSyncStatus()

        // Then
        XCTAssertNotNil(syncStatus.currentVersion)
        XCTAssertGreaterThan(syncStatus.totalQuestions, 0)
        XCTAssertFalse(syncStatus.isOffline)
        XCTAssertNotNil(syncStatus.lastSyncDate)
    }

    func testForceSync() async throws {
        // Given
        try await quizDataUseCase.initializeQuizData()
        let initialSyncStatus = quizDataUseCase.getSyncStatus()

        // When
        try await quizDataUseCase.forceSync()

        // Then
        let finalSyncStatus = quizDataUseCase.getSyncStatus()
        XCTAssertEqual(finalSyncStatus.totalQuestions, initialSyncStatus.totalQuestions)
        XCTAssertNotNil(finalSyncStatus.lastSyncDate)
    }
}
