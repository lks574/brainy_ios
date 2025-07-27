import SwiftUI

/// 앱 설정 상태를 확인하고 적절한 화면을 표시하는 뷰
struct AppConfigurationView<Content: View>: View {
    @StateObject private var featureFlagManager = FeatureFlagManager.shared
    @State private var configurationState: ConfigurationState = .loading
    @State private var staticConfig: StaticConfig?
    
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        Group {
            switch configurationState {
            case .loading:
                LoadingConfigurationView()
                
            case .maintenance:
                MaintenanceView {
                    await checkConfiguration()
                }
                
            case .updateRequired(let status):
                UpdateRequiredView(status: status) {
                    openAppStore()
                }
                
            case .ready:
                content()
                    .environment(\.featureFlagManager, featureFlagManager)
            }
        }
        .task {
            await checkConfiguration()
        }
    }
    
    // MARK: - Private Methods
    
    private func checkConfiguration() async {
        configurationState = .loading
        
        // 1. 앱 버전 확인
        let versionStatus = await AppVersionManager.shared.validateAppVersion()
        if versionStatus.isUpdateRequired {
            configurationState = .updateRequired(versionStatus)
            return
        }
        
        // 2. 정적 설정 로드
        do {
            let config = try await StaticConfigManager.shared.loadStaticConfig()
            staticConfig = config
            
            // 3. 점검 모드 확인
            if config.maintenanceMode {
                configurationState = .maintenance
                return
            }
            
            // 4. 기능 플래그 업데이트
            await featureFlagManager.loadFeatureFlags()
            
            // 5. 모든 검사 통과
            configurationState = .ready
            
        } catch {
            print("Configuration check failed: \(error)")
            // 설정 로드 실패 시에도 앱 실행 허용 (기본값 사용)
            configurationState = .ready
        }
    }
    
    private func openAppStore() {
        Task {
            if let url = await AppVersionManager.shared.getAppStoreURL() {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
}

// MARK: - Configuration State

enum ConfigurationState {
    case loading
    case maintenance
    case updateRequired(AppVersionStatus)
    case ready
}

// MARK: - Loading Configuration View

struct LoadingConfigurationView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 로딩 애니메이션
            Image(systemName: "gear")
                .font(.system(size: 60))
                .foregroundColor(.brainyPrimary)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 2)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            
            // 로딩 메시지
            VStack(spacing: 12) {
                Text("앱 설정 확인 중")
                    .font(.brainyHeadline)
                    .foregroundColor(.brainyText)
                
                Text("잠시만 기다려주세요...")
                    .font(.brainyBody)
                    .foregroundColor(.brainyTextSecondary)
            }
            
            Spacer()
        }
        .background(Color.brainyBackground)
    }
}

// MARK: - Preview

#if DEBUG
struct AppConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        AppConfigurationView {
            Text("Main App Content")
        }
    }
}
#endif