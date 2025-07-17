import Foundation

protocol AuthenticationUseCaseProtocol: Sendable {
    func signInWithEmail(email: String, password: String) async throws -> User
    func signInWithGoogle() async throws -> User
    func signInWithApple() async throws -> User
    func signOut() async throws
    func getCurrentUser() async -> User?
}

final class AuthenticationUseCase: AuthenticationUseCaseProtocol {
    private let repository: AuthenticationRepositoryProtocol
    
    init(repository: AuthenticationRepositoryProtocol) {
        self.repository = repository
    }
    
    func signInWithEmail(email: String, password: String) async throws -> User {
        return try await repository.signInWithEmail(email: email, password: password)
    }
    
    func signInWithGoogle() async throws -> User {
        return try await repository.signInWithGoogle()
    }
    
    func signInWithApple() async throws -> User {
        return try await repository.signInWithApple()
    }
    
    func signOut() async throws {
        try await repository.signOut()
    }
    
    func getCurrentUser() async -> User? {
        return await repository.getCurrentUser()
    }
}
