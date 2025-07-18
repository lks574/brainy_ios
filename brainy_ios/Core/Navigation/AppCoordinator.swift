import SwiftUI
import Combine

/// 앱의 전체 네비게이션을 관리하는 코디네이터
@MainActor
class AppCoordinator: ObservableObject {
    
    // MARK: - Navigation State
    enum AppState: Equatable {
        case loading
        case authentication
        case main
        
        static func == (lhs: AppState, rhs: AppState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading), (.authentication, .authentication), (.main, .main):
                return true
            default:
                return false
            }
        }
    }
    
    enum MainScreen {
        case quizModeSelection
        case categorySelection(quizMode: QuizMode, quizType: QuizType)
        case quizPlay(category: QuizCategory, mode: QuizMode, type: QuizType)
        case quizResult(session: QuizSession)
        case history
        case historyDetail(session: QuizSession)
        case profile
    }
    
    // MARK: - Properties
    @Published var appState: AppState = .loading
    @Published var currentMainScreen: MainScreen = .quizModeSelection
    @Published var navigationPath = NavigationPath()
    @Published var isNavigationInProgress = false
    
    // Navigation history for better back navigation
    private var navigationHistory: [MainScreen] = []
    private let maxHistorySize = 10
    
    // MARK: - Navigation Methods
    
    /// 앱 상태를 변경합니다
    func setAppState(_ state: AppState) {
        guard appState != state else { return }
        
        isNavigationInProgress = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            appState = state
        }
        
        // 상태 변경 완료 후 플래그 리셋
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isNavigationInProgress = false
        }
        
        // 상태 변경 시 히스토리 초기화
        if state == .authentication {
            clearNavigationHistory()
        }
    }
    
    /// 메인 화면으로 이동합니다
    func navigateToMain() {
        setAppState(.main)
        currentMainScreen = .quizModeSelection
        navigationPath = NavigationPath()
        clearNavigationHistory()
        addToHistory(.quizModeSelection)
    }
    
    /// 인증 화면으로 이동합니다
    func navigateToAuthentication() {
        setAppState(.authentication)
        navigationPath = NavigationPath()
        clearNavigationHistory()
    }
    
    /// 특정 메인 화면으로 이동합니다
    func navigateToMainScreen(_ screen: MainScreen) {
        guard !isNavigationInProgress else { return }
        
        currentMainScreen = screen
        navigationPath.append(screen)
        addToHistory(screen)
    }
    
    /// 이전 화면으로 돌아갑니다
    func navigateBack() {
        guard !isNavigationInProgress else { return }
        
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
            removeFromHistory()
        }
    }
    
    /// 루트 화면으로 돌아갑니다
    func navigateToRoot() {
        guard !isNavigationInProgress else { return }
        
        navigationPath = NavigationPath()
        currentMainScreen = .quizModeSelection
        clearNavigationHistory()
        addToHistory(.quizModeSelection)
    }
    
    /// 퀴즈 모드 선택 화면으로 이동합니다
    func navigateToQuizModeSelection() {
        navigateToRoot()
    }
    
    /// 카테고리 선택 화면으로 이동합니다
    func navigateToCategorySelection(quizMode: QuizMode, quizType: QuizType) {
        navigateToMainScreen(.categorySelection(quizMode: quizMode, quizType: quizType))
    }
    
    /// 퀴즈 플레이 화면으로 이동합니다
    func navigateToQuizPlay(category: QuizCategory, mode: QuizMode, type: QuizType) {
        navigateToMainScreen(.quizPlay(category: category, mode: mode, type: type))
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
    
    // MARK: - Navigation History Management
    
    /// 네비게이션 히스토리에 화면 추가
    private func addToHistory(_ screen: MainScreen) {
        navigationHistory.append(screen)
        
        // 히스토리 크기 제한
        if navigationHistory.count > maxHistorySize {
            navigationHistory.removeFirst()
        }
    }
    
    /// 네비게이션 히스토리에서 마지막 화면 제거
    private func removeFromHistory() {
        if !navigationHistory.isEmpty {
            navigationHistory.removeLast()
        }
    }
    
    /// 네비게이션 히스토리 초기화
    private func clearNavigationHistory() {
        navigationHistory.removeAll()
    }
    
    /// 현재 네비게이션 히스토리 반환
    var currentNavigationHistory: [MainScreen] {
        return navigationHistory
    }
    
    /// 특정 화면으로 직접 이동 (히스토리 무시)
    func navigateDirectlyTo(_ screen: MainScreen) {
        guard !isNavigationInProgress else { return }
        
        currentMainScreen = screen
        navigationPath = NavigationPath()
        navigationPath.append(screen)
        clearNavigationHistory()
        addToHistory(screen)
    }
    
    /// 네비게이션 스택이 비어있는지 확인
    var isAtRoot: Bool {
        return navigationPath.isEmpty
    }
    
    /// 현재 화면 깊이 반환
    var navigationDepth: Int {
        return navigationHistory.count
    }
}

// MARK: - MainScreen Hashable Conformance
extension AppCoordinator.MainScreen: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .quizModeSelection:
            hasher.combine("quizModeSelection")
        case .categorySelection(let quizMode, let quizType):
            hasher.combine("categorySelection")
            hasher.combine(quizMode)
            hasher.combine(quizType)
        case .quizPlay(let category, let mode, let type):
            hasher.combine("quizPlay")
            hasher.combine(category)
            hasher.combine(mode)
            hasher.combine(type)
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
        case (.categorySelection(let lhsMode, let lhsType), .categorySelection(let rhsMode, let rhsType)):
            return lhsMode == rhsMode && lhsType == rhsType
        case (.quizPlay(let lhsCategory, let lhsMode, let lhsType), .quizPlay(let rhsCategory, let rhsMode, let rhsType)):
            return lhsCategory == rhsCategory && lhsMode == rhsMode && lhsType == rhsType
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
