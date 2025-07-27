import Foundation

/// 로그인 시도 제한 관리자
actor LoginAttemptManager {
    // MARK: - Properties
    private let configManager = StaticConfigManager.shared
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private let attemptCountKey = "login_attempt_count_"
    private let lockTimeKey = "account_lock_time_"
    private let lastAttemptKey = "last_login_attempt_"
    
    // MARK: - Singleton
    static let shared = LoginAttemptManager()
    
    private init() {}
    
    // MARK: - Login Attempt Management
    
    /// 로그인 시도 기록
    func recordLoginAttempt(for identifier: String, success: Bool) async {
        let key = attemptCountKey + identifier
        let lockKey = lockTimeKey + identifier
        let lastAttemptKey = self.lastAttemptKey + identifier
        
        // 마지막 시도 시간 기록
        userDefaults.set(Date(), forKey: lastAttemptKey)
        
        if success {
            // 성공 시 시도 횟수 초기화
            userDefaults.removeObject(forKey: key)
            userDefaults.removeObject(forKey: lockKey)
        } else {
            // 실패 시 시도 횟수 증가
            let currentCount = userDefaults.integer(forKey: key)
            let newCount = currentCount + 1
            userDefaults.set(newCount, forKey: key)
            
            // 최대 시도 횟수 확인
            let maxAttempts = await getMaxLoginAttempts()
            if newCount >= maxAttempts {
                await lockAccount(identifier)
            }
        }
    }
    
    /// 계정 잠금 상태 확인
    func isAccountLocked(_ identifier: String) async -> Bool {
        let lockKey = lockTimeKey + identifier
        
        guard let lockTime = userDefaults.object(forKey: lockKey) as? Date else {
            return false
        }
        
        let lockDuration = await getLockDuration()
        let unlockTime = lockTime.addingTimeInterval(lockDuration)
        
        if Date() > unlockTime {
            // 잠금 해제 시간이 지났으면 잠금 해제
            await unlockAccount(identifier)
            return false
        }
        
        return true
    }
    
    /// 계정 잠금까지 남은 시도 횟수
    func getRemainingAttempts(for identifier: String) async -> Int {
        let key = attemptCountKey + identifier
        let currentCount = userDefaults.integer(forKey: key)
        let maxAttempts = await getMaxLoginAttempts()
        
        return max(0, maxAttempts - currentCount)
    }
    
    /// 계정 잠금 해제까지 남은 시간
    func getTimeUntilUnlock(for identifier: String) async -> TimeInterval? {
        let lockKey = lockTimeKey + identifier
        
        guard let lockTime = userDefaults.object(forKey: lockKey) as? Date else {
            return nil
        }
        
        let lockDuration = await getLockDuration()
        let unlockTime = lockTime.addingTimeInterval(lockDuration)
        let remainingTime = unlockTime.timeIntervalSinceNow
        
        return remainingTime > 0 ? remainingTime : nil
    }
    
    /// 로그인 시도 통계
    func getLoginAttemptStats(for identifier: String) async -> LoginAttemptStats {
        let attemptKey = attemptCountKey + identifier
        let lastAttemptKey = self.lastAttemptKey + identifier
        let lockKey = lockTimeKey + identifier
        
        let attemptCount = userDefaults.integer(forKey: attemptKey)
        let lastAttempt = userDefaults.object(forKey: lastAttemptKey) as? Date
        let lockTime = userDefaults.object(forKey: lockKey) as? Date
        let isLocked = await isAccountLocked(identifier)
        let remainingAttempts = await getRemainingAttempts(for: identifier)
        let timeUntilUnlock = await getTimeUntilUnlock(for: identifier)
        
        return LoginAttemptStats(
            attemptCount: attemptCount,
            remainingAttempts: remainingAttempts,
            lastAttempt: lastAttempt,
            isLocked: isLocked,
            lockTime: lockTime,
            timeUntilUnlock: timeUntilUnlock
        )
    }
    
    // MARK: - Private Methods
    
    /// 계정 잠금
    private func lockAccount(_ identifier: String) async {
        let lockKey = lockTimeKey + identifier
        userDefaults.set(Date(), forKey: lockKey)
        
        // 보안 이벤트 로깅
        await logSecurityEvent(.accountLocked, for: identifier)
        
        // 잠금 알림 발송
        await MainActor.run {
            NotificationCenter.default.post(
                name: .accountLocked,
                object: nil,
                userInfo: ["identifier": identifier]
            )
        }
    }
    
    /// 계정 잠금 해제
    private func unlockAccount(_ identifier: String) async {
        let attemptKey = attemptCountKey + identifier
        let lockKey = lockTimeKey + identifier
        
        userDefaults.removeObject(forKey: attemptKey)
        userDefaults.removeObject(forKey: lockKey)
        
        // 보안 이벤트 로깅
        await logSecurityEvent(.accountUnlocked, for: identifier)
    }
    
    /// 최대 로그인 시도 횟수 가져오기
    private func getMaxLoginAttempts() async -> Int {
        do {
            let config = try await configManager.loadStaticConfig()
            return config.authConfig.maxLoginAttempts
        } catch {
            return 5 // 기본값
        }
    }
    
    /// 계정 잠금 지속 시간 가져오기
    private func getLockDuration() async -> TimeInterval {
        // 기본 30분 잠금
        return 30 * 60
    }
    
    /// 보안 이벤트 로깅
    private func logSecurityEvent(_ event: SecurityEventType, for identifier: String) async {
        await SecurityEventLogger.shared.logEvent(
            type: event,
            identifier: identifier,
            details: [
                "timestamp": Date(),
                "device_id": await getDeviceId()
            ]
        )
    }
    
    /// 디바이스 ID 가져오기
    private func getDeviceId() async -> String {
        return await SessionManager.shared.getCurrentSession()?.deviceId ?? "unknown"
    }
}

// MARK: - Login Attempt Stats

struct LoginAttemptStats {
    let attemptCount: Int
    let remainingAttempts: Int
    let lastAttempt: Date?
    let isLocked: Bool
    let lockTime: Date?
    let timeUntilUnlock: TimeInterval?
    
    var lockTimeString: String? {
        guard let lockTime = lockTime else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: lockTime)
    }
    
    var timeUntilUnlockString: String? {
        guard let timeUntilUnlock = timeUntilUnlock else { return nil }
        
        let minutes = Int(timeUntilUnlock / 60)
        let seconds = Int(timeUntilUnlock.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        } else {
            return "\(seconds)초"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let accountLocked = Notification.Name("accountLocked")
    static let accountUnlocked = Notification.Name("accountUnlocked")
}