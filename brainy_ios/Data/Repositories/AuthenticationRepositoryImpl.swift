import Foundation
import SwiftData
@preconcurrency import FirebaseAuth
@preconcurrency import GoogleSignIn
import AuthenticationServices

/// AuthenticationRepository의 구현체
@MainActor
class AuthenticationRepositoryImpl: AuthenticationRepositoryProtocol {
    private let localDataSource: LocalDataSource
    private var currentUser: User?
    
    init(localDataSource: LocalDataSource) {
        self.localDataSource = localDataSource
    }
    
    func signInWithEmail(email: String, password: String) async throws -> User {
        // 개발 모드: 테스트 계정 처리
        if email == "test@test.com" && password == "123456" {
            let user = try await getOrCreateUser(
                id: "test-user-id",
                email: email,
                displayName: "테스트 사용자",
                authProvider: .email
            )
            
            currentUser = user
            return user
        }
        
        do {
            // Firebase Auth로 이메일 로그인
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let firebaseUser = authResult.user
            
            // 로컬 사용자 확인 또는 생성
            let user = try await getOrCreateUser(
                id: firebaseUser.uid,
                email: firebaseUser.email,
                displayName: firebaseUser.displayName ?? extractDisplayName(from: email),
                authProvider: .email
            )
            
            currentUser = user
            return user
            
        } catch let error as NSError {
            // Firebase Auth 에러 처리
            throw mapFirebaseError(error)
        }
    }
    
    func signInWithGoogle() async throws -> User {
        guard let presentingViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else {
            throw BrainyError.authenticationFailed("Google 로그인을 위한 화면을 찾을 수 없습니다.")
        }
        
        do {
            // Google Sign-In 실행
            let result = try await GoogleSignIn.GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let googleUser = result.user
            
            // Firebase Auth에 Google 자격 증명으로 로그인
            guard let idToken = googleUser.idToken?.tokenString else {
                throw BrainyError.authenticationFailed("Google ID 토큰을 가져올 수 없습니다.")
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: googleUser.accessToken.tokenString)
            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user
            
            // 로컬 사용자 확인 또는 생성
            let user = try await getOrCreateUser(
                id: firebaseUser.uid,
                email: firebaseUser.email,
                displayName: firebaseUser.displayName ?? googleUser.profile?.name ?? "Google User",
                authProvider: .google
            )
            
            currentUser = user
            return user
            
        } catch {
            throw BrainyError.authenticationFailed("Google 로그인 중 오류가 발생했습니다: \(error.localizedDescription)")
        }
    }
    
    func signInWithApple() async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate { result in
                continuation.resume(with: result)
            }
            
            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = delegate
            authorizationController.performRequests()
        }
    }
    
    func signOut() async throws {
        do {
            // Firebase Auth 로그아웃
            try Auth.auth().signOut()
            
            // Google Sign-In 로그아웃
            GoogleSignIn.GIDSignIn.sharedInstance.signOut()
            
            // 현재 사용자 정보 초기화
            currentUser = nil
            
        } catch {
            throw BrainyError.authenticationFailed("로그아웃 중 오류가 발생했습니다: \(error.localizedDescription)")
        }
    }
    
    func getCurrentUser() async -> User? {
        // 메모리에 현재 사용자가 있다면 반환 (테스트 사용자 포함)
        if let currentUser = currentUser {
            return currentUser
        }
        
        // Firebase Auth의 현재 사용자 확인
        if let firebaseUser = Auth.auth().currentUser {
            // 로컬 DB에서 사용자 찾기
            currentUser = try? localDataSource.fetchUser(byId: firebaseUser.uid)
            return currentUser
        }
        
        return nil
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
    
    /// 사용자를 가져오거나 생성합니다
    private func getOrCreateUser(
        id: String,
        email: String?,
        displayName: String,
        authProvider: AuthProvider
    ) async throws -> User {
        // 기존 사용자 확인
        if let existingUser = try localDataSource.fetchUser(byId: id) {
            return existingUser
        }
        
        // 새 사용자 생성
        let newUser = User(
            id: id,
            email: email,
            displayName: displayName,
            authProvider: authProvider
        )
        
        try localDataSource.saveUser(newUser)
        return newUser
    }
    
    /// Firebase 에러를 BrainyError로 매핑합니다
    private func mapFirebaseError(_ error: NSError) -> BrainyError {
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return BrainyError.authenticationFailed("알 수 없는 인증 오류가 발생했습니다.")
        }
        
        switch errorCode {
        case .invalidEmail:
            return BrainyError.validationError("올바르지 않은 이메일 형식입니다.")
        case .wrongPassword:
            return BrainyError.authenticationFailed("비밀번호가 올바르지 않습니다.")
        case .userNotFound:
            return BrainyError.authenticationFailed("등록되지 않은 사용자입니다.")
        case .userDisabled:
            return BrainyError.authenticationFailed("비활성화된 계정입니다.")
        case .tooManyRequests:
            return BrainyError.authenticationFailed("너무 많은 로그인 시도입니다. 잠시 후 다시 시도해주세요.")
        case .networkError:
            return BrainyError.networkError(errorCode.rawValue)
        default:
            return BrainyError.authenticationFailed("로그인 중 오류가 발생했습니다: \(error.localizedDescription)")
        }
    }
    
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

// MARK: - Apple Sign-In Delegate
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<User, Error>) -> Void
    
    init(completion: @escaping (Result<User, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            do {
                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    // Apple ID 자격 증명 처리
                    _ = appleIDCredential.user
                    let email = appleIDCredential.email
                    let fullName = appleIDCredential.fullName
                    
                    let displayName = [fullName?.givenName, fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                        .isEmpty ? "Apple User" : [fullName?.givenName, fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    
                    // Firebase Auth에 Apple 자격 증명으로 로그인
                    guard let identityToken = appleIDCredential.identityToken,
                          let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                        throw BrainyError.authenticationFailed("Apple ID 토큰을 가져올 수 없습니다.")
                    }

                    let credential = OAuthProvider.credential(providerID: .apple, accessToken: identityTokenString)

                    let authResult = try await Auth.auth().signIn(with: credential)
                    let firebaseUser = authResult.user
                    
                    // 로컬 사용자 확인 또는 생성
                    let localDataSource = LocalDataSource(modelContext: ModelContainer.shared.mainContext)
                    let user = try await self.getOrCreateUser(
                        localDataSource: localDataSource,
                        id: firebaseUser.uid,
                        email: email ?? firebaseUser.email,
                        displayName: firebaseUser.displayName ?? displayName,
                        authProvider: .apple
                    )
                    
                    completion(.success(user))
                }
            } catch {
                completion(.failure(BrainyError.authenticationFailed("Apple 로그인 중 오류가 발생했습니다: \(error.localizedDescription)")))
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(BrainyError.authenticationFailed("Apple 로그인이 취소되었거나 오류가 발생했습니다: \(error.localizedDescription)")))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first ?? UIWindow()
    }
    
    private func getOrCreateUser(
        localDataSource: LocalDataSource,
        id: String,
        email: String?,
        displayName: String,
        authProvider: AuthProvider
    ) async throws -> User {
        // 기존 사용자 확인
        if let existingUser = try localDataSource.fetchUser(byId: id) {
            return existingUser
        }
        
        // 새 사용자 생성
        let newUser = User(
            id: id,
            email: email,
            displayName: displayName,
            authProvider: authProvider
        )
        
        try localDataSource.saveUser(newUser)
        return newUser
    }
}
