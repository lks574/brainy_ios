import Foundation

protocol AuthenticationRepositoryProtocol: Sendable {
    func signInWithEmail(email: String, password: String) async throws -> User
    func signInWithGoogle() async throws -> User
    func signInWithApple() async throws -> User
    func signOut() async throws
    func getCurrentUser() async -> User?
}
