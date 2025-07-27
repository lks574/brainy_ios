import Foundation
import SwiftUI

/// 사용자 친화적 에러 메시지 관리자
@MainActor
class ErrorMessageManager: ObservableObject {
    // MARK: - Properties
    @Published var currentError: UserFriendlyError?
    @Published var showingError = false
    
    // MARK: - Singleton
    static let shared = ErrorMessageManager()
    
    private init() {}
    
    // MARK: - Error Display
    
    /// 에러 표시
    func showError(_ error: Error, context: ErrorContext = .general) {
        let userFriendlyError = convertToUserFriendlyError(error, context: context)
        currentError = userFriendlyError
        showingError = true
        
        // 에러 로깅
        Task {
            await SecurityEventLogger.shared.logEvent(
                type: .suspiciousActivity,
                details: [
                    "event": "error_displayed",
                    "error_type": String(describing: type(of: error)),
                    "error_message": error.localizedDescription,
                    "context": context.rawValue,
                    "user_friendly_message": userFriendlyError.message
                ]
            )
        }
    }
    
    /// 에러 숨기기
    func hideError() {
        currentError = nil
        showingError = false
    }
    
    /// 특정 타입의 에러 표시
    func showNetworkError(_ error: NetworkError) {
        showError(error, context: .network)
    }
    
    func showAuthError(_ error: Error) {
        showError(error, context: .authentication)
    }
    
    func showSyncError(_ error: Error) {
        showError(error, context: .sync)
    }
    
    func showDataError(_ error: Error) {
        showError(error, context: .data)
    }
    
    // MARK: - Error Conversion
    
    /// 에러를 사용자 친화적 메시지로 변환
    private func convertToUserFriendlyError(_ error: Error, context: ErrorContext) -> UserFriendlyError {
        // 네트워크 에러 처리
        if let networkError = error as? NetworkError {
            return handleNetworkError(networkError, context: context)
        }
        
        // 인증 에러 처리
        if let authError = error as? SessionError {
            return handleAuthError(authError, context: context)
        }
        
        // 동기화 에러 처리
        if let syncError = error as? SyncError {
            return handleSyncError(syncError, context: context)
        }
        
        // 키체인 에러 처리
        if let keychainError = error as? KeychainError {
            return handleKeychainError(keychainError, context: context)
        }
        
        // 정적 설정 에러 처리
        if let configError = error as? StaticConfigError {
            return handleConfigError(configError, context: context)
        }
        
        // URL 에러 처리
        if let urlError = error as? URLError {
            return handleURLError(urlError, context: context)
        }
        
        // 기본 에러 처리
        return UserFriendlyError(
            title: getContextTitle(context),
            message: error.localizedDescription,
            actionTitle: "확인",
            action: nil,
            severity: .medium
        )
    }
    
    // MARK: - Specific Error Handlers
    
    private func handleNetworkError(_ error: NetworkError, context: ErrorContext) -> UserFriendlyError {
        switch error {
        case .noConnection:
            return UserFriendlyError(
                title: "인터넷 연결 없음",
                message: "인터넷 연결을 확인하고 다시 시도해주세요.",
                actionTitle: "설정으로 이동",
                action: { self.openNetworkSettings() },
                severity: .high
            )
            
        case .timeout:
            return UserFriendlyError(
                title: "연결 시간 초과",
                message: "네트워크가 불안정합니다. 잠시 후 다시 시도해주세요.",
                actionTitle: "다시 시도",
                action: nil,
                severity: .medium
            )
            
        case .unauthorized:
            return UserFriendlyError(
                title: "인증 필요",
                message: "다시 로그인해주세요.",
                actionTitle: "로그인",
                action: { self.navigateToLogin() },
                severity: .high
            )
            
        case .serverError(let code):
            return UserFriendlyError(
                title: "서버 오류",
                message: "서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.",
                actionTitle: "다시 시도",
                action: nil,
                severity: .medium
            )
            
        case .retryExhausted(let originalError, let attempts):
            return UserFriendlyError(
                title: "연결 실패",
                message: "\(attempts)번 시도했지만 연결할 수 없습니다. 네트워크 상태를 확인해주세요.",
                actionTitle: "확인",
                action: nil,
                severity: .high
            )
            
        default:
            return UserFriendlyError(
                title: "네트워크 오류",
                message: error.localizedDescription,
                actionTitle: "확인",
                action: nil,
                severity: .medium
            )
        }
    }
    
    private func handleAuthError(_ error: SessionError, context: ErrorContext) -> UserFriendlyError {
        switch error {
        case .sessionExpired:
            return UserFriendlyError(
                title: "세션 만료",
                message: "보안을 위해 세션이 만료되었습니다. 다시 로그인해주세요.",
                actionTitle: "로그인",
                action: { self.navigateToLogin() },
                severity: .high
            )
            
        case .noActiveSession:
            return UserFriendlyError(
                title: "로그인 필요",
                message: "이 기능을 사용하려면 로그인이 필요합니다.",
                actionTitle: "로그인",
                action: { self.navigateToLogin() },
                severity: .medium
            )
            
        case .invalidToken:
            return UserFriendlyError(
                title: "인증 오류",
                message: "인증 정보가 유효하지 않습니다. 다시 로그인해주세요.",
                actionTitle: "로그인",
                action: { self.navigateToLogin() },
                severity: .high
            )
            
        case .keychainError:
            return UserFriendlyError(
                title: "보안 오류",
                message: "보안 저장소에 문제가 발생했습니다. 앱을 재시작해주세요.",
                actionTitle: "확인",
                action: nil,
                severity: .high
            )
        }
    }
    
    private func handleSyncError(_ error: SyncError, context: ErrorContext) -> UserFriendlyError {
        switch error {
        case .syncInProgress:
            return UserFriendlyError(
                title: "동기화 진행 중",
                message: "이미 동기화가 진행 중입니다. 잠시 후 다시 시도해주세요.",
                actionTitle: "확인",
                action: nil,
                severity: .low
            )
            
        case .networkUnavailable:
            return UserFriendlyError(
                title: "네트워크 연결 필요",
                message: "동기화하려면 인터넷 연결이 필요합니다.",
                actionTitle: "확인",
                action: nil,
                severity: .medium
            )
            
        case .uploadFailed(let message):
            return UserFriendlyError(
                title: "업로드 실패",
                message: "데이터 업로드에 실패했습니다. 나중에 다시 시도해주세요.",
                actionTitle: "확인",
                action: nil,
                severity: .medium
            )
            
        case .downloadFailed(let message):
            return UserFriendlyError(
                title: "다운로드 실패",
                message: "데이터 다운로드에 실패했습니다. 네트워크 상태를 확인해주세요.",
                actionTitle: "확인",
                action: nil,
                severity: .medium
            )
            
        case .dataCorrupted:
            return UserFriendlyError(
                title: "데이터 오류",
                message: "데이터가 손상되었습니다. 앱을 재시작해주세요.",
                actionTitle: "확인",
                action: nil,
                severity: .high
            )
        }
    }
    
    private func handleKeychainError(_ error: KeychainError, context: ErrorContext) -> UserFriendlyError {
        return UserFriendlyError(
            title: "보안 저장소 오류",
            message: "보안 정보 저장에 문제가 발생했습니다. 앱을 재시작해주세요.",
            actionTitle: "확인",
            action: nil,
            severity: .high
        )
    }
    
    private func handleConfigError(_ error: StaticConfigError, context: ErrorContext) -> UserFriendlyError {
        switch error {
        case .downloadFailed:
            return UserFriendlyError(
                title: "설정 로드 실패",
                message: "앱 설정을 불러올 수 없습니다. 네트워크 상태를 확인해주세요.",
                actionTitle: "다시 시도",
                action: nil,
                severity: .medium
            )
            
        case .invalidConfig:
            return UserFriendlyError(
                title: "설정 오류",
                message: "앱 설정에 문제가 있습니다. 앱을 업데이트해주세요.",
                actionTitle: "확인",
                action: nil,
                severity: .high
            )
            
        default:
            return UserFriendlyError(
                title: "설정 오류",
                message: error.localizedDescription,
                actionTitle: "확인",
                action: nil,
                severity: .medium
            )
        }
    }
    
    private func handleURLError(_ error: URLError, context: ErrorContext) -> UserFriendlyError {
        switch error.code {
        case .notConnectedToInternet:
            return UserFriendlyError(
                title: "인터넷 연결 없음",
                message: "인터넷에 연결되지 않았습니다. 연결 상태를 확인해주세요.",
                actionTitle: "설정으로 이동",
                action: { self.openNetworkSettings() },
                severity: .high
            )
            
        case .timedOut:
            return UserFriendlyError(
                title: "연결 시간 초과",
                message: "서버 응답이 너무 느립니다. 잠시 후 다시 시도해주세요.",
                actionTitle: "다시 시도",
                action: nil,
                severity: .medium
            )
            
        default:
            return UserFriendlyError(
                title: "네트워크 오류",
                message: "네트워크 연결에 문제가 발생했습니다.",
                actionTitle: "확인",
                action: nil,
                severity: .medium
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getContextTitle(_ context: ErrorContext) -> String {
        switch context {
        case .general:
            return "오류"
        case .network:
            return "네트워크 오류"
        case .authentication:
            return "인증 오류"
        case .sync:
            return "동기화 오류"
        case .data:
            return "데이터 오류"
        }
    }
    
    private func openNetworkSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func navigateToLogin() {
        NotificationCenter.default.post(name: .navigateToLogin, object: nil)
    }
}

// MARK: - User Friendly Error

struct UserFriendlyError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let actionTitle: String
    let action: (() -> Void)?
    let severity: ErrorSeverity
    
    var iconName: String {
        switch severity {
        case .low:
            return "info.circle"
        case .medium:
            return "exclamationmark.triangle"
        case .high:
            return "xmark.circle"
        }
    }
    
    var iconColor: Color {
        switch severity {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

// MARK: - Error Context

enum ErrorContext: String, CaseIterable {
    case general = "general"
    case network = "network"
    case authentication = "authentication"
    case sync = "sync"
    case data = "data"
}

// MARK: - Error Severity

enum ErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToLogin = Notification.Name("navigateToLogin")
}