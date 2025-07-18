import Foundation
import SwiftUI
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    // MARK: - Properties
    private let authenticationUseCase: AuthenticationUseCaseProtocol
    
    // UI State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    // Form Fields
    @Published var email = ""
    @Published var password = ""
    @Published var showPassword = false
    
    // MARK: - Initialization
    init(authenticationUseCase: AuthenticationUseCaseProtocol) {
        self.authenticationUseCase = authenticationUseCase
        Task {
            await checkCurrentUser()
        }
    }
    
    // MARK: - Authentication Methods
    
    /// 이메일로 로그인
    func signInWithEmail() async {
        guard validateEmailInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authenticationUseCase.signInWithEmail(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            clearForm()
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    /// Google로 로그인
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authenticationUseCase.signInWithGoogle()
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    /// Apple로 로그인
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authenticationUseCase.signInWithApple()
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    /// 로그아웃
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authenticationUseCase.signOut()
            currentUser = nil
            isAuthenticated = false
            clearForm()
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    /// 현재 사용자 확인
    func checkCurrentUser() async {
        let user = await authenticationUseCase.getCurrentUser()
        currentUser = user
        isAuthenticated = user != nil
    }
    
    // MARK: - Validation Methods
    
    /// 이메일 입력 유효성 검사
    private func validateEmailInput() -> Bool {
        errorMessage = nil
        
        if email.isEmpty {
            errorMessage = "이메일을 입력해주세요."
            return false
        }
        
        if !isValidEmail(email) {
            errorMessage = "올바른 이메일 형식을 입력해주세요."
            return false
        }
        
        if password.isEmpty {
            errorMessage = "비밀번호를 입력해주세요."
            return false
        }
        
        if password.count < 6 {
            errorMessage = "비밀번호는 6자 이상이어야 합니다."
            return false
        }
        
        return true
    }
    
    /// 이메일 형식 검증
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Helper Methods
    
    /// 폼 필드 초기화
    private func clearForm() {
        email = ""
        password = ""
        showPassword = false
    }
    
    /// 에러 메시지 처리
    private func handleAuthError(_ error: Error) -> String {
        if let brainyError = error as? BrainyError {
            switch brainyError {
            case .authenticationFailed(let message):
                return message
            case .networkError(let message):
                return "네트워크 오류: \(message)"
            case .dataError(let message):
                return "데이터 오류: \(message)"
            case .validationError(let message):
                return "입력 오류: \(message)"
            case .unknownError(let message):
                return "알 수 없는 오류: \(message)"
            default:
              return "알 수 없는 오류"
            }
        }
        
        return "로그인 중 오류가 발생했습니다. 다시 시도해주세요."
    }
    
    /// 에러 메시지 초기화
    func clearError() {
        errorMessage = nil
    }
    
    /// 비밀번호 표시/숨김 토글
    func togglePasswordVisibility() {
        showPassword.toggle()
    }
}

// MARK: - Computed Properties
extension AuthenticationViewModel {
    
    /// 로그인 버튼 활성화 여부
    var isSignInButtonEnabled: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }
    
    /// 소셜 로그인 버튼 활성화 여부
    var isSocialSignInEnabled: Bool {
        !isLoading
    }
    
    /// 현재 사용자 표시 이름
    var userDisplayName: String {
        currentUser?.displayName ?? "사용자"
    }
    
    /// 현재 사용자 이메일
    var userEmail: String {
        currentUser?.email ?? ""
    }
}
