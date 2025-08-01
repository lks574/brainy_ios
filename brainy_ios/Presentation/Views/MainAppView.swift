import SwiftUI
import SwiftData

/// 메인 앱 화면을 관리하는 뷰
struct MainAppView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var authViewModel: AuthenticationViewModel
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    
    // SyncViewModel을 State로 관리
    @State private var syncViewModel: SyncViewModel?
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            QuizModeSelectionView(coordinator: coordinator)
                .navigationDestination(for: AppCoordinator.MainScreen.self) { screen in
                    destinationView(for: screen)
                }
                .navigationBarBackButtonHidden(true)
        }
        .tint(.brainyPrimary)
        .disabled(coordinator.isNavigationInProgress)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .onAppear {
            if syncViewModel == nil {
                let localDataSource = LocalDataSource(modelContext: modelContext)
                let networkService = NetworkService()
                let syncManager = SyncManager(networkService: networkService, localDataSource: localDataSource)
                syncViewModel = SyncViewModel(syncManager: syncManager, localDataSource: localDataSource)
            }
        }
    }
    
    // MARK: - Navigation Destinations
    @ViewBuilder
    private func destinationView(for screen: AppCoordinator.MainScreen) -> some View {
        switch screen {
        case .quizModeSelection:
            QuizModeSelectionView(coordinator: coordinator)
            
        case .categorySelection(let quizMode, let quizType):
            CategorySelectionView(coordinator: coordinator, quizMode: quizMode, quizType: quizType)
            
        case .quizPlay(let category, let mode, let type):
          QuizPlayView(coordinator: coordinator, category: category, mode: mode, quizType: type)

        case .quizResult(let session):
            QuizResultView(coordinator: coordinator, session: session)
            
        case .history:
            HistoryView(coordinator: coordinator)
            
        case .historyDetail(let session):
            HistoryDetailView(coordinator: coordinator, session: session)
            
        case .profile:
            if let syncViewModel = syncViewModel {
                ProfileView(coordinator: coordinator, authViewModel: authViewModel, settingsManager: settingsManager, syncViewModel: syncViewModel)
            } else {
                // SyncViewModel이 아직 초기화되지 않은 경우 로딩 표시
                VStack {
                    ProgressView()
                    Text("로딩 중...")
                        .font(.brainyBody)
                        .foregroundColor(.brainyTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.brainyBackground)
            }
        }
    }
    
    // MARK: - Scene Phase Handling
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // 앱이 활성화될 때 필요한 처리
            break
        case .inactive:
            // 앱이 비활성화될 때 필요한 처리
            break
        case .background:
            // 앱이 백그라운드로 진입할 때 필요한 처리
            break
        @unknown default:
            break
        }
    }
}


