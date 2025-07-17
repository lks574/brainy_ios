import Foundation
import SwiftData

/// 데이터 마이그레이션 및 버전 관리를 담당하는 매니저
@MainActor
class DataMigrationManager {
    private let localDataSource: LocalDataSource
    private let userDefaults = UserDefaults.standard
    
    // 현재 앱의 데이터 버전
    private static let currentDataVersion = "1.0.0"
    private static let dataVersionKey = "BrainyDataVersion"
    private static let lastQuizUpdateKey = "LastQuizUpdateDate"
    
    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }
    
    /// 앱 시작 시 데이터 마이그레이션을 수행합니다
    func performMigrationIfNeeded() async throws {
        let currentVersion = getCurrentDataVersion()
        let appVersion = Self.currentDataVersion
        
        if currentVersion != appVersion {
            try await performMigration(from: currentVersion, to: appVersion)
            setCurrentDataVersion(appVersion)
        }
        
        // 퀴즈 데이터 업데이트 확인
        try await checkAndUpdateQuizData()
    }
    
    /// 데이터 마이그레이션을 수행합니다
    private func performMigration(from oldVersion: String, to newVersion: String) async throws {
        print("데이터 마이그레이션 시작: \(oldVersion) -> \(newVersion)")
        
        switch (oldVersion, newVersion) {
        case ("", "1.0.0"):
            // 첫 설치 시 초기 데이터 설정
            try await performInitialSetup()
            
        case ("1.0.0", "1.1.0"):
            // 버전 1.1.0으로 마이그레이션 (예시)
            try await migrateToVersion1_1_0()
            
        default:
            // 알 수 없는 버전 조합
            print("알 수 없는 마이그레이션 경로: \(oldVersion) -> \(newVersion)")
        }
        
        print("데이터 마이그레이션 완료")
    }
    
    /// 초기 설정을 수행합니다
    private func performInitialSetup() async throws {
        print("초기 데이터 설정 시작")
        
        // 샘플 퀴즈 데이터가 없다면 생성
        let existingQuestions = try localDataSource.fetchAllQuizQuestions()
        if existingQuestions.isEmpty {
            let sampleQuestions = createInitialQuizData()
            try localDataSource.saveQuizQuestions(sampleQuestions)
            print("초기 퀴즈 데이터 \(sampleQuestions.count)개 생성 완료")
        }
    }
    
    /// 버전 1.1.0으로 마이그레이션 (예시)
    private func migrateToVersion1_1_0() async throws {
        print("버전 1.1.0 마이그레이션 시작")
        
        // 예시: 새로운 필드 추가, 데이터 구조 변경 등
        // 실제 마이그레이션 로직 구현
        
        print("버전 1.1.0 마이그레이션 완료")
    }
    
    /// 퀴즈 데이터 업데이트를 확인하고 수행합니다
    private func checkAndUpdateQuizData() async throws {
        let lastUpdateDate = getLastQuizUpdateDate()
        let currentDate = Date()
        
        // 7일마다 퀴즈 데이터 업데이트 확인
        let daysSinceLastUpdate = Calendar.current.dateComponents([.day], from: lastUpdateDate, to: currentDate).day ?? 0
        
        if daysSinceLastUpdate >= 7 {
            print("퀴즈 데이터 업데이트 확인 중...")
            
            // TODO: 서버에서 최신 퀴즈 데이터 확인 및 다운로드
            // 현재는 로컬 데이터 검증만 수행
            try await validateLocalQuizData()
            
            setLastQuizUpdateDate(currentDate)
        }
    }
    
    /// 로컬 퀴즈 데이터의 유효성을 검사합니다
    private func validateLocalQuizData() async throws {
        let allQuestions = try localDataSource.fetchAllQuizQuestions()
        
        // 데이터 무결성 검사
        for question in allQuestions {
            if question.question.isEmpty || question.correctAnswer.isEmpty {
                print("잘못된 퀴즈 데이터 발견: \(question.id)")
                // 필요시 데이터 수정 또는 삭제
            }
        }
        
        print("퀴즈 데이터 검증 완료: \(allQuestions.count)개 문제")
    }
    
    /// 데이터베이스를 완전히 초기화합니다
    func resetAllData() async throws {
        print("모든 데이터 초기화 시작")
        
        // 모든 데이터 삭제
        let allUsers = try localDataSource.fetchAllUsers()
        let allQuestions = try localDataSource.fetchAllQuizQuestions()
        let allResults = try localDataSource.fetchAllQuizResults()
        let allSessions = try localDataSource.fetchAllQuizSessions()
        
        try localDataSource.deleteBatch(allUsers)
        try localDataSource.deleteBatch(allQuestions)
        try localDataSource.deleteBatch(allResults)
        try localDataSource.deleteBatch(allSessions)
        
        // UserDefaults 초기화
        userDefaults.removeObject(forKey: Self.dataVersionKey)
        userDefaults.removeObject(forKey: Self.lastQuizUpdateKey)
        
        print("모든 데이터 초기화 완료")
    }
    
    /// 데이터베이스 상태를 확인합니다
    func getDatabaseStatus() async throws -> DatabaseStatus {
        let userCount = try localDataSource.count(User.self)
        let questionCount = try localDataSource.count(QuizQuestion.self)
        let resultCount = try localDataSource.count(QuizResult.self)
        let sessionCount = try localDataSource.count(QuizSession.self)
        
        return DatabaseStatus(
            dataVersion: getCurrentDataVersion(),
            userCount: userCount,
            questionCount: questionCount,
            resultCount: resultCount,
            sessionCount: sessionCount,
            lastQuizUpdate: getLastQuizUpdateDate()
        )
    }
}

// MARK: - UserDefaults Helpers
extension DataMigrationManager {
    
    private func getCurrentDataVersion() -> String {
        return userDefaults.string(forKey: Self.dataVersionKey) ?? ""
    }
    
    private func setCurrentDataVersion(_ version: String) {
        userDefaults.set(version, forKey: Self.dataVersionKey)
    }
    
    private func getLastQuizUpdateDate() -> Date {
        return userDefaults.object(forKey: Self.lastQuizUpdateKey) as? Date ?? Date.distantPast
    }
    
    private func setLastQuizUpdateDate(_ date: Date) {
        userDefaults.set(date, forKey: Self.lastQuizUpdateKey)
    }
}

// MARK: - Sample Data Creation
extension DataMigrationManager {
    
    private func createInitialQuizData() -> [QuizQuestion] {
        return [
            // 일반 상식 문제
            QuizQuestion(
                id: "general_001",
                question: "대한민국의 수도는?",
                correctAnswer: "서울",
                category: .general,
                difficulty: .easy,
                type: .shortAnswer
            ),
            QuizQuestion(
                id: "general_002",
                question: "다음 중 대한민국의 수도는?",
                correctAnswer: "서울",
                category: .general,
                difficulty: .easy,
                type: .multipleChoice,
                options: ["서울", "부산", "대구", "인천"]
            ),
            
            // 인물 문제
            QuizQuestion(
                id: "person_001",
                question: "한글을 창제한 조선의 왕은?",
                correctAnswer: "세종대왕",
                category: .person,
                difficulty: .medium,
                type: .shortAnswer
            ),
            QuizQuestion(
                id: "person_002",
                question: "다음 중 조선을 건국한 인물은?",
                correctAnswer: "이성계",
                category: .person,
                difficulty: .medium,
                type: .multipleChoice,
                options: ["이성계", "정도전", "이방원", "최영"]
            ),
            
            // 나라 문제
            QuizQuestion(
                id: "country_001",
                question: "태극기의 중앙에 있는 원의 이름은?",
                correctAnswer: "태극",
                category: .country,
                difficulty: .hard,
                type: .shortAnswer
            ),
            QuizQuestion(
                id: "country_002",
                question: "다음 중 한국의 전통 음식이 아닌 것은?",
                correctAnswer: "스시",
                category: .country,
                difficulty: .medium,
                type: .multipleChoice,
                options: ["김치", "불고기", "스시", "비빔밥"]
            )
        ]
    }
}

// MARK: - Data Models
struct DatabaseStatus {
    let dataVersion: String
    let userCount: Int
    let questionCount: Int
    let resultCount: Int
    let sessionCount: Int
    let lastQuizUpdate: Date
}