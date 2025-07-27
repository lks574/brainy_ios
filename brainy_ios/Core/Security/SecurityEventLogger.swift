import Foundation

/// 보안 이벤트 로거 (로컬 저장)
actor SecurityEventLogger {
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let maxEventsCount = 1000 // 최대 저장할 이벤트 수
    private let eventsKey = "security_events"
    
    // MARK: - Singleton
    static let shared = SecurityEventLogger()
    
    private init() {}
    
    // MARK: - Event Logging
    
    /// 보안 이벤트 로깅
    func logEvent(
        type: SecurityEventType,
        identifier: String? = nil,
        details: [String: Any] = [:]
    ) async {
        let event = SecurityEvent(
            id: UUID().uuidString,
            type: type,
            identifier: identifier,
            timestamp: Date(),
            details: details,
            deviceInfo: await getDeviceInfo()
        )
        
        await saveEvent(event)
        
        // 중요한 이벤트는 즉시 알림
        if type.isCritical {
            await notifySecurityEvent(event)
        }
    }
    
    /// 보안 이벤트 목록 조회
    func getEvents(
        limit: Int = 100,
        type: SecurityEventType? = nil,
        since: Date? = nil
    ) async -> [SecurityEvent] {
        let allEvents = await loadEvents()
        
        var filteredEvents = allEvents
        
        // 타입 필터링
        if let type = type {
            filteredEvents = filteredEvents.filter { $0.type == type }
        }
        
        // 날짜 필터링
        if let since = since {
            filteredEvents = filteredEvents.filter { $0.timestamp >= since }
        }
        
        // 최신순 정렬 및 제한
        return Array(filteredEvents.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }
    
    /// 특정 식별자의 이벤트 조회
    func getEvents(for identifier: String, limit: Int = 50) async -> [SecurityEvent] {
        let allEvents = await loadEvents()
        
        return Array(
            allEvents
                .filter { $0.identifier == identifier }
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(limit)
        )
    }
    
    /// 보안 이벤트 통계
    func getEventStatistics(since: Date? = nil) async -> SecurityEventStatistics {
        let events = await getEvents(limit: Int.max, since: since)
        
        var typeCounts: [SecurityEventType: Int] = [:]
        var criticalEvents = 0
        var recentEvents = 0
        
        let oneDayAgo = Date().addingTimeInterval(-86400)
        
        for event in events {
            typeCounts[event.type, default: 0] += 1
            
            if event.type.isCritical {
                criticalEvents += 1
            }
            
            if event.timestamp > oneDayAgo {
                recentEvents += 1
            }
        }
        
        return SecurityEventStatistics(
            totalEvents: events.count,
            criticalEvents: criticalEvents,
            recentEvents: recentEvents,
            typeCounts: typeCounts,
            oldestEvent: events.last?.timestamp,
            newestEvent: events.first?.timestamp
        )
    }
    
    /// 오래된 이벤트 정리
    func cleanupOldEvents() async {
        let events = await loadEvents()
        
        if events.count > maxEventsCount {
            let recentEvents = Array(
                events.sorted { $0.timestamp > $1.timestamp }.prefix(maxEventsCount)
            )
            await saveEvents(recentEvents)
        }
    }
    
    // MARK: - Private Methods
    
    /// 이벤트 저장
    private func saveEvent(_ event: SecurityEvent) async {
        var events = await loadEvents()
        events.append(event)
        
        // 최대 개수 초과 시 오래된 이벤트 제거
        if events.count > maxEventsCount {
            events = Array(events.sorted { $0.timestamp > $1.timestamp }.prefix(maxEventsCount))
        }
        
        await saveEvents(events)
    }
    
    /// 모든 이벤트 로드
    private func loadEvents() async -> [SecurityEvent] {
        guard let data = userDefaults.data(forKey: eventsKey) else { return [] }
        
        do {
            return try JSONDecoder().decode([SecurityEvent].self, from: data)
        } catch {
            print("Failed to decode security events: \(error)")
            return []
        }
    }
    
    /// 모든 이벤트 저장
    private func saveEvents(_ events: [SecurityEvent]) async {
        do {
            let data = try JSONEncoder().encode(events)
            userDefaults.set(data, forKey: eventsKey)
        } catch {
            print("Failed to encode security events: \(error)")
        }
    }
    
    /// 디바이스 정보 수집
    private func getDeviceInfo() async -> DeviceInfo {
        return DeviceInfo(
            deviceId: await getDeviceId(),
            appVersion: getAppVersion(),
            osVersion: getOSVersion(),
            deviceModel: getDeviceModel()
        )
    }
    
    /// 디바이스 ID 가져오기
    private func getDeviceId() async -> String {
        return await SessionManager.shared.getCurrentSession()?.deviceId ?? "unknown"
    }
    
    /// 앱 버전 가져오기
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
    
    /// OS 버전 가져오기
    private func getOSVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    /// 디바이스 모델 가져오기
    private func getDeviceModel() -> String {
        return UIDevice.current.model
    }
    
    /// 보안 이벤트 알림
    private func notifySecurityEvent(_ event: SecurityEvent) async {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .securityEventOccurred,
                object: nil,
                userInfo: ["event": event]
            )
        }
    }
}

// MARK: - Security Event

struct SecurityEvent: Codable, Identifiable {
    let id: String
    let type: SecurityEventType
    let identifier: String?
    let timestamp: Date
    let details: [String: String] // Codable을 위해 [String: Any] 대신 사용
    let deviceInfo: DeviceInfo
    
    init(id: String, type: SecurityEventType, identifier: String?, timestamp: Date, details: [String: Any], deviceInfo: DeviceInfo) {
        self.id = id
        self.type = type
        self.identifier = identifier
        self.timestamp = timestamp
        self.deviceInfo = deviceInfo
        
        // [String: Any]를 [String: String]으로 변환
        var stringDetails: [String: String] = [:]
        for (key, value) in details {
            stringDetails[key] = String(describing: value)
        }
        self.details = stringDetails
    }
}

// MARK: - Security Event Type

enum SecurityEventType: String, Codable, CaseIterable {
    case loginSuccess = "login_success"
    case loginFailure = "login_failure"
    case accountLocked = "account_locked"
    case accountUnlocked = "account_unlocked"
    case sessionExpired = "session_expired"
    case sessionRefreshed = "session_refreshed"
    case passwordChanged = "password_changed"
    case suspiciousActivity = "suspicious_activity"
    case dataSync = "data_sync"
    case appVersionMismatch = "app_version_mismatch"
    
    var displayName: String {
        switch self {
        case .loginSuccess:
            return "로그인 성공"
        case .loginFailure:
            return "로그인 실패"
        case .accountLocked:
            return "계정 잠금"
        case .accountUnlocked:
            return "계정 잠금 해제"
        case .sessionExpired:
            return "세션 만료"
        case .sessionRefreshed:
            return "세션 갱신"
        case .passwordChanged:
            return "비밀번호 변경"
        case .suspiciousActivity:
            return "의심스러운 활동"
        case .dataSync:
            return "데이터 동기화"
        case .appVersionMismatch:
            return "앱 버전 불일치"
        }
    }
    
    var isCritical: Bool {
        switch self {
        case .accountLocked, .suspiciousActivity, .appVersionMismatch:
            return true
        default:
            return false
        }
    }
    
    var iconName: String {
        switch self {
        case .loginSuccess:
            return "checkmark.circle"
        case .loginFailure:
            return "xmark.circle"
        case .accountLocked:
            return "lock"
        case .accountUnlocked:
            return "lock.open"
        case .sessionExpired:
            return "clock.badge.exclamationmark"
        case .sessionRefreshed:
            return "arrow.clockwise"
        case .passwordChanged:
            return "key"
        case .suspiciousActivity:
            return "exclamationmark.triangle"
        case .dataSync:
            return "arrow.triangle.2.circlepath"
        case .appVersionMismatch:
            return "app.badge"
        }
    }
}

// MARK: - Device Info

struct DeviceInfo: Codable {
    let deviceId: String
    let appVersion: String
    let osVersion: String
    let deviceModel: String
}

// MARK: - Security Event Statistics

struct SecurityEventStatistics {
    let totalEvents: Int
    let criticalEvents: Int
    let recentEvents: Int
    let typeCounts: [SecurityEventType: Int]
    let oldestEvent: Date?
    let newestEvent: Date?
    
    var criticalEventPercentage: Double {
        guard totalEvents > 0 else { return 0 }
        return Double(criticalEvents) / Double(totalEvents) * 100
    }
    
    var mostCommonEventType: SecurityEventType? {
        return typeCounts.max { $0.value < $1.value }?.key
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let securityEventOccurred = Notification.Name("securityEventOccurred")
}

// MARK: - UIDevice Extension

import UIKit

extension UIDevice {
    static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        return identifier
    }
}