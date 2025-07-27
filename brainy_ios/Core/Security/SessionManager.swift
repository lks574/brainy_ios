import Foundation
import Security

/// 세션 관리자
actor SessionManager {
    // MARK: - Properties
    private let configManager = StaticConfigManager.shared
    private let keychain = KeychainManager.shared
    
    // Session keys
    private let sessionTokenKey = "session_token"
    private let sessionExpiryKey = "session_expiry"
    private let deviceIdKey = "device_id"
    private let lastActivityKey = "last_activity"
    
    // Session timeout timer
    private var sessionTimer: Timer?
    private var currentSessionInfo: SessionInfo?
    
    // MARK: - Singleton
    static let shared = SessionManager()
    
    private init() {}
    
    // MARK: - Session Management
    
    /// 새로운 세션 시작
    func startSession(token: String, expiresAt: Date, userId: String) async throws {
        let deviceId = await getOrCreateDeviceId()
        
        let sessionInfo = SessionInfo(
            sessionId: UUID().uuidString,
            token: token,
            userId: userId,
            deviceId: deviceId,
            expiresAt: expiresAt,
            lastActivity: Date()
        )
        
        // Keychain에 세션 정보 저장
        try keychain.save(token, for: sessionTokenKey)
        try keychain.save(expiresAt.timeIntervalSince1970, for: sessionExpiryKey)
        try keychain.save(deviceId, for: deviceIdKey)
        
        currentSessionInfo = sessionInfo
        
        // 세션 타임아웃 타이머 설정
        await setupSessionTimer()
        
        // 활동 시간 업데이트
        await updateLastActivity()
    }
    
    /// 현재 세션 정보 반환
    func getCurrentSession() async -> SessionInfo? {
        if let session = currentSessionInfo {
            return session
        }
        
        // Keychain에서 세션 복원 시도
        return await restoreSessionFromKeychain()
    }
    
    /// 세션 유효성 확인
    func isSessionValid() async -> Bool {
        guard let session = await getCurrentSession() else { return false }
        
        // 만료 시간 확인
        if Date() > session.expiresAt {
            await invalidateSession()
            return false
        }
        
        // 정적 설정에서 세션 타임아웃 확인
        do {
            let config = try await configManager.loadStaticConfig()
            let timeoutInterval = TimeInterval(config.authConfig.sessionTimeoutMinutes * 60)
            
            if Date().timeIntervalSince(session.lastActivity) > timeoutInterval {
                await invalidateSession()
                return false
            }
        } catch {
            // 설정 로드 실패 시 기본 타임아웃 사용 (60분)
            if Date().timeIntervalSince(session.lastActivity) > 3600 {
                await invalidateSession()
                return false
            }
        }
        
        return true
    }
    
    /// 세션 갱신
    func refreshSession() async throws {
        guard let currentSession = currentSessionInfo else {
            throw SessionError.noActiveSession
        }
        
        // 새로운 만료 시간 설정 (현재 시간 + 설정된 타임아웃)
        let config = try await configManager.loadStaticConfig()
        let timeoutInterval = TimeInterval(config.authConfig.sessionTimeoutMinutes * 60)
        let newExpiryTime = Date().addingTimeInterval(timeoutInterval)
        
        // 세션 정보 업데이트
        let updatedSession = SessionInfo(
            sessionId: currentSession.sessionId,
            token: currentSession.token,
            userId: currentSession.userId,
            deviceId: currentSession.deviceId,
            expiresAt: newExpiryTime,
            lastActivity: Date()
        )
        
        // Keychain 업데이트
        try keychain.save(newExpiryTime.timeIntervalSince1970, for: sessionExpiryKey)
        
        currentSessionInfo = updatedSession
        
        // 타이머 재설정
        await setupSessionTimer()
    }
    
    /// 마지막 활동 시간 업데이트
    func updateLastActivity() async {
        guard var session = currentSessionInfo else { return }
        
        session.lastActivity = Date()
        currentSessionInfo = session
        
        UserDefaults.standard.set(Date(), forKey: lastActivityKey)
    }
    
    /// 세션 무효화
    func invalidateSession() async {
        currentSessionInfo = nil
        
        // Keychain에서 세션 정보 삭제
        keychain.delete(sessionTokenKey)
        keychain.delete(sessionExpiryKey)
        
        // 타이머 정리
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        // UserDefaults 정리
        UserDefaults.standard.removeObject(forKey: lastActivityKey)
        
        // 세션 만료 알림 발송
        await MainActor.run {
            NotificationCenter.default.post(name: .sessionExpired, object: nil)
        }
    }
    
    // MARK: - Private Methods
    
    /// Keychain에서 세션 복원
    private func restoreSessionFromKeychain() async -> SessionInfo? {
        guard let token: String = keychain.load(sessionTokenKey),
              let expiryInterval: Double = keychain.load(sessionExpiryKey),
              let deviceId: String = keychain.load(deviceIdKey) else {
            return nil
        }
        
        let expiryDate = Date(timeIntervalSince1970: expiryInterval)
        let lastActivity = UserDefaults.standard.object(forKey: lastActivityKey) as? Date ?? Date()
        
        let sessionInfo = SessionInfo(
            sessionId: UUID().uuidString, // 새로운 세션 ID 생성
            token: token,
            userId: "", // 실제 구현에서는 토큰에서 추출
            deviceId: deviceId,
            expiresAt: expiryDate,
            lastActivity: lastActivity
        )
        
        currentSessionInfo = sessionInfo
        await setupSessionTimer()
        
        return sessionInfo
    }
    
    /// 디바이스 ID 생성 또는 반환
    private func getOrCreateDeviceId() async -> String {
        if let existingId: String = keychain.load(deviceIdKey) {
            return existingId
        }
        
        let newDeviceId = UUID().uuidString
        try? keychain.save(newDeviceId, for: deviceIdKey)
        return newDeviceId
    }
    
    /// 세션 타임아웃 타이머 설정
    private func setupSessionTimer() async {
        sessionTimer?.invalidate()
        
        guard let session = currentSessionInfo else { return }
        
        let timeUntilExpiry = session.expiresAt.timeIntervalSinceNow
        
        if timeUntilExpiry > 0 {
            await MainActor.run {
                sessionTimer = Timer.scheduledTimer(withTimeInterval: timeUntilExpiry, repeats: false) { _ in
                    Task {
                        await self.invalidateSession()
                    }
                }
            }
        }
    }
}

// MARK: - Session Info

struct SessionInfo {
    let sessionId: String
    let token: String
    let userId: String
    let deviceId: String
    let expiresAt: Date
    var lastActivity: Date
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    var timeUntilExpiry: TimeInterval {
        return expiresAt.timeIntervalSinceNow
    }
    
    var timeSinceLastActivity: TimeInterval {
        return Date().timeIntervalSince(lastActivity)
    }
}

// MARK: - Session Error

enum SessionError: LocalizedError {
    case noActiveSession
    case sessionExpired
    case invalidToken
    case keychainError
    
    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "활성 세션이 없습니다."
        case .sessionExpired:
            return "세션이 만료되었습니다."
        case .invalidToken:
            return "유효하지 않은 토큰입니다."
        case .keychainError:
            return "키체인 오류가 발생했습니다."
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let sessionExpired = Notification.Name("sessionExpired")
    static let sessionRefreshed = Notification.Name("sessionRefreshed")
}