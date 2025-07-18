//
//  ContentView.swift
//  brainy_ios
//
//  Created by KyungSeok Lee on 7/17/25.
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @StateObject private var authViewModel: AuthenticationViewModel
    @StateObject private var coordinator = AppCoordinator()
    @State private var isInitializing = true
    
    init() {
        // 의존성 주입 설정
        let localDataSource = LocalDataSource(modelContext: ModelContainer.shared.mainContext)
        let authRepository = AuthenticationRepositoryImpl(localDataSource: localDataSource)
        let authUseCase = AuthenticationUseCase(repository: authRepository)
        self._authViewModel = StateObject(wrappedValue: AuthenticationViewModel(authenticationUseCase: authUseCase))
    }
    
    var body: some View {
        Group {
            switch coordinator.appState {
            case .loading:
                loadingView
            case .authentication:
                SignInView(viewModel: authViewModel)
                    .onReceive(authViewModel.$isAuthenticated) { isAuthenticated in
                        if isAuthenticated {
                            coordinator.navigateToMain()
                        }
                    }
            case .main:
                MainAppView(coordinator: coordinator, authViewModel: authViewModel)
                    .onReceive(authViewModel.$isAuthenticated) { isAuthenticated in
                        if !isAuthenticated {
                            coordinator.navigateToAuthentication()
                        }
                    }
            }
        }
        .task {
            await initializeApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await handleAppWillEnterForeground()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            handleAppDidEnterBackground()
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
    

    
    // MARK: - App Lifecycle Methods
    
    /// 앱 초기화
    private func initializeApp() async {
        coordinator.setAppState(.loading)
        
        // 인증 상태 확인
        await authViewModel.checkCurrentUser()
        
        // 인증 상태에 따라 화면 전환
        if authViewModel.isAuthenticated {
            coordinator.navigateToMain()
        } else {
            coordinator.navigateToAuthentication()
        }
        
        isInitializing = false
    }
    
    /// 앱이 포그라운드로 진입할 때 처리
    private func handleAppWillEnterForeground() async {
        // 인증 상태 재확인
        await authViewModel.checkCurrentUser()
        
        // 인증이 해제된 경우 로그인 화면으로 이동
        if !authViewModel.isAuthenticated && coordinator.appState == .main {
            coordinator.navigateToAuthentication()
        }
    }
    
    /// 앱이 백그라운드로 진입할 때 처리
    private func handleAppDidEnterBackground() {
        // 필요한 경우 데이터 저장 등의 작업 수행
        // 현재는 특별한 처리 없음
    }
}
