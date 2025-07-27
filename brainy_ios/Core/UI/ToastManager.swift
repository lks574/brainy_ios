import Foundation
import SwiftUI

/// 토스트 메시지 관리자
@MainActor
class ToastManager: ObservableObject {
    // MARK: - Properties
    @Published var currentToast: ToastMessage?
    @Published var toastQueue: [ToastMessage] = []
    
    private var toastTimer: Timer?
    
    // MARK: - Singleton
    static let shared = ToastManager()
    
    private init() {}
    
    // MARK: - Toast Display
    
    /// 토스트 메시지 표시
    func showToast(
        message: String,
        type: ToastType = .info,
        duration: TimeInterval = 3.0,
        action: ToastAction? = nil
    ) {
        let toast = ToastMessage(
            id: UUID(),
            message: message,
            type: type,
            duration: duration,
            action: action,
            timestamp: Date()
        )
        
        if currentToast == nil {
            displayToast(toast)
        } else {
            toastQueue.append(toast)
        }
    }
    
    /// 성공 토스트
    func showSuccess(_ message: String, duration: TimeInterval = 2.0) {
        showToast(message: message, type: .success, duration: duration)
    }
    
    /// 에러 토스트
    func showError(_ message: String, duration: TimeInterval = 4.0, action: ToastAction? = nil) {
        showToast(message: message, type: .error, duration: duration, action: action)
    }
    
    /// 경고 토스트
    func showWarning(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .warning, duration: duration)
    }
    
    /// 정보 토스트
    func showInfo(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .info, duration: duration)
    }
    
    /// 로딩 토스트 (무한 지속)
    func showLoading(_ message: String = "처리 중...") {
        showToast(message: message, type: .loading, duration: .infinity)
    }
    
    /// 현재 토스트 숨기기
    func hideCurrentToast() {
        toastTimer?.invalidate()
        toastTimer = nil
        currentToast = nil
        
        // 대기 중인 토스트가 있으면 다음 토스트 표시
        if !toastQueue.isEmpty {
            let nextToast = toastQueue.removeFirst()
            displayToast(nextToast)
        }
    }
    
    /// 모든 토스트 제거
    func clearAllToasts() {
        toastTimer?.invalidate()
        toastTimer = nil
        currentToast = nil
        toastQueue.removeAll()
    }
    
    // MARK: - Convenience Methods
    
    /// 네트워크 관련 토스트
    func showNetworkError() {
        showError("인터넷 연결을 확인해주세요", action: ToastAction(
            title: "설정",
            action: { self.openNetworkSettings() }
        ))
    }
    
    func showNetworkRestored() {
        showSuccess("인터넷 연결이 복원되었습니다")
    }
    
    /// 동기화 관련 토스트
    func showSyncSuccess() {
        showSuccess("동기화가 완료되었습니다")
    }
    
    func showSyncError() {
        showError("동기화에 실패했습니다", action: ToastAction(
            title: "다시 시도",
            action: { self.retrySyncAction() }
        ))
    }
    
    /// 인증 관련 토스트
    func showLoginSuccess() {
        showSuccess("로그인되었습니다")
    }
    
    func showLogoutSuccess() {
        showInfo("로그아웃되었습니다")
    }
    
    func showSessionExpired() {
        showWarning("세션이 만료되었습니다. 다시 로그인해주세요")
    }
    
    /// 퀴즈 관련 토스트
    func showQuizCompleted(score: Int, total: Int) {
        let accuracy = Double(score) / Double(total) * 100
        showSuccess("퀴즈 완료! 정답률: \(Int(accuracy))%")
    }
    
    func showQuizSaved() {
        showInfo("퀴즈 결과가 저장되었습니다")
    }
    
    // MARK: - Private Methods
    
    /// 토스트 표시
    private func displayToast(_ toast: ToastMessage) {
        currentToast = toast
        
        // 무한 지속이 아닌 경우 타이머 설정
        if toast.duration != .infinity {
            toastTimer = Timer.scheduledTimer(withTimeInterval: toast.duration, repeats: false) { _ in
                Task { @MainActor in
                    self.hideCurrentToast()
                }
            }
        }
    }
    
    /// 네트워크 설정 열기
    private func openNetworkSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /// 동기화 재시도
    private func retrySyncAction() {
        NotificationCenter.default.post(name: .retrySyncRequested, object: nil)
    }
}

// MARK: - Toast Message

struct ToastMessage: Identifiable, Equatable {
    let id: UUID
    let message: String
    let type: ToastType
    let duration: TimeInterval
    let action: ToastAction?
    let timestamp: Date
    
    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Toast Type

enum ToastType {
    case success
    case error
    case warning
    case info
    case loading
    
    var iconName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        case .loading:
            return "arrow.triangle.2.circlepath"
        }
    }
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .warning:
            return .orange
        case .info:
            return .blue
        case .loading:
            return .brainyPrimary
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success:
            return .green.opacity(0.1)
        case .error:
            return .red.opacity(0.1)
        case .warning:
            return .orange.opacity(0.1)
        case .info:
            return .blue.opacity(0.1)
        case .loading:
            return .brainyPrimary.opacity(0.1)
        }
    }
}

// MARK: - Toast Action

struct ToastAction {
    let title: String
    let action: () -> Void
}

// MARK: - Toast View

struct ToastView: View {
    let toast: ToastMessage
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 아이콘
            if toast.type == .loading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(toast.type.color)
            } else {
                Image(systemName: toast.type.iconName)
                    .foregroundColor(toast.type.color)
                    .font(.title3)
            }
            
            // 메시지
            Text(toast.message)
                .font(.brainyBody)
                .foregroundColor(.brainyText)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // 액션 버튼
            if let action = toast.action {
                Button(action.title) {
                    action.action()
                    onDismiss()
                }
                .font(.brainyCaption)
                .foregroundColor(toast.type.color)
                .fontWeight(.medium)
            }
            
            // 닫기 버튼
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.brainyTextSecondary)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(toast.type.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .scaleEffect(isAnimating ? 1.0 : 0.9)
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

// MARK: - Toast Container

struct ToastContainer: View {
    @StateObject private var toastManager = ToastManager.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            if let toast = toastManager.currentToast {
                ToastView(toast: toast) {
                    toastManager.hideCurrentToast()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: toastManager.currentToast)
    }
}

// MARK: - View Extensions

extension View {
    /// 토스트 컨테이너 추가
    func withToast() -> some View {
        self.overlay(
            ToastContainer(),
            alignment: .bottom
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let retrySyncRequested = Notification.Name("retrySyncRequested")
}