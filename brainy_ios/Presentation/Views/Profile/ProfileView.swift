import SwiftUI

/// 프로필 및 설정 화면
struct ProfileView: View {
    @State private var coordinator: AppCoordinator
    @State private var authViewModel: AuthenticationViewModel
    @ObservedObject private var settingsManager: SettingsManager
    @State private var showingSyncAlert = false
    @State private var syncMessage = ""
    @State private var isSyncing = false
    
    init(coordinator: AppCoordinator, authViewModel: AuthenticationViewModel, settingsManager: SettingsManager) {
        self._coordinator = State(initialValue: coordinator)
        self._authViewModel = State(initialValue: authViewModel)
        self.settingsManager = settingsManager
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 헤더
                headerSection
                
                // 사용자 정보
                userInfoSection
                
                // 설정 옵션들
                settingsSection
                
                // 앱 정보
                appInfoSection
                
                // 로그아웃 버튼
                logoutSection
                
                // 뒤로 가기 버튼
                BrainyButton("뒤로 가기", style: .secondary) {
                    coordinator.navigateBack()
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brainyBackground)
        .navigationBarHidden(true)
        .preferredColorScheme(settingsManager.colorScheme)
        .alert("동기화", isPresented: $showingSyncAlert) {
            Button("확인") { }
        } message: {
            Text(syncMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 프로필 아이콘
            ZStack {
                Circle()
                    .fill(Color.brainyPrimary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.brainyPrimary)
            }
            
            Text("프로필")
                .font(.brainyTitle)
                .foregroundColor(.brainyText)
        }
    }
    
    // MARK: - User Info Section
    private var userInfoSection: some View {
        VStack(spacing: 16) {
            // 사용자 기본 정보
            VStack(spacing: 8) {
                Text(authViewModel.userDisplayName)
                    .font(.brainyHeadlineMedium)
                    .foregroundColor(.brainyText)
                
                if !authViewModel.userEmail.isEmpty {
                    Text(authViewModel.userEmail)
                        .font(.brainyBody)
                        .foregroundColor(.brainyTextSecondary)
                }
                
                // 인증 제공자 표시
                HStack(spacing: 8) {
                    Image(systemName: authProviderIcon)
                        .font(.system(size: 14))
                        .foregroundColor(.brainyTextSecondary)
                    
                    Text(authProviderText)
                        .font(.brainyCaption)
                        .foregroundColor(.brainyTextSecondary)
                }
            }
            
            // 가입일 정보
            if let user = authViewModel.currentUser {
                VStack(spacing: 4) {
                    Text("가입일")
                        .font(.brainyCaption)
                        .foregroundColor(.brainyTextSecondary)
                    
                    Text(formatDate(user.createdAt))
                        .font(.brainyBodySmall)
                        .foregroundColor(.brainyText)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.brainyCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 16) {
            // 섹션 헤더
            HStack {
                Text("설정")
                    .font(.brainyHeadlineMedium)
                    .foregroundColor(.brainyText)
                Spacer()
            }
            
            VStack(spacing: 0) {
                // 데이터 동기화
                SettingRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "데이터 동기화",
                    subtitle: settingsManager.lastSyncDateString,
                    showChevron: true,
                    isLoading: isSyncing
                ) {
                    performSync()
                }
                
                Divider()
                    .padding(.leading, 44)
                
                // 다크모드 토글
                SettingToggleRow(
                    icon: "moon.circle",
                    title: "다크모드",
                    subtitle: "어두운 테마 사용",
                    isOn: $settingsManager.isDarkModeEnabled
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // 알림 설정
                SettingToggleRow(
                    icon: "bell.circle",
                    title: "알림",
                    subtitle: "퀴즈 알림 받기",
                    isOn: $settingsManager.isNotificationEnabled
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // 사운드 설정
                SettingToggleRow(
                    icon: "speaker.wave.2.circle",
                    title: "사운드",
                    subtitle: "효과음 및 배경음",
                    isOn: $settingsManager.isSoundEnabled
                )
            }
            .padding(16)
            .background(Color.brainyCardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("앱 정보")
                    .font(.brainyHeadlineMedium)
                    .foregroundColor(.brainyText)
                Spacer()
            }
            
            VStack(spacing: 0) {
                SettingRow(
                    icon: "info.circle",
                    title: "버전",
                    subtitle: appVersion,
                    showChevron: false
                ) { }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingRow(
                    icon: "questionmark.circle",
                    title: "도움말",
                    subtitle: "사용법 및 FAQ",
                    showChevron: true
                ) {
                    // TODO: 도움말 화면으로 이동
                }
                
                Divider()
                    .padding(.leading, 44)
                
                SettingRow(
                    icon: "envelope.circle",
                    title: "문의하기",
                    subtitle: "개발자에게 연락",
                    showChevron: true
                ) {
                    // TODO: 문의 화면으로 이동
                }
            }
            .padding(16)
            .background(Color.brainyCardBackground)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Logout Section
    private var logoutSection: some View {
        BrainyButton(
            authViewModel.isLoading ? "로그아웃 중..." : "로그아웃",
            style: .secondary,
            isEnabled: !authViewModel.isLoading
        ) {
            Task {
                await authViewModel.signOut()
                if !authViewModel.isAuthenticated {
                    coordinator.navigateToAuthentication()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var authProviderIcon: String {
        guard let user = authViewModel.currentUser else { return "person.circle" }
        
        switch user.authProvider {
        case .email:
            return "envelope.circle"
        case .google:
            return "globe.circle"
        case .apple:
            return "applelogo"
        }
    }
    
    private var authProviderText: String {
        guard let user = authViewModel.currentUser else { return "알 수 없음" }
        
        switch user.authProvider {
        case .email:
            return "이메일로 가입"
        case .google:
            return "Google로 가입"
        case .apple:
            return "Apple로 가입"
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private func performSync() {
        guard !isSyncing else { return }
        
        isSyncing = true
        
        // TODO: Task 14에서 실제 동기화 로직 구현
        // 현재는 시뮬레이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            settingsManager.lastSyncDate = Date()
            isSyncing = false
            syncMessage = "데이터 동기화가 완료되었습니다."
            showingSyncAlert = true
        }
    }
}

// MARK: - Setting Row Components

private struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let showChevron: Bool
    let isLoading: Bool
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        showChevron: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.brainyPrimary)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.brainyBody)
                        .foregroundColor(.brainyText)
                    
                    Text(subtitle)
                        .font(.brainyCaption)
                        .foregroundColor(.brainyTextSecondary)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.brainyTextSecondary)
                }
            }
            .padding(.vertical, 12)
        }
        .disabled(isLoading)
    }
}

private struct SettingToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.brainyPrimary)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.brainyBody)
                    .foregroundColor(.brainyText)
                
                Text(subtitle)
                    .font(.brainyCaption)
                    .foregroundColor(.brainyTextSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.brainyPrimary)
        }
        .padding(.vertical, 12)
    }
}
