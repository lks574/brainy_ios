import Foundation

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