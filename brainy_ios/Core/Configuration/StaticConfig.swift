import Foundation

// MARK: - Static Configuration Models

/// 앱의 정적 설정 구조
struct StaticConfig: Codable {
    let quizVersion: String
    let downloadUrl: String
    let categories: [String]
    let maintenanceMode: Bool
    let minAppVersion: String
    let featureFlags: FeatureFlags
    let authConfig: AuthStaticConfig
    let forceUpdateVersions: [String]?
    
    enum CodingKeys: String, CodingKey {
        case quizVersion = "quiz_version"
        case downloadUrl = "download_url"
        case categories
        case maintenanceMode = "maintenance_mode"
        case minAppVersion = "min_app_version"
        case featureFlags = "feature_flags"
        case authConfig = "auth_config"
        case forceUpdateVersions = "force_update_versions"
    }
}

/// 기능 플래그 설정
struct FeatureFlags: Codable {
    let aiQuiz: Bool
    let voiceMode: Bool
    let offlineMode: Bool
    
    enum CodingKeys: String, CodingKey {
        case aiQuiz = "ai_quiz"
        case voiceMode = "voice_mode"
        case offlineMode = "offline_mode"
    }
}

/// 인증 관련 정적 설정
struct AuthStaticConfig: Codable {
    let authMethodsEnabled: [String]
    let socialLoginRequired: Bool
    let passwordMinLength: Int
    let sessionTimeoutMinutes: Int
    let maxLoginAttempts: Int
    let minAppVersionForAuth: String
    
    enum CodingKeys: String, CodingKey {
        case authMethodsEnabled = "auth_methods_enabled"
        case socialLoginRequired = "social_login_required"
        case passwordMinLength = "password_min_length"
        case sessionTimeoutMinutes = "session_timeout_minutes"
        case maxLoginAttempts = "max_login_attempts"
        case minAppVersionForAuth = "min_app_version_for_auth"
    }
}

// MARK: - Default Configuration

extension StaticConfig {
    /// 기본 정적 설정 (오프라인 시 사용)
    static let defaultConfig = StaticConfig(
        quizVersion: "1.0.0",
        downloadUrl: "",
        categories: ["person", "general", "country", "drama", "music"],
        maintenanceMode: false,
        minAppVersion: "1.0.0",
        featureFlags: FeatureFlags(
            aiQuiz: true,
            voiceMode: true,
            offlineMode: true
        ),
        authConfig: AuthStaticConfig(
            authMethodsEnabled: ["email", "google", "apple"],
            socialLoginRequired: false,
            passwordMinLength: 8,
            sessionTimeoutMinutes: 60,
            maxLoginAttempts: 5,
            minAppVersionForAuth: "1.0.0"
        ),
        forceUpdateVersions: nil
    )
}

extension FeatureFlags {
    /// 기본 기능 플래그
    static let defaultFlags = FeatureFlags(
        aiQuiz: true,
        voiceMode: true,
        offlineMode: true
    )
}

extension AuthStaticConfig {
    /// 기본 인증 설정
    static let defaultAuthConfig = AuthStaticConfig(
        authMethodsEnabled: ["email", "google", "apple"],
        socialLoginRequired: false,
        passwordMinLength: 8,
        sessionTimeoutMinutes: 60,
        maxLoginAttempts: 5,
        minAppVersionForAuth: "1.0.0"
    )
}