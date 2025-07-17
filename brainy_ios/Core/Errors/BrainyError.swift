import Foundation

enum BrainyError: LocalizedError {
    case authenticationFailed(String)
    case networkUnavailable
    case dataCorrupted
    case quizNotFound
    case syncFailed(String)
    case adLoadFailed
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "로그인 실패: \(message)"
        case .networkUnavailable:
            return "네트워크 연결을 확인해주세요"
        case .dataCorrupted:
            return "데이터가 손상되었습니다"
        case .quizNotFound:
            return "퀴즈를 찾을 수 없습니다"
        case .syncFailed(let message):
            return "동기화 실패: \(message)"
        case .adLoadFailed:
            return "광고 로드에 실패했습니다"
        }
    }
}