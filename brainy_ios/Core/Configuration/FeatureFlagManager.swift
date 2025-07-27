import Foundation

/// 기능 플래그 관리자
@MainActor
class FeatureFlagManager: ObservableObject {
    // MARK: - Properties
    @Published private var currentFlags: FeatureFlags = .defaultFlags
    private let configManager = StaticConfigManager.shared
    
    // MARK: - Singleton
    static let shared = FeatureFlagManager()
    
    private init() {
        Task {
            await loadFeatureFlags()
        }
    }
    
    // MARK: - Public Methods
    
    /// 기능 플래그를 로드합니다
    func loadFeatureFlags() async {
        do {
            let config = try await configManager.loadStaticConfig()
            currentFlags = config.featureFlags
        } catch {
            print("Failed to load feature flags: \(error)")
            // 실패 시 기본값 사용
            currentFlags = .defaultFlags
        }
    }
    
    /// 기능 플래그를 강제로 새로고침합니다
    func refreshFeatureFlags() async {
        do {
            let config = try await configManager.forceRefreshConfig()
            currentFlags = config.featureFlags
        } catch {
            print("Failed to refresh feature flags: \(error)")
        }
    }
    
    // MARK: - Feature Flag Checks
    
    /// AI 퀴즈 기능이 활성화되어 있는지 확인
    var isAIQuizEnabled: Bool {
        currentFlags.aiQuiz
    }
    
    /// 음성 모드 기능이 활성화되어 있는지 확인
    var isVoiceModeEnabled: Bool {
        currentFlags.voiceMode
    }
    
    /// 오프라인 모드 기능이 활성화되어 있는지 확인
    var isOfflineModeEnabled: Bool {
        currentFlags.offlineMode
    }
    
    /// 특정 기능이 활성화되어 있는지 확인하는 범용 메서드
    func isFeatureEnabled(_ feature: Feature) -> Bool {
        switch feature {
        case .aiQuiz:
            return isAIQuizEnabled
        case .voiceMode:
            return isVoiceModeEnabled
        case .offlineMode:
            return isOfflineModeEnabled
        }
    }
    
    /// 현재 활성화된 퀴즈 모드들을 반환
    var availableQuizModes: [QuizType] {
        var modes: [QuizType] = [.multipleChoice, .shortAnswer]
        
        if isVoiceModeEnabled {
            modes.append(.voice)
        }
        
        if isAIQuizEnabled {
            modes.append(.ai)
        }
        
        return modes
    }
}

// MARK: - Feature Enum

enum Feature: String, CaseIterable {
    case aiQuiz = "ai_quiz"
    case voiceMode = "voice_mode"
    case offlineMode = "offline_mode"
    
    var displayName: String {
        switch self {
        case .aiQuiz:
            return "AI 퀴즈"
        case .voiceMode:
            return "음성 모드"
        case .offlineMode:
            return "오프라인 모드"
        }
    }
    
    var description: String {
        switch self {
        case .aiQuiz:
            return "AI가 생성하는 동적 퀴즈"
        case .voiceMode:
            return "음성으로 듣고 답하는 퀴즈"
        case .offlineMode:
            return "인터넷 없이도 퀴즈 플레이"
        }
    }
}

// MARK: - SwiftUI Environment

struct FeatureFlagEnvironmentKey: EnvironmentKey {
    static let defaultValue = FeatureFlagManager.shared
}

extension EnvironmentValues {
    var featureFlagManager: FeatureFlagManager {
        get { self[FeatureFlagEnvironmentKey.self] }
        set { self[FeatureFlagEnvironmentKey.self] = newValue }
    }
}