import Foundation
import Network

/// 네트워크 에러 처리 및 재시도 관리자
actor NetworkErrorHandler {
    // MARK: - Properties
    private let maxRetryAttempts = 3
    private let baseRetryDelay: TimeInterval = 1.0
    private let maxRetryDelay: TimeInterval = 30.0
    
    // Network monitor
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    // MARK: - Singleton
    static let shared = NetworkErrorHandler()
    
    private init() {
        startNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    /// 네트워크 모니터링 시작
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
                
                // 연결 상태 변경 알림
                NotificationCenter.default.post(
                    name: .networkStatusChanged,
                    object: nil,
                    userInfo: [
                        "isConnected": path.status == .satisfied,
                        "connectionType": path.availableInterfaces.first?.type?.rawValue ?? "unknown"
                    ]
                )
            }
        }
        
        networkMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Retry Logic
    
    /// 네트워크 요청을 재시도와 함께 실행
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        maxAttempts: Int? = nil,
        shouldRetry: ((Error) -> Bool)? = nil
    ) async throws -> T {
        let attempts = maxAttempts ?? maxRetryAttempts
        var lastError: Error?
        
        for attempt in 1...attempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // 재시도 여부 확인
                let shouldRetryError = shouldRetry?(error) ?? shouldRetryForError(error)
                
                if attempt < attempts && shouldRetryError {
                    let delay = calculateRetryDelay(attempt: attempt)
                    
                    // 보안 이벤트 로깅
                    await logRetryAttempt(attempt: attempt, error: error, delay: delay)
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    break
                }
            }
        }
        
        // 모든 재시도 실패
        if let error = lastError {
            await logRetryFailure(error: error, attempts: attempts)
            throw NetworkError.retryExhausted(originalError: error, attempts: attempts)
        } else {
            throw NetworkError.unknown
        }
    }
    
    /// 에러에 대한 재시도 여부 결정
    private func shouldRetryForError(_ error: Error) -> Bool {
        // 네트워크 연결 상태 확인
        guard isConnected else { return false }
        
        if let networkError = error as? NetworkError {
            switch networkError {
            case .noConnection, .timeout, .serverError:
                return true
            case .unauthorized, .forbidden, .notFound, .clientError:
                return false
            case .retryExhausted, .unknown:
                return false
            }
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
                return true
            case .badURL, .unsupportedURL, .cannotParseResponse:
                return false
            default:
                return true
            }
        }
        
        return true
    }
    
    /// 재시도 지연 시간 계산 (지수 백오프)
    private func calculateRetryDelay(attempt: Int) -> TimeInterval {
        let exponentialDelay = baseRetryDelay * pow(2.0, Double(attempt - 1))
        let jitter = Double.random(in: 0...0.1) * exponentialDelay
        return min(exponentialDelay + jitter, maxRetryDelay)
    }
    
    // MARK: - Network Status
    
    /// 현재 네트워크 연결 상태
    func getCurrentNetworkStatus() -> NetworkStatus {
        return NetworkStatus(
            isConnected: isConnected,
            connectionType: connectionType,
            lastChecked: Date()
        )
    }
    
    /// 네트워크 연결 대기
    func waitForConnection(timeout: TimeInterval = 30.0) async throws {
        guard !isConnected else { return }
        
        let startTime = Date()
        
        while !isConnected {
            if Date().timeIntervalSince(startTime) > timeout {
                throw NetworkError.timeout
            }
            
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
        }
    }
    
    // MARK: - Error Logging
    
    /// 재시도 시도 로깅
    private func logRetryAttempt(attempt: Int, error: Error, delay: TimeInterval) async {
        await SecurityEventLogger.shared.logEvent(
            type: .suspiciousActivity,
            details: [
                "event": "network_retry_attempt",
                "attempt": String(attempt),
                "error": error.localizedDescription,
                "delay": String(delay),
                "network_status": isConnected ? "connected" : "disconnected"
            ]
        )
    }
    
    /// 재시도 실패 로깅
    private func logRetryFailure(error: Error, attempts: Int) async {
        await SecurityEventLogger.shared.logEvent(
            type: .suspiciousActivity,
            details: [
                "event": "network_retry_exhausted",
                "total_attempts": String(attempts),
                "final_error": error.localizedDescription,
                "network_status": isConnected ? "connected" : "disconnected"
            ]
        )
    }
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case clientError(Int)
    case serverError(Int)
    case retryExhausted(originalError: Error, attempts: Int)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "인터넷 연결을 확인해주세요"
        case .timeout:
            return "요청 시간이 초과되었습니다"
        case .unauthorized:
            return "인증이 필요합니다"
        case .forbidden:
            return "접근 권한이 없습니다"
        case .notFound:
            return "요청한 리소스를 찾을 수 없습니다"
        case .clientError(let code):
            return "클라이언트 오류 (코드: \(code))"
        case .serverError(let code):
            return "서버 오류 (코드: \(code))"
        case .retryExhausted(let originalError, let attempts):
            return "\(attempts)번 재시도 후 실패: \(originalError.localizedDescription)"
        case .unknown:
            return "알 수 없는 네트워크 오류가 발생했습니다"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Wi-Fi 또는 모바일 데이터 연결을 확인하고 다시 시도해주세요"
        case .timeout:
            return "네트워크 상태를 확인하고 다시 시도해주세요"
        case .unauthorized:
            return "다시 로그인해주세요"
        case .forbidden:
            return "관리자에게 문의하세요"
        case .notFound:
            return "앱을 최신 버전으로 업데이트해주세요"
        case .clientError, .serverError:
            return "잠시 후 다시 시도해주세요"
        case .retryExhausted:
            return "네트워크 상태를 확인하고 잠시 후 다시 시도해주세요"
        case .unknown:
            return "앱을 재시작하거나 잠시 후 다시 시도해주세요"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .serverError:
            return true
        case .unauthorized, .forbidden, .notFound, .clientError:
            return false
        case .retryExhausted, .unknown:
            return false
        }
    }
}

// MARK: - Network Status

struct NetworkStatus {
    let isConnected: Bool
    let connectionType: NWInterface.InterfaceType?
    let lastChecked: Date
    
    var connectionTypeString: String {
        switch connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "모바일 데이터"
        case .wiredEthernet:
            return "이더넷"
        case .loopback:
            return "로컬"
        case .other:
            return "기타"
        case .none:
            return "연결 없음"
        @unknown default:
            return "알 수 없음"
        }
    }
    
    var statusMessage: String {
        if isConnected {
            return "\(connectionTypeString)에 연결됨"
        } else {
            return "인터넷에 연결되지 않음"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}