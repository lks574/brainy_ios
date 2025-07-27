//
//  ContentView.swift
//  brainy_ios
//
//  Created by KyungSeok Lee on 7/17/25.
//

import SwiftUI
import SwiftData
import Combine
import UIKit

struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var settingsManager = SettingsManager()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var isInitializing = true
    @State private var lastActiveTime: Date?
    
    var body: some View {
        AppConfigurationView {
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
                    MainAppView(coordinator: coordinator, authViewModel: authViewModel, settingsManager: settingsManager)
                        .onReceive(authViewModel.$isAuthenticated) { isAuthenticated in
                            if !isAuthenticated {
                                coordinator.navigateToAuthentication()
                            }
                        }
                }
            }
            .preferredColorScheme(settingsManager.colorScheme)
            .task {
                await initializeApp()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                Task {
                    await handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task {
                    await handleAppWillEnterForeground()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                handleAppDidEnterBackground()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    await handleAppDidBecomeActive()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                handleAppWillResignActive()
            }
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
        
        // AuthenticationViewModel 의존성 설정
        authViewModel.setupDependencies(modelContext: modelContext)
        
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
    
    /// 앱이 활성화될 때 처리
    private func handleAppDidBecomeActive() async {
        // 앱이 활성화될 때 필요한 작업 수행
        // 예: 네트워크 상태 확인, 데이터 동기화 등
        if !isInitializing && coordinator.appState == .main {
            // 메인 화면에서 필요한 데이터 새로고침 등
        }
    }
    
    /// 앱이 비활성화될 때 처리
    private func handleAppWillResignActive() {
        // 앱이 비활성화될 때 필요한 작업 수행
        // 예: 타이머 일시정지, 중요한 데이터 저장 등
        lastActiveTime = Date()
    }
    
    /// Scene Phase 변경 처리
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) async {
        switch newPhase {
        case .active:
            await handleSceneDidBecomeActive()
        case .inactive:
            handleSceneWillResignActive()
        case .background:
            handleSceneDidEnterBackground()
        @unknown default:
            break
        }
    }
    
    /// Scene이 활성화될 때 처리
    private func handleSceneDidBecomeActive() async {
        guard !isInitializing else { return }
        
        // 장시간 백그라운드에 있었다면 인증 상태 재확인
        if let lastActive = lastActiveTime {
            let timeInterval = Date().timeIntervalSince(lastActive)
            // 30분 이상 백그라운드에 있었다면 인증 상태 재확인
            if timeInterval > 1800 {
                await authViewModel.checkCurrentUser()
                
                // 인증이 해제된 경우 로그인 화면으로 이동
                if !authViewModel.isAuthenticated && coordinator.appState == .main {
                    coordinator.navigateToAuthentication()
                }
            }
        }
        
        // 메인 화면에서 필요한 데이터 새로고침
        if coordinator.appState == .main {
            // TODO: 필요시 퀴즈 데이터 버전 확인 및 업데이트
        }
    }
    
    /// Scene이 비활성화될 때 처리
    private func handleSceneWillResignActive() {
        lastActiveTime = Date()
        
        // 진행 중인 퀴즈가 있다면 일시정지 처리
        // TODO: 퀴즈 진행 상태 저장
    }
    
    /// Scene이 백그라운드로 진입할 때 처리
    private func handleSceneDidEnterBackground() {
        // 중요한 데이터 저장
        // TODO: 필요시 진행 상황 저장
        
        // 메모리 정리
        // TODO: 불필요한 리소스 해제
    }
}
