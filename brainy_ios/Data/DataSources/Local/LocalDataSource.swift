import Foundation
import SwiftData

/// SwiftData를 사용한 로컬 데이터 소스
@MainActor
class LocalDataSource {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Generic CRUD Operations
    
    /// 엔티티를 저장합니다
    func save<T: PersistentModel>(_ entity: T) throws {
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    /// 여러 엔티티를 배치로 저장합니다
    func saveBatch<T: PersistentModel>(_ entities: [T]) throws {
        for entity in entities {
            modelContext.insert(entity)
        }
        try modelContext.save()
    }
    
    /// 엔티티를 업데이트합니다
    func update() throws {
        try modelContext.save()
    }
    
    /// 엔티티를 삭제합니다
    func delete<T: PersistentModel>(_ entity: T) throws {
        modelContext.delete(entity)
        try modelContext.save()
    }
    
    /// 여러 엔티티를 배치로 삭제합니다
    func deleteBatch<T: PersistentModel>(_ entities: [T]) throws {
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }
    
    /// 모든 엔티티를 조회합니다
    func fetchAll<T: PersistentModel>(_ type: T.Type) throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try modelContext.fetch(descriptor)
    }
    
    /// 조건에 맞는 엔티티를 조회합니다
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        return try modelContext.fetch(descriptor)
    }
    
    /// ID로 엔티티를 조회합니다
    func fetchByID<T: PersistentModel>(_ type: T.Type, id: String) throws -> T? {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = 1
        
        // Note: SwiftData에서는 predicate를 사용해야 하지만, 
        // 여기서는 간단히 모든 데이터를 가져와서 필터링합니다
        let allEntities = try fetchAll(type)
        
        // User, QuizQuestion, QuizResult, QuizSession 모두 id 프로퍼티를 가지고 있다고 가정
        return allEntities.first { entity in
            if let user = entity as? User {
                return user.id == id
            } else if let question = entity as? QuizQuestion {
                return question.id == id
            } else if let result = entity as? QuizResult {
                return result.id == id
            } else if let session = entity as? QuizSession {
                return session.id == id
            }
            return false
        }
    }
    
    /// 엔티티 개수를 조회합니다
    func count<T: PersistentModel>(_ type: T.Type) throws -> Int {
        let descriptor = FetchDescriptor<T>()
        return try modelContext.fetchCount(descriptor)
    }
}

// MARK: - User Operations
extension LocalDataSource {
    
    /// 사용자를 저장합니다
    func saveUser(_ user: User) throws {
        try save(user)
    }
    
    /// 사용자를 조회합니다
    func fetchUser(byId id: String) throws -> User? {
        return try fetchByID(User.self, id: id)
    }
    
    /// 이메일로 사용자를 조회합니다
    func fetchUser(byEmail email: String) throws -> User? {
        let allUsers = try fetchAll(User.self)
        return allUsers.first { $0.email == email }
    }
    
    /// 모든 사용자를 조회합니다
    func fetchAllUsers() throws -> [User] {
        return try fetchAll(User.self)
    }
    
    /// 사용자를 삭제합니다
    func deleteUser(_ user: User) throws {
        try delete(user)
    }
}

// MARK: - QuizQuestion Operations
extension LocalDataSource {
    
    /// 퀴즈 문제를 저장합니다
    func saveQuizQuestion(_ question: QuizQuestion) throws {
        try save(question)
    }
    
    /// 퀴즈 문제들을 배치로 저장합니다
    func saveQuizQuestions(_ questions: [QuizQuestion]) throws {
        try saveBatch(questions)
    }
    
    /// 퀴즈 문제를 조회합니다
    func fetchQuizQuestion(by id: String) throws -> QuizQuestion? {
        return try fetchByID(QuizQuestion.self, id: id)
    }
    
    /// 카테고리별 퀴즈 문제를 조회합니다
    func fetchQuizQuestions(by category: QuizCategory) throws -> [QuizQuestion] {
        let allQuestions = try fetchAll(QuizQuestion.self)
        return allQuestions.filter { $0.category == category }
    }
    
    /// 타입별 퀴즈 문제를 조회합니다
    func fetchQuizQuestions(by type: QuizType) throws -> [QuizQuestion] {
        let allQuestions = try fetchAll(QuizQuestion.self)
        return allQuestions.filter { $0.type == type }
    }
    
    /// 완료되지 않은 퀴즈 문제를 조회합니다
    func fetchUncompletedQuizQuestions(category: QuizCategory? = nil) throws -> [QuizQuestion] {
        let allQuestions = try fetchAll(QuizQuestion.self)
        var filteredQuestions = allQuestions.filter { !$0.isCompleted }
        
        if let category = category {
            filteredQuestions = filteredQuestions.filter { $0.category == category }
        }
        
        return filteredQuestions
    }
    
    /// 모든 퀴즈 문제를 조회합니다
    func fetchAllQuizQuestions() throws -> [QuizQuestion] {
        return try fetchAll(QuizQuestion.self)
    }
    
    /// 퀴즈 문제를 삭제합니다
    func deleteQuizQuestion(_ question: QuizQuestion) throws {
        try delete(question)
    }
    
    /// 모든 퀴즈 문제를 삭제합니다
    func deleteAllQuizQuestions() throws {
        let allQuestions = try fetchAll(QuizQuestion.self)
        try deleteBatch(allQuestions)
    }
}

// MARK: - QuizResult Operations
extension LocalDataSource {
    
    /// 퀴즈 결과를 저장합니다
    func saveQuizResult(_ result: QuizResult) throws {
        try save(result)
    }
    
    /// 퀴즈 결과들을 배치로 저장합니다
    func saveQuizResults(_ results: [QuizResult]) throws {
        try saveBatch(results)
    }
    
    /// 퀴즈 결과를 조회합니다
    func fetchQuizResult(by id: String) throws -> QuizResult? {
        return try fetchByID(QuizResult.self, id: id)
    }
    
    /// 사용자별 퀴즈 결과를 조회합니다
    func fetchQuizResults(by userId: String) throws -> [QuizResult] {
        let allResults = try fetchAll(QuizResult.self)
        return allResults.filter { $0.userId == userId }
    }
    
    /// 카테고리별 퀴즈 결과를 조회합니다
    func fetchQuizResults(by category: QuizCategory, userId: String) throws -> [QuizResult] {
        let allResults = try fetchAll(QuizResult.self)
        return allResults.filter { $0.category == category && $0.userId == userId }
    }
    
    /// 모든 퀴즈 결과를 조회합니다
    func fetchAllQuizResults() throws -> [QuizResult] {
        return try fetchAll(QuizResult.self)
    }
    
    /// 퀴즈 결과를 삭제합니다
    func deleteQuizResult(_ result: QuizResult) throws {
        try delete(result)
    }
}

// MARK: - QuizSession Operations
extension LocalDataSource {
    
    /// 퀴즈 세션을 저장합니다
    func saveQuizSession(_ session: QuizSession) throws {
        try save(session)
    }
    
    /// 퀴즈 세션을 조회합니다
    func fetchQuizSession(by id: String) throws -> QuizSession? {
        return try fetchByID(QuizSession.self, id: id)
    }
    
    /// 사용자별 퀴즈 세션을 조회합니다
    func fetchQuizSessions(by userId: String) throws -> [QuizSession] {
        let allSessions = try fetchAll(QuizSession.self)
        return allSessions.filter { $0.userId == userId }
    }
    
    /// 완료되지 않은 퀴즈 세션을 조회합니다
    func fetchIncompleteQuizSessions(by userId: String) throws -> [QuizSession] {
        let allSessions = try fetchAll(QuizSession.self)
        return allSessions.filter { $0.userId == userId && $0.completedAt == nil }
    }
    
    /// 완료된 퀴즈 세션을 조회합니다
    func fetchCompletedQuizSessions(by userId: String) throws -> [QuizSession] {
        let allSessions = try fetchAll(QuizSession.self)
        return allSessions.filter { $0.userId == userId && $0.completedAt != nil }
    }
    
    /// 모든 퀴즈 세션을 조회합니다
    func fetchAllQuizSessions() throws -> [QuizSession] {
        return try fetchAll(QuizSession.self)
    }
    
    /// 퀴즈 세션을 삭제합니다
    func deleteQuizSession(_ session: QuizSession) throws {
        try delete(session)
    }
}
