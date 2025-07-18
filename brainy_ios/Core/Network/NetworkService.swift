import Foundation
import UIKit

/// 네트워크 서비스 프로토콜
protocol NetworkServiceProtocol: Sendable {
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T
    func download(from url: URL) async throws -> Data
}

/// 네트워크 서비스 구현체
final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    private let baseURL: String
    
    init(baseURL: String = "https://api.brainy-quiz.com", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func request<T: Codable>(_ endpoint: APIEndpoint) async throws -> T {
        let url = try buildURL(for: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        
        if let body = endpoint.body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BrainyError.networkUnavailable
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw BrainyError.networkError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
            
        } catch {
            if error is DecodingError {
                throw BrainyError.dataCorrupted
            } else if error is URLError {
                throw BrainyError.networkUnavailable
            } else {
                throw error
            }
        }
    }
    
    func download(from url: URL) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw BrainyError.networkUnavailable
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw BrainyError.networkError(httpResponse.statusCode)
            }
            
            return data
            
        } catch {
            if error is URLError {
                throw BrainyError.networkUnavailable
            } else {
                throw error
            }
        }
    }
    
    private func buildURL(for endpoint: APIEndpoint) throws -> URL {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw BrainyError.invalidURL
        }
        
        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            guard let finalURL = components?.url else {
                throw BrainyError.invalidURL
            }
            return finalURL
        }
        
        return url
    }
}

/// HTTP 메서드
enum HTTPMethod: String, Sendable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

/// API 엔드포인트 프로토콜
protocol APIEndpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

/// 퀴즈 관련 API 엔드포인트
enum QuizAPIEndpoint: APIEndpoint, Sendable {
    case getVersion
    case downloadQuizData(version: String)
    
    var path: String {
        switch self {
        case .getVersion:
            return "/api/v1/quiz/version"
        case .downloadQuizData:
            return "/api/v1/quiz/data"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getVersion, .downloadQuizData:
            return .GET
        }
    }
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getVersion:
            return nil
        case .downloadQuizData(let version):
            return [URLQueryItem(name: "version", value: version)]
        }
    }
    
    var body: Data? {
        return nil
    }
}

/// 동기화 관련 API 엔드포인트
enum SyncAPIEndpoint: APIEndpoint, Sendable {
    case uploadUserData(data: UserSyncData)
    case downloadUserData(userId: String)
    case getSyncStatus(userId: String)
    
    var path: String {
        switch self {
        case .uploadUserData:
            return "/api/v1/sync/upload"
        case .downloadUserData(let userId):
            return "/api/v1/sync/download/\(userId)"
        case .getSyncStatus(let userId):
            return "/api/v1/sync/status/\(userId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .uploadUserData:
            return .POST
        case .downloadUserData, .getSyncStatus:
            return .GET
        }
    }
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
    
    var body: Data? {
        switch self {
        case .uploadUserData(let data):
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try? encoder.encode(data)
        case .downloadUserData, .getSyncStatus:
            return nil
        }
    }
}
// MARK: - Sync Data Models

/// 동기화용 사용자 데이터
struct UserSyncData: Codable, Sendable {
    let userId: String
    let quizResults: [SyncQuizResult]
    let quizSessions: [SyncQuizSession]
    let lastSyncAt: Date
    let deviceInfo: DeviceInfo
}

/// 동기화용 퀴즈 결과
struct SyncQuizResult: Codable, Sendable {
    let id: String
    let userId: String
    let questionId: String
    let userAnswer: String
    let isCorrect: Bool
    let timeSpent: TimeInterval
    let completedAt: Date
    let category: QuizCategory
    let quizMode: QuizMode
    
    init(from result: QuizResult) {
        self.id = result.id
        self.userId = result.userId
        self.questionId = result.questionId
        self.userAnswer = result.userAnswer
        self.isCorrect = result.isCorrect
        self.timeSpent = result.timeSpent
        self.completedAt = result.completedAt
        self.category = result.category
        self.quizMode = result.quizMode
    }
}

/// 동기화용 퀴즈 세션
struct SyncQuizSession: Codable, Sendable {
    let id: String
    let userId: String
    let category: QuizCategory
    let mode: QuizMode
    let totalQuestions: Int
    let correctAnswers: Int
    let totalTime: TimeInterval
    let startedAt: Date
    let completedAt: Date?
    
    init(from session: QuizSession) {
        self.id = session.id
        self.userId = session.userId
        self.category = session.category
        self.mode = session.mode
        self.totalQuestions = session.totalQuestions
        self.correctAnswers = session.correctAnswers
        self.totalTime = session.totalTime
        self.startedAt = session.startedAt
        self.completedAt = session.completedAt
    }
}

/// 동기화 응답
struct SyncResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let newResults: [SyncQuizResult]
    let newSessions: [SyncQuizSession]
    let syncedAt: Date
}

/// 사용자 백업 데이터
struct UserBackupData: Codable, Sendable {
    let userId: String
    let quizResults: [SyncQuizResult]
    let quizSessions: [SyncQuizSession]
    let backupDate: Date
}

/// 동기화 상태
struct SyncStatus: Codable, Sendable {
    let userId: String
    let lastSyncAt: Date?
    let isUpToDate: Bool
    let pendingChanges: Int
}

/// 디바이스 정보
struct DeviceInfo: Codable, Sendable {
    let deviceModel: String
    let systemVersion: String
    let appVersion: String
    let timestamp: Date

    @MainActor
    static func current() -> DeviceInfo {
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        return DeviceInfo(
            deviceModel: device.model,
            systemVersion: device.systemVersion,
            appVersion: appVersion,
            timestamp: Date()
        )
    }
}
