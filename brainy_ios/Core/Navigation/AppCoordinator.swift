import SwiftUI
import Combine

/// 앱의 전체 네비게이션을 관리하는 코디네이터
@MainActor
class AppCoordinator: ObservableObject {
    
    // MARK: - Navigation State
    enum AppState {
        case loading
        case authentication
        case main
    }
    
    enum MainScreen {
        case quizModeSelection
        case categorySelection(quizMode: QuizMode)
        case quizPlay(category: QuizCategory, mode: QuizMode)
        case quizResult(session: QuizSession)
        case history
        case historyDetail(session: QuizSession)
        case profile
    }
    
    // MARK: - Properties
    @Published var appState: AppState = .loading
    @Published var currentMainScreen: MainScreen = .quizModeSelection
    @Published var navigationPath = NavigationPath()
    
    // MARK: - Navigation Methods
    
    /// 앱 상태를 변경합니다
    func setAppState(_ state: AppState) {
        withAnimation(.easeInOut(duration: 0.3)) {
            appState = state
        }
    }
    
    /// 메인 화면으로 이동합니다
    func navigateToMain() {
        setAppState(.main)
        currentMainScreen = .quizModeSelection
        navigationPath = NavigationPath()
    }
    
    /// 인증 화면으로 이동합니다
    func navigateToAuthentication() {
        setAppState(.authentication)
        navigationPath = NavigationPath()
    }
    
    /// 특정 메인 화면으로 이동합니다
    func navigateToMainScreen(_ screen: MainScreen) {
        currentMainScreen = screen
        navigationPath.append(screen)
    }
    
    /// 이전 화면으로 돌아갑니다
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    /// 루트 화면으로 돌아갑니다
    func navigateToRoot() {
        navigationPath = NavigationPath()
        currentMainScreen = .quizModeSelection
    }
    
    /// 퀴즈 모드 선택 화면으로 이동합니다
    func navigateToQuizModeSelection() {
        navigateToRoot()
    }
    
    /// 카테고리 선택 화면으로 이동합니다
    func navigateToCategorySelection(quizMode: QuizMode) {
        navigateToMainScreen(.categorySelection(quizMode: quizMode))
    }
    
    /// 퀴즈 플레이 화면으로 이동합니다
    func navigateToQuizPlay(category: QuizCategory, mode: QuizMode) {
        navigateToMainScreen(.quizPlay(category: category, mode: mode))
    }
    
    /// 퀴즈 결과 화면으로 이동합니다
    func navigateToQuizResult(session: QuizSession) {
        navigateToMainScreen(.quizResult(session: session))
    }
    
    /// 히스토리 화면으로 이동합니다
    func navigateToHistory() {
        navigateToMainScreen(.history)
    }
    
    /// 히스토리 상세 화면으로 이동합니다
    func navigateToHistoryDetail(session: QuizSession) {
        navigateToMainScreen(.historyDetail(session: session))
    }
    
    /// 프로필 화면으로 이동합니다
    func navigateToProfile() {
        navigateToMainScreen(.profile)
    }
}

// MARK: - MainScreen Hashable Conformance
extension AppCoordinator.MainScreen: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .quizModeSelection:
            hasher.combine("quizModeSelection")
        case .categorySelection(let quizMode):
            hasher.combine("categorySelection")
            hasher.combine(quizMode)
        case .quizPlay(let category, let mode):
            hasher.combine("quizPlay")
            hasher.combine(category)
            hasher.combine(mode)
        case .quizResult(let session):
            hasher.combine("quizResult")
            hasher.combine(session.id)
        case .history:
            hasher.combine("history")
        case .historyDetail(let session):
            hasher.combine("historyDetail")
            hasher.combine(session.id)
        case .profile:
            hasher.combine("profile")
        }
    }
    
    static func == (lhs: AppCoordinator.MainScreen, rhs: AppCoordinator.MainScreen) -> Bool {
        switch (lhs, rhs) {
        case (.quizModeSelection, .quizModeSelection):
            return true
        case (.categorySelection(let lhsMode), .categorySelection(let rhsMode)):
            return lhsMode == rhsMode
        case (.quizPlay(let lhsCategory, let lhsMode), .quizPlay(let rhsCategory, let rhsMode)):
            return lhsCategory == rhsCategory && lhsMode == rhsMode
        case (.quizResult(let lhsSession), .quizResult(let rhsSession)):
            return lhsSession.id == rhsSession.id
        case (.history, .history):
            return true
        case (.historyDetail(let lhsSession), .historyDetail(let rhsSession)):
            return lhsSession.id == rhsSession.id
        case (.profile, .profile):
            return true
        default:
            return false
        }
    }
}