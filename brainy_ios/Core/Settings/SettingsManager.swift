import Foundation
import SwiftUI

/// 앱 설정을 관리하는 클래스
@MainActor
class SettingsManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isDarkModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDarkModeEnabled, forKey: "isDarkModeEnabled")
        }
    }
    
    @Published var isNotificationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isNotificationEnabled, forKey: "isNotificationEnabled")
        }
    }
    
    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "isSoundEnabled")
        }
    }
    
    @Published var lastSyncDate: Date? {
        didSet {
            if let date = lastSyncDate {
                UserDefaults.standard.set(date, forKey: "lastSyncDate")
            } else {
                UserDefaults.standard.removeObject(forKey: "lastSyncDate")
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        self.isDarkModeEnabled = UserDefaults.standard.bool(forKey: "isDarkModeEnabled")
        self.isNotificationEnabled = UserDefaults.standard.bool(forKey: "isNotificationEnabled")
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "isSoundEnabled") as? Bool ?? true
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }
    
    // MARK: - Methods
    
    /// 모든 설정을 기본값으로 초기화
    func resetToDefaults() {
        isDarkModeEnabled = false
        isNotificationEnabled = false
        isSoundEnabled = true
        lastSyncDate = nil
    }
    
    /// 현재 색상 스키마 반환
    var colorScheme: ColorScheme? {
        isDarkModeEnabled ? .dark : .light
    }
    
    /// 마지막 동기화 시간 문자열 반환
    var lastSyncDateString: String {
        guard let lastSyncDate = lastSyncDate else {
            return "동기화한 적 없음"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.string(from: lastSyncDate)
    }
}