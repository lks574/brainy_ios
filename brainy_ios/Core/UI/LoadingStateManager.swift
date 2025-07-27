import Foundation
import SwiftUI

/// 로딩 상태 관리자
@MainActor
class LoadingStateManager: ObservableObject {
    // MARK: - Properties
    @Published var loadingStates: [String: LoadingState] = [:]
    @Published var globalLoadingState: LoadingState = .idle
    
    // MARK: - Singleton
    static let shared = LoadingStateManager()
    
    private init() {}
    
    // MARK: - Loading State Management
    
    /// 로딩 시작
    func startLoading(for key: String, message: String = "로딩 중...", showProgress: Bool = false) {
        let loadingState = LoadingState(
            isLoading: true,
            message: message,
            progress: showProgress ? 0.0 : nil,
            startTime: Date()
        )
        
        loadingStates[key] = loadingState
        updateGlobalLoadingState()
    }
    
    /// 로딩 진행률 업데이트
    func updateProgress(for key: String, progress: Double, message: String? = nil) {
        guard var currentState = loadingStates[key], currentState.isLoading else { return }
        
        currentState.progress = min(max(progress, 0.0), 1.0)
        if let message = message {
            currentState.message = message
        }
        
        loadingStates[key] = currentState
    }
    
    /// 로딩 완료
    func stopLoading(for key: String) {
        loadingStates[key] = LoadingState(
            isLoading: false,
            message: "",
            progress: nil,
            startTime: Date()
        )
        
        updateGlobalLoadingState()
    }
    
    /// 모든 로딩 중지
    func stopAllLoading() {
        loadingStates.removeAll()
        globalLoadingState = .idle
    }
    
    /// 특정 키의 로딩 상태 확인
    func isLoading(for key: String) -> Bool {
        return loadingStates[key]?.isLoading ?? false
    }
    
    /// 전체 로딩 상태 확인
    func isAnyLoading() -> Bool {
        return loadingStates.values.contains { $0.isLoading }
    }
    
    /// 로딩 상태 가져오기
    func getLoadingState(for key: String) -> LoadingState? {
        return loadingStates[key]
    }
    
    // MARK: - Convenience Methods
    
    /// 네트워크 요청 로딩
    func startNetworkLoading(message: String = "서버와 통신 중...") {
        startLoading(for: "network", message: message)
    }
    
    func stopNetworkLoading() {
        stopLoading(for: "network")
    }
    
    /// 동기화 로딩
    func startSyncLoading(message: String = "데이터 동기화 중...") {
        startLoading(for: "sync", message: message, showProgress: true)
    }
    
    func updateSyncProgress(_ progress: Double, message: String? = nil) {
        updateProgress(for: "sync", progress: progress, message: message)
    }
    
    func stopSyncLoading() {
        stopLoading(for: "sync")
    }
    
    /// 인증 로딩
    func startAuthLoading(message: String = "로그인 중...") {
        startLoading(for: "auth", message: message)
    }
    
    func stopAuthLoading() {
        stopLoading(for: "auth")
    }
    
    /// 데이터 로딩
    func startDataLoading(message: String = "데이터 로드 중...") {
        startLoading(for: "data", message: message)
    }
    
    func stopDataLoading() {
        stopLoading(for: "data")
    }
    
    // MARK: - Private Methods
    
    /// 전체 로딩 상태 업데이트
    private func updateGlobalLoadingState() {
        let activeStates = loadingStates.values.filter { $0.isLoading }
        
        if activeStates.isEmpty {
            globalLoadingState = .idle
        } else if activeStates.count == 1 {
            globalLoadingState = activeStates.first!
        } else {
            // 여러 로딩이 동시에 진행 중인 경우
            let combinedMessage = "여러 작업 진행 중..."
            globalLoadingState = LoadingState(
                isLoading: true,
                message: combinedMessage,
                progress: nil,
                startTime: activeStates.map { $0.startTime }.min() ?? Date()
            )
        }
    }
}

// MARK: - Loading State

struct LoadingState {
    var isLoading: Bool
    var message: String
    var progress: Double? // nil이면 무한 로딩, 값이 있으면 진행률 표시
    var startTime: Date
    
    static let idle = LoadingState(
        isLoading: false,
        message: "",
        progress: nil,
        startTime: Date()
    )
    
    var duration: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    var isLongRunning: Bool {
        return duration > 10.0 // 10초 이상
    }
    
    var progressPercentage: Int {
        guard let progress = progress else { return 0 }
        return Int(progress * 100)
    }
}

// MARK: - Loading View Components

struct LoadingOverlay: View {
    let loadingState: LoadingState
    let allowsInteraction: Bool
    
    init(loadingState: LoadingState, allowsInteraction: Bool = false) {
        self.loadingState = loadingState
        self.allowsInteraction = allowsInteraction
    }
    
    var body: some View {
        ZStack {
            // 배경
            if !allowsInteraction {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            }
            
            // 로딩 컨텐츠
            VStack(spacing: 16) {
                // 프로그레스 인디케이터
                if let progress = loadingState.progress {
                    // 진행률 표시
                    VStack(spacing: 12) {
                        CircularProgressView(progress: progress)
                            .frame(width: 60, height: 60)
                        
                        Text("\(loadingState.progressPercentage)%")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                    }
                } else {
                    // 무한 로딩
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.brainyPrimary)
                }
                
                // 로딩 메시지
                Text(loadingState.message)
                    .font(.brainyBody)
                    .foregroundColor(.brainyText)
                    .multilineTextAlignment(.center)
                
                // 장시간 로딩 시 추가 정보
                if loadingState.isLongRunning {
                    Text("시간이 오래 걸리고 있습니다...")
                        .font(.brainyCaption)
                        .foregroundColor(.brainyTextSecondary)
                }
            }
            .padding(24)
            .background(Color.brainyBackground)
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.brainySecondary.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.brainyPrimary,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}

struct InlineLoadingView: View {
    let message: String
    let showProgress: Bool
    let progress: Double?
    
    init(message: String = "로딩 중...", showProgress: Bool = false, progress: Double? = nil) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if showProgress, let progress = progress {
                CircularProgressView(progress: progress)
                    .frame(width: 20, height: 20)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.brainyPrimary)
            }
            
            Text(message)
                .font(.brainyBody)
                .foregroundColor(.brainyTextSecondary)
            
            if showProgress, let progress = progress {
                Text("\(Int(progress * 100))%")
                    .font(.brainyCaption)
                    .foregroundColor(.brainyTextSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.brainySurface)
        .cornerRadius(8)
    }
}

// MARK: - View Extensions

extension View {
    /// 로딩 오버레이 추가
    func loadingOverlay(
        isLoading: Bool,
        message: String = "로딩 중...",
        progress: Double? = nil,
        allowsInteraction: Bool = false
    ) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    LoadingOverlay(
                        loadingState: LoadingState(
                            isLoading: true,
                            message: message,
                            progress: progress,
                            startTime: Date()
                        ),
                        allowsInteraction: allowsInteraction
                    )
                }
            }
        )
    }
    
    /// 로딩 상태 관리자와 연동된 로딩 오버레이
    func loadingOverlay(for key: String, allowsInteraction: Bool = false) -> some View {
        self.overlay(
            LoadingStateObserver(key: key, allowsInteraction: allowsInteraction)
        )
    }
}

// MARK: - Loading State Observer

struct LoadingStateObserver: View {
    @StateObject private var loadingManager = LoadingStateManager.shared
    let key: String
    let allowsInteraction: Bool
    
    var body: some View {
        Group {
            if let loadingState = loadingManager.getLoadingState(for: key),
               loadingState.isLoading {
                LoadingOverlay(
                    loadingState: loadingState,
                    allowsInteraction: allowsInteraction
                )
            }
        }
    }
}