import Foundation
import UIKit

/// 앱 버전 관리자
actor AppVersionManager {
    // MARK: - Properties
    private let configManager = StaticConfigManager.shared
    
    // MARK: - Singleton
    static let shared = AppVersionManager()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 현재 앱 버전이 최소 요구 버전을 만족하는지 확인
    func validateAppVersion() async -> AppVersionStatus {
        do {
            let config = try await configManager.loadStaticConfig()
            let currentVersion = getCurrentAppVersion()
            let minRequiredVersion = config.minAppVersion
            let authMinVersion = config.authConfig.minAppVersionForAuth
            
            // 전체 앱 버전 체크
            if !isVersionCompatible(current: currentVersion, minimum: minRequiredVersion) {
                return .updateRequired(
                    currentVersion: currentVersion,
                    requiredVersion: minRequiredVersion,
                    message: "앱을 최신 버전으로 업데이트해 주세요."
                )
            }
            
            // 인증 기능 버전 체크
            if !isVersionCompatible(current: currentVersion, minimum: authMinVersion) {
                return .authUpdateRequired(
                    currentVersion: currentVersion,
                    requiredVersion: authMinVersion,
                    message: "로그인 기능을 사용하려면 앱을 업데이트해 주세요."
                )
            }
            
            return .compatible
            
        } catch {
            print("Failed to validate app version: \(error)")
            // 설정을 가져올 수 없는 경우 호환 가능으로 처리
            return .compatible
        }
    }
    
    /// 현재 앱 버전을 반환
    func getCurrentAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// 현재 빌드 번호를 반환
    func getCurrentBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// 앱 스토어 업데이트 URL을 반환
    func getAppStoreURL() -> URL? {
        // 실제 앱 스토어 ID로 교체 필요
        let appStoreID = "YOUR_APP_STORE_ID"
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }
    
    // MARK: - Private Methods
    
    /// 버전 호환성 확인
    private func isVersionCompatible(current: String, minimum: String) -> Bool {
        return current.compare(minimum, options: .numeric) != .orderedAscending
    }
}

// MARK: - App Version Status

enum AppVersionStatus {
    case compatible
    case updateRequired(currentVersion: String, requiredVersion: String, message: String)
    case authUpdateRequired(currentVersion: String, requiredVersion: String, message: String)
    
    var isUpdateRequired: Bool {
        switch self {
        case .compatible:
            return false
        case .updateRequired, .authUpdateRequired:
            return true
        }
    }
    
    var updateMessage: String? {
        switch self {
        case .compatible:
            return nil
        case .updateRequired(_, _, let message),
             .authUpdateRequired(_, _, let message):
            return message
        }
    }
}

// MARK: - Update Alert View

import SwiftUI

struct UpdateRequiredView: View {
    let status: AppVersionStatus
    let onUpdateTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 업데이트 아이콘
            Image(systemName: "arrow.up.circle")
                .font(.system(size: 80))
                .foregroundColor(.brainyPrimary)
            
            // 업데이트 메시지
            VStack(spacing: 16) {
                Text("업데이트 필요")
                    .font(.brainyTitle)
                    .foregroundColor(.brainyText)
                
                if let message = status.updateMessage {
                    Text(message)
                        .font(.brainyBody)
                        .foregroundColor(.brainyTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                if case .updateRequired(let current, let required, _) = status {
                    VStack(spacing: 8) {
                        Text("현재 버전: \(current)")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                        
                        Text("필요 버전: \(required)")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                    }
                }
            }
            
            Spacer()
            
            // 업데이트 버튼
            BrainyButton(
                "앱 스토어에서 업데이트",
                style: .primary
            ) {
                onUpdateTapped()
            }
            .padding(.horizontal, 32)
            
            // 안내 텍스트
            Text("업데이트 후 더 나은 서비스를 이용하실 수 있습니다.")
                .font(.brainyCaption)
                .foregroundColor(.brainyTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 32)
        .background(Color.brainyBackground)
        .navigationBarHidden(true)
    }
}