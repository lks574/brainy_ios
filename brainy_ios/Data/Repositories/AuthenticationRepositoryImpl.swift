import Foundation
import SwiftData

/// AuthenticationRepository의 구현체
@MainActor
class AuthenticationRepositoryImpl: AuthenticationRepositoryProtocol {
    private let localDataSource: LocalDataSource
    private var currentUser: User?
    
    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }
    
    func signInWithEmail(email: String, password: String) async throws -> User {
        // TODO: 실제 Firebase Auth 또는 Supabase Auth 연동 필요
        // 현재는 로컬 사용자 확인 또는 생성
        
        // 기존 사용자 확인
        if let existingUser = try localDataSource.fetchUser(byEmail: email) {
            currentUser = existingUser
            return existingUser
        }
        
        // 새 사용자 생성
        let newUser = User(
            id: UUID().uuidString,
            email: email,
            displayName: extractDisplayName(from: email),
            authProvider: .email
        )
        
        try localDataSource.saveUser(newUser)
        currentUser = newUser
        return newUser
    }
    
    func signInWithGoogle() async throws -> User {
        // TODO: Google Sign-In SDK 연동 필요
        // 현재는 더미 구현
        
        let googleUser = User(
            id: "google_" + UUID().uuidString,
            email: "user@gmail.com",
            displayName: "Google User",
            authProvider: .google
        )
        
        // 기존 사용자 확인
        if let existingUser = try localDataSource.fetchUser(byId: googleUser.id) {
            currentUser = existingUser
            return existingUser
        }
        
        try localDataSource.saveUser(googleUser)
        currentUser = googleUser
        return googleUser
    }
    
    func signInWithApple() async throws -> User {
        // TODO: Sign in with Apple 연동 필요
        // 현재는 더미 구현
        
        let appleUser = User(
            id: "apple_" + UUID().uuidString,
            email: nil, // Apple 로그인은 이메일이 선택사항
            displayName: "Apple User",
            authProvider: .apple
        )
        
        // 기존 사용자 확인
        if let existingUser = try localDataSource.fetchUser(byId: appleUser.id) {
            currentUser = existingUser
            return existingUser
        }
        
        try localDataSource.saveUser(appleUser)
        currentUser = appleUser
        return appleUser
    }
    
    func signOut() async throws {
        // TODO: 실제 인증 서비스 로그아웃 처리 필요
        currentUser = nil
    }
    
    func getCurrentUser() async -> User? {
        return currentUser
    }
    
    // MARK: - Additional Methods
    
    /// 사용자 정보를 업데이트합니다
    func updateUser(_ user: User) async throws {
        try localDataSource.update()
        if currentUser?.id == user.id {
            currentUser = user
        }
    }
    
    /// 사용자의 마지막 동기화 시간을 업데이트합니다
    func updateLastSyncTime(userId: String) async throws {
        guard let user = try localDataSource.fetchUser(byId: userId) else {
            throw BrainyError.authenticationFailed("사용자를 찾을 수 없습니다")
        }
        
        user.lastSyncAt = Date()
        try localDataSource.update()
        
        if currentUser?.id == userId {
            currentUser = user
        }
    }
    
    /// 사용자를 삭제합니다 (계정 탈퇴)
    func deleteUser(userId: String) async throws {
        guard let user = try localDataSource.fetchUser(byId: userId) else {
            throw BrainyError.authenticationFailed("사용자를 찾을 수 없습니다")
        }
        
        try localDataSource.deleteUser(user)
        
        if currentUser?.id == userId {
            currentUser = nil
        }
    }
    
    /// 앱 시작 시 저장된 사용자 정보를 복원합니다
    func restoreUserSession() async throws -> User? {
        // TODO: 실제 구현에서는 토큰 검증 등이 필요
        // 현재는 마지막 로그인한 사용자를 반환
        let allUsers = try localDataSource.fetchAllUsers()
        let lastUser = allUsers.max { $0.createdAt < $1.createdAt }
        
        currentUser = lastUser
        return lastUser
    }
    
    /// 사용자 인증 상태를 확인합니다
    func isUserAuthenticated() async -> Bool {
        return currentUser != nil
    }
}

// MARK: - Helper Methods
extension AuthenticationRepositoryImpl {
    
    /// 이메일에서 표시 이름을 추출합니다
    private func extractDisplayName(from email: String) -> String {
        let components = email.components(separatedBy: "@")
        return components.first?.capitalized ?? "사용자"
    }
    
    /// 사용자 ID의 유효성을 검사합니다
    private func validateUserId(_ userId: String) -> Bool {
        return !userId.isEmpty && userId.count >= 3
    }
    
    /// 이메일 형식의 유효성을 검사합니다
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
