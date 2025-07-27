import Foundation
import Security

/// Keychain 관리자
class KeychainManager {
    // MARK: - Singleton
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Service Identifier
    private let service = Bundle.main.bundleIdentifier ?? "com.brainy.quiz"
    
    // MARK: - Save Methods
    
    /// String 값을 Keychain에 저장
    func save(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        try save(data, for: key)
    }
    
    /// Double 값을 Keychain에 저장
    func save(_ value: Double, for key: String) throws {
        let data = withUnsafeBytes(of: value) { Data($0) }
        try save(data, for: key)
    }
    
    /// Data를 Keychain에 저장
    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 기존 항목 삭제
        SecItemDelete(query as CFDictionary)
        
        // 새 항목 추가
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    // MARK: - Load Methods
    
    /// String 값을 Keychain에서 로드
    func load<T>(_ key: String) -> T? {
        guard let data = loadData(for: key) else { return nil }
        
        if T.self == String.self {
            return String(data: data, encoding: .utf8) as? T
        } else if T.self == Double.self {
            return data.withUnsafeBytes { $0.load(as: Double.self) } as? T
        }
        
        return nil
    }
    
    /// Data를 Keychain에서 로드
    private func loadData(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        
        return result as? Data
    }
    
    // MARK: - Delete Methods
    
    /// 특정 키의 항목을 Keychain에서 삭제
    func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// 모든 항목을 Keychain에서 삭제
    func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Utility Methods
    
    /// 특정 키가 Keychain에 존재하는지 확인
    func exists(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Keychain의 모든 키 목록 반환
    func getAllKeys() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }
}

// MARK: - Keychain Error

enum KeychainError: LocalizedError {
    case invalidData
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "유효하지 않은 데이터입니다."
        case .saveFailed(let status):
            return "키체인 저장 실패: \(status)"
        case .loadFailed(let status):
            return "키체인 로드 실패: \(status)"
        case .deleteFailed(let status):
            return "키체인 삭제 실패: \(status)"
        }
    }
}