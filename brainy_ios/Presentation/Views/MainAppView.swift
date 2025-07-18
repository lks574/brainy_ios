import SwiftUI
import SwiftData

/// 메인 앱 화면을 관리하는 뷰
struct MainAppView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            QuizModeSelectionView(coordinator: coordinator)
                .navigationDestination(for: AppCoordinator.MainScreen.self) { screen in
                    destinationView(for: screen)
                }
        }
        .tint(.brainyPrimary)
    }
    
    // MARK: - Navigation Destinations
    @ViewBuilder
    private func destinationView(for screen: AppCoordinator.MainScreen) -> some View {
        switch screen {
        case .quizModeSelection:
            QuizModeSelectionView(coordinator: coordinator)
            
        case .categorySelection(let quizMode):
            CategorySelectionView(coordinator: coordinator, quizMode: quizMode)
            
        case .quizPlay(let category, let mode):
            QuizPlayView(coordinator: coordinator, category: category, mode: mode)
            
        case .quizResult(let session):
            QuizResultView(coordinator: coordinator, session: session)
            
        case .history:
            HistoryView(coordinator: coordinator)
            
        case .historyDetail(let session):
            HistoryDetailView(coordinator: coordinator, session: session)
            
        case .profile:
            ProfileView(coordinator: coordinator, authViewModel: authViewModel)
        }
    }
}


