import SwiftUI

/// 프로필 화면 (임시 구현)
struct ProfileView: View {
    @State private var coordinator: AppCoordinator
    @State private var authViewModel: AuthenticationViewModel
    
    init(coordinator: AppCoordinator, authViewModel: AuthenticationViewModel) {
        self._coordinator = State(initialValue: coordinator)
        self._authViewModel = State(initialValue: authViewModel)
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // 헤더
            headerSection
            
            // 사용자 정보
            userInfoSection
            
            // 설정 옵션들
            settingsSection
            
            Spacer()
            
            // 로그아웃 버튼
            logoutSection
            
            // 뒤로 가기 버튼
            BrainyButton("뒤로 가기", style: .secondary) {
                coordinator.navigateBack()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brainyBackground)
        .navigationBarHidden(true)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("👤")
                .font(.system(size: 60))
            
            Text("프로필")
                .font(.brainyTitle)
                .foregroundColor(.brainyText)
        }
    }
    
    // MARK: - User Info Section
    private var userInfoSection: some View {
        VStack(spacing: 12) {
            Text(authViewModel.userDisplayName)
                .font(.brainyHeadlineMedium)
                .foregroundColor(.brainyText)
            
            if !authViewModel.userEmail.isEmpty {
                Text(authViewModel.userEmail)
                    .font(.brainyBody)
                    .foregroundColor(.brainyTextSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.brainyCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 12) {
            Text("설정")
                .font(.brainyHeadlineMedium)
                .foregroundColor(.brainyText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                SettingRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "데이터 동기화",
                    subtitle: "진행 상황을 서버에 저장"
                ) {
                    // TODO: Task 14에서 구현
                }
                
                SettingRow(
                    icon: "moon.circle",
                    title: "다크모드",
                    subtitle: "어두운 테마 사용"
                ) {
                    // TODO: Task 13에서 구현
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
}

// MARK: - Setting Row
private struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
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
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.brainyTextSecondary)
            }
            .padding(.vertical, 8)
        }
    }
}
