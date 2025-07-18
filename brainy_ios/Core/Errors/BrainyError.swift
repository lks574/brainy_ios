import Foundation

enum BrainyError: LocalizedError, Sendable {
    case authenticationFailed(String)
    case validationError(String)
    case networkError(Int)
    case networkUnavailable
    case dataCorrupted
    case dataError(String)
    case quizNotFound
    case syncFailed(String)
    case adLoadFailed
    case invalidURL
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "로그인 실패: \(message)"
        case .validationError(let message):
            return "입력 오류: \(message)"
        case .networkError(let statusCode):
            return "네트워크 오류: HTTP \(statusCode)"
        case .networkUnavailable:
            return "네트워크 연결을 확인해주세요"
        case .dataCorrupted:
            return "데이터가 손상되었습니다"
        case .dataError(let message):
            return "데이터 오류: \(message)"
        case .quizNotFound:
            return "퀴즈를 찾을 수 없습니다"
        case .syncFailed(let message):
            return "동기화 실패: \(message)"
        case .adLoadFailed:
            return "광고 로드에 실패했습니다"
        case .invalidURL:
            return "잘못된 URL입니다"
        case .unknownError(let message):
            return "알 수 없는 오류: \(message)"
        }
    }
}