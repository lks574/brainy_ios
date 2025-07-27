import SwiftUI
import Network

/// 오프라인 상태 표시 및 관리
@MainActor
class OfflineIndicatorManager: ObservableObject {
    // MARK: - Properties
    @Published var isOffline = false
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var showOfflineIndicator = false
    
    private let networkErrorHandler = NetworkErrorHandler.shared
    
    // MARK: - Singleton
    static let shared = OfflineIndicatorManager()
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        // 네트워크 상태 변경 알림 구독
        NotificationCenter.default.addObserver(
            forName: .networkStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let isConnected = userInfo["isConnected"] as? Bool else { return }
            
            let wasOffline = self.isOffline
            self.isOffline = !isConnected
            
            if let connectionTypeRaw = userInfo["connectionType"] as? String {
                self.connectionType = NWInterface.InterfaceType(rawValue: connectionTypeRaw)
            }
            
            // 오프라인 상태 변경 시 처리
            self.handleNetworkStatusChange(wasOffline: wasOffline, isNowOffline: !isConnected)
        }
        
        // 초기 네트워크 상태 확인
        Task {
            let status = await networkErrorHandler.getCurrentNetworkStatus()
            self.isOffline = !status.isConnected
            self.connectionType = status.connectionType
            self.showOfflineIndicator = !status.isConnected
        }
    }
    
    /// 네트워크 상태 변경 처리
    private func handleNetworkStatusChange(wasOffline: Bool, isNowOffline: Bool) {
        showOfflineIndicator = isNowOffline
        
        if wasOffline && !isNowOffline {
            // 온라인으로 복원됨
            ToastManager.shared.showNetworkRestored()
            
            // 대기 중인 동기화가 있는지 확인
            NotificationCenter.default.post(name: .networkRestored, object: nil)
            
        } else if !wasOffline && isNowOffline {
            // 오프라인으로 변경됨
            ToastManager.shared.showNetworkError()
        }
    }
    
    // MARK: - Public Methods
    
    /// 수동으로 네트워크 상태 확인
    func checkNetworkStatus() async {
        let status = await networkErrorHandler.getCurrentNetworkStatus()
        isOffline = !status.isConnected
        connectionType = status.connectionType
        showOfflineIndicator = !status.isConnected
    }
    
    /// 오프라인 모드 안내 표시
    func showOfflineGuidance() {
        ToastManager.shared.showInfo("오프라인 모드에서도 퀴즈를 계속 플레이할 수 있습니다")
    }
}

// MARK: - Offline Indicator View

struct OfflineIndicator: View {
    @StateObject private var offlineManager = OfflineIndicatorManager.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            if offlineManager.showOfflineIndicator {
                offlineIndicatorBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: offlineManager.showOfflineIndicator)
    }
    
    private var offlineIndicatorBar: some View {
        VStack(spacing: 0) {
            // 기본 오프라인 바
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)
                    .font(.caption)
                
                Text("오프라인")
                    .font(.brainyCaption)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange)
            
            // 확장된 정보
            if isExpanded {
                offlineDetailsView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var offlineDetailsView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("오프라인 모드")
                        .font(.brainyBody)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                    
                    Text("인터넷 연결 없이도 퀴즈를 계속 플레이할 수 있습니다")
                        .font(.brainyCaption)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            // 오프라인 기능 안내
            VStack(spacing: 8) {
                OfflineFeatureRow(
                    icon: "play.circle",
                    title: "퀴즈 플레이",
                    description: "모든 퀴즈 모드 사용 가능"
                )
                
                OfflineFeatureRow(
                    icon: "chart.bar",
                    title: "통계 확인",
                    description: "로컬 통계 실시간 계산"
                )
                
                OfflineFeatureRow(
                    icon: "clock",
                    title: "히스토리",
                    description: "과거 퀴즈 기록 조회"
                )
                
                OfflineFeatureRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "자동 동기화",
                    description: "연결 시 자동으로 동기화됩니다",
                    isDisabled: true
                )
            }
            
            // 네트워크 설정 버튼
            Button(action: {
                openNetworkSettings()
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("네트워크 설정")
                }
                .font(.brainyCaption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.9))
    }
    
    private func openNetworkSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Offline Feature Row

struct OfflineFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isDisabled: Bool
    
    init(icon: String, title: String, description: String, isDisabled: Bool = false) {
        self.icon = icon
        self.title = title
        self.description = description
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(isDisabled ? .white.opacity(0.5) : .white)
                .font(.caption)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.brainyCaption)
                    .foregroundColor(isDisabled ? .white.opacity(0.5) : .white)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(isDisabled ? .white.opacity(0.4) : .white.opacity(0.8))
            }
            
            Spacer()
            
            if isDisabled {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.caption2)
            } else {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.white)
                    .font(.caption2)
            }
        }
    }
}

// MARK: - Offline Banner View

struct OfflineBanner: View {
    let message: String
    let showRetryButton: Bool
    let onRetry: (() -> Void)?
    
    init(
        message: String = "오프라인 상태입니다",
        showRetryButton: Bool = true,
        onRetry: (() -> Void)? = nil
    ) {
        self.message = message
        self.showRetryButton = showRetryButton
        self.onRetry = onRetry
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("오프라인 모드")
                    .font(.brainyBody)
                    .foregroundColor(.brainyText)
                    .fontWeight(.medium)
                
                Text(message)
                    .font(.brainyCaption)
                    .foregroundColor(.brainyTextSecondary)
            }
            
            Spacer()
            
            if showRetryButton {
                Button("재시도") {
                    onRetry?()
                }
                .font(.brainyCaption)
                .foregroundColor(.brainyPrimary)
                .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

// MARK: - View Extensions

extension View {
    /// 오프라인 인디케이터 추가
    func withOfflineIndicator() -> some View {
        VStack(spacing: 0) {
            OfflineIndicator()
            self
        }
    }
    
    /// 오프라인 상태에서 배너 표시
    func offlineBanner(
        message: String = "일부 기능이 제한될 수 있습니다",
        showRetryButton: Bool = true,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 12) {
            OfflineBanner(
                message: message,
                showRetryButton: showRetryButton,
                onRetry: onRetry
            )
            
            self
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkRestored = Notification.Name("networkRestored")
}