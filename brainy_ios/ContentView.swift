//
//  ContentView.swift
//  brainy_ios
//
//  Created by KyungSeok Lee on 7/17/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var authViewModel: AuthenticationViewModel
    @State private var isLoading = true
    
    init() {
        // 의존성 주입 설정
        let localDataSource = LocalDataSource(modelContext: ModelContainer.shared.mainContext)
        let authRepository = AuthenticationRepositoryImpl(localDataSource: localDataSource)
        let authUseCase = AuthenticationUseCase(repository: authRepository)
        self._authViewModel = State(initialValue: AuthenticationViewModel(authenticationUseCase: authUseCase))
    }
    
    var body: some View {
        Group {
            if isLoading {
                // 로딩 화면
                loadingView
            } else if authViewModel.isAuthenticated {
                // 메인 앱 화면 (임시)
                mainAppView
            } else {
                // 로그인 화면
                SignInView(viewModel: authViewModel)
            }
        }
        .task {
            await checkAuthenticationStatus()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Text("🧠")
                .font(.system(size: 80))
            
            Text("Brainy Quiz")
                .font(.brainyTitle)
                .foregroundColor(.brainyText)
            
            ProgressView()
                .scaleEffect(1.2)
                .tint(.brainyPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brainyBackground)
    }
    
    // MARK: - Main App View (임시)
    private var mainAppView: some View {
        NavigationView {
            VStack(spacing: 32) {
                Text("🧠")
                    .font(.system(size: 80))
                
                Text("환영합니다!")
                    .font(.brainyTitle)
                    .foregroundColor(.brainyText)
                
                Text("안녕하세요, \(authViewModel.userDisplayName)님")
                    .font(.brainyBody)
                    .foregroundColor(.brainyTextSecondary)
                
                if !authViewModel.userEmail.isEmpty {
                    Text(authViewModel.userEmail)
                        .font(.brainyCaption)
                        .foregroundColor(.brainyTextSecondary)
                }
                
                Spacer()
                
                // 로그아웃 버튼
                BrainyButton(
                    "로그아웃",
                    style: .secondary,
                    isEnabled: !authViewModel.isLoading
                ) {
                    Task {
                        await authViewModel.signOut()
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.brainyBackground)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Helper Methods
    private func checkAuthenticationStatus() async {
        // 인증 상태 확인
        await authViewModel.checkCurrentUser()
        
        // 로딩 완료
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
