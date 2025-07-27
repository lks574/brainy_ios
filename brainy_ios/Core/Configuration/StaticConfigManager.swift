import Foundation

/// 정적 설정 관리자
actor StaticConfigManager {
    // MARK: - Properties
    private var cachedConfig: StaticConfig?
    private var lastConfigUpdate: Date?
    private let configCacheKey = "static_config_cache"
    private let configUpdateKey = "static_config_last_update"
    private let cacheExpirationInterval: TimeInterval = 3600 // 1시간
    
    // Supabase Storage URL (실제 URL로 교체 필요)
    private let configStorageURL = "https://your-project.supabase.co/storage/v1/object/public/config/static_config.json"
    
    // MARK: - Public Methods
    
    /// 정적 설정을 로드합니다 (캐시 우선, 만료 시 다운로드)
    func loadStaticConfig() async throws -> StaticConfig {
        // 1. 캐시된 설정이 있고 만료되지 않았다면 반환
        if let cachedConfig = cachedConfig,
           let lastUpdate = lastConfigUpdate,
           !isConfigExpired(lastUpdate: lastUpdate) {
            return cachedConfig
        }
        
        // 2. 로컬 저장소에서 캐시된 설정 확인
        if let localCachedConfig = loadCachedConfigFromUserDefaults(),
           let lastUpdate = UserDefaults.standard.object(forKey: configUpdateKey) as? Date,
           !isConfigExpired(lastUpdate: lastUpdate) {
            cachedConfig = localCachedConfig
            lastConfigUpdate = lastUpdate
            return localCachedConfig
        }
        
        // 3. 네트워크에서 새로운 설정 다운로드 시도
        do {
            let downloadedConfig = try await downloadConfigFromStorage()
            await updateCache(config: downloadedConfig)
            return downloadedConfig
        } catch {
            // 4. 다운로드 실패 시 캐시된 설정 또는 기본 설정 반환
            if let fallbackConfig = cachedConfig ?? loadCachedConfigFromUserDefaults() {
                return fallbackConfig
            } else {
                return StaticConfig.defaultConfig
            }
        }
    }
    
    /// Supabase Storage에서 설정 파일을 다운로드합니다
    func downloadConfigFromStorage() async throws -> StaticConfig {
        guard let url = URL(string: configStorageURL) else {
            throw StaticConfigError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StaticConfigError.downloadFailed
        }
        
        let config = try JSONDecoder().decode(StaticConfig.self, from: data)
        
        // 설정 유효성 검증
        guard validateConfig(config) else {
            throw StaticConfigError.invalidConfig
        }
        
        return config
    }
    
    /// 캐시된 설정을 반환합니다 (네트워크 없이)
    func getCachedConfig() -> StaticConfig? {
        return cachedConfig ?? loadCachedConfigFromUserDefaults()
    }
    
    /// 설정이 만료되었는지 확인합니다
    func isConfigExpired() -> Bool {
        guard let lastUpdate = lastConfigUpdate else { return true }
        return isConfigExpired(lastUpdate: lastUpdate)
    }
    
    /// 설정 캐시를 강제로 갱신합니다
    func forceRefreshConfig() async throws -> StaticConfig {
        let config = try await downloadConfigFromStorage()
        await updateCache(config: config)
        return config
    }
    
    // MARK: - Private Methods
    
    /// 설정이 만료되었는지 확인
    private func isConfigExpired(lastUpdate: Date) -> Bool {
        return Date().timeIntervalSince(lastUpdate) > cacheExpirationInterval
    }
    
    /// 설정 유효성 검증
    func validateConfig(_ config: StaticConfig) -> Bool {
        // 기본 유효성 검사
        guard !config.quizVersion.isEmpty,
              !config.categories.isEmpty,
              !config.minAppVersion.isEmpty,
              config.authConfig.passwordMinLength > 0,
              config.authConfig.sessionTimeoutMinutes > 0,
              config.authConfig.maxLoginAttempts > 0 else {
            return false
        }
        
        // 인증 방식 유효성 검사
        let validAuthMethods = ["email", "google", "apple"]
        for method in config.authConfig.authMethodsEnabled {
            if !validAuthMethods.contains(method) {
                return false
            }
        }
        
        return true
    }
    
    /// 캐시 업데이트
    private func updateCache(config: StaticConfig) async {
        cachedConfig = config
        lastConfigUpdate = Date()
        
        // UserDefaults에 저장
        saveCachedConfigToUserDefaults(config: config)
        UserDefaults.standard.set(Date(), forKey: configUpdateKey)
    }
    
    /// UserDefaults에서 캐시된 설정 로드
    private func loadCachedConfigFromUserDefaults() -> StaticConfig? {
        guard let data = UserDefaults.standard.data(forKey: configCacheKey) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(StaticConfig.self, from: data)
        } catch {
            print("Failed to decode cached config: \(error)")
            return nil
        }
    }
    
    /// UserDefaults에 설정 저장
    private func saveCachedConfigToUserDefaults(config: StaticConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            UserDefaults.standard.set(data, forKey: configCacheKey)
        } catch {
            print("Failed to encode config for caching: \(error)")
        }
    }
}

// MARK: - Error Types

enum StaticConfigError: LocalizedError {
    case invalidURL
    case downloadFailed
    case invalidConfig
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 설정 파일 URL입니다."
        case .downloadFailed:
            return "설정 파일 다운로드에 실패했습니다."
        case .invalidConfig:
            return "설정 파일이 유효하지 않습니다."
        case .decodingFailed:
            return "설정 파일 파싱에 실패했습니다."
        }
    }
}

// MARK: - Singleton Access

extension StaticConfigManager {
    static let shared = StaticConfigManager()
}