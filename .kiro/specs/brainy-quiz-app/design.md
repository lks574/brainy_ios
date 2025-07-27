# Design Document

## Overview

Brainy는 Swift 6와 SwiftData를 활용한 iOS 퀴즈 앱으로, 클린 아키텍처 패턴을 적용하여 유지보수성과 확장성을 보장합니다. 최소한의 서버 통신으로 효율적인 사용자 경험을 제공하며, 다양한 퀴즈 형태와 카테고리를 지원합니다.

## Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────┐
│           Presentation Layer        │
│  (SwiftUI Views, ViewModels)       │
├─────────────────────────────────────┤
│           Domain Layer              │
│  (Use Cases, Entities, Protocols)  │
├─────────────────────────────────────┤
│             Data Layer              │
│  (Repositories, Data Sources)       │
└─────────────────────────────────────┘
```

### Project Structure

```
BrainyApp/
├── Presentation/
│   ├── Views/
│   │   ├── Authentication/
│   │   ├── Quiz/
│   │   ├── History/
│   │   └── Profile/
│   ├── ViewModels/
│   └── Components/
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   └── Repositories/
├── Data/
│   ├── Repositories/
│   ├── DataSources/
│   │   ├── Local/
│   │   └── Remote/
│   └── Models/
├── Core/
│   ├── Network/
│   ├── Storage/
│   ├── Extensions/
│   └── Utils/
└── Resources/
    ├── DesignSystem/
    └── Localizable/
```

## Components and Interfaces

### Authentication Module

#### AuthenticationView
- 정적 설정 기반으로 허용된 로그인 방식만 표시
- 이메일, Google, Apple 로그인 옵션 제공
- 앱 버전 호환성 검증 및 업데이트 안내
- 로그인 상태에 따른 화면 전환 처리

#### AuthenticationViewModel
```swift
@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var authConfig: AuthStaticConfig?
    @Published var sessionInfo: SessionInfo?
    
    private let authUseCase: AuthenticationUseCaseProtocol
    private let configManager: StaticConfigManager
    
    func loadAuthConfig() async
    func signInWithEmail(email: String, password: String) async
    func signInWithGoogle() async
    func signInWithApple() async
    func signInAsGuest() async
    func refreshSession() async
    func signOut() async
    func validateAppVersion() -> Bool
}

struct AuthStaticConfig {
    let authMethodsEnabled: [String]
    let socialLoginRequired: Bool
    let guestModeEnabled: Bool
    let passwordMinLength: Int
    let sessionTimeoutMinutes: Int
    let maxLoginAttempts: Int
    let minAppVersionForAuth: String
}

struct SessionInfo {
    let sessionId: String
    let deviceId: String
    let expiresAt: Date
    let lastActivity: Date
}
```

### Quiz Module

#### QuizFlowCoordinator
- 퀴즈 모드 선택 → 카테고리 선택 → 퀴즈 진행 플로우 관리

#### QuizModeSelectionView
- 주관식, 객관식, 음성모드, AI 모드 선택

#### CategorySelectionView
- 인물, 상식, 나라, 드라마, 음악 등 카테고리 선택
- 스테이지 형식 vs 개별 형식 선택

#### QuizPlayView
- 문제 표시 및 답안 입력
- 진행률 표시
- 타이머 기능

#### QuizViewModel
```swift
@MainActor
class QuizViewModel: ObservableObject {
    @Published var currentQuestion: QuizQuestion?
    @Published var questions: [QuizQuestion] = []
    @Published var currentIndex: Int = 0
    @Published var score: Int = 0
    @Published var timeRemaining: Int = 0
    
    private let quizUseCase: QuizUseCaseProtocol
    
    func loadQuestions(category: QuizCategory, mode: QuizMode) async
    func submitAnswer(_ answer: String) async
    func nextQuestion()
    func finishQuiz() async
}
```

### History Module

#### HistoryView
- 퀴즈 히스토리 목록 표시
- 날짜별, 카테고리별 필터링

#### HistoryDetailView
- 상세 결과 표시 (점수, 소요시간, 정답률)

### Profile Module

#### ProfileView
- 로컬 저장된 사용자 정보 표시
- 설정 옵션 (다크모드, 알림 등)
- 수동 동기화 버튼 및 진행률 표시
- 동기화 상태 및 마지막 동기화 시간 표시
- 오프라인 모드 상태 표시

### Static Configuration Module

#### StaticConfigManager
```swift
actor StaticConfigManager {
    private var cachedConfig: StaticConfig?
    private var lastConfigUpdate: Date?
    
    func loadStaticConfig() async throws -> StaticConfig
    func downloadConfigFromStorage() async throws -> StaticConfig
    func getCachedConfig() -> StaticConfig?
    func isConfigExpired() -> Bool
    func validateConfig(_ config: StaticConfig) -> Bool
}
```

### Local-First Data Module

#### LocalDataManager
```swift
actor LocalDataManager {
    private let modelContext: ModelContext
    
    // 로컬 우선 데이터 관리
    func saveQuizResult(_ result: QuizResult) async
    func loadLocalQuizHistory() async -> [QuizSession]
    func calculateLocalStats() async -> UserStats
    func markForSync(_ items: [Syncable]) async
    func getPendingSyncItems() async -> [Syncable]
    
    // 오프라인 지원
    func isDataAvailableOffline() -> Bool
    func loadCachedLeaderboard() -> LeaderboardData?
    func updateLocalCache<T>(_ data: T, for key: String) async
}

protocol Syncable {
    var id: String { get }
    var lastModified: Date { get }
    var needsSync: Bool { get set }
}
```

#### SyncManager
```swift
actor SyncManager {
    private let syncUseCase: SyncUseCaseProtocol
    private let configManager: StaticConfigManager
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var pendingSyncCount: Int = 0
    
    // 로컬 우선 데이터 관리
    func initializeLocalData() async
    func markPendingSync(for results: [QuizResult]) async
    
    // 수동 동기화 (사용자가 버튼 클릭 시에만)
    func manualSync() async throws
    func uploadPendingResults() async throws
    func downloadLatestQuizData() async throws
    func updateLeaderboard() async throws // 하루 1회만
    
    // 정적 설정 관리
    func checkStaticConfig() async throws -> StaticConfig
    func downloadStaticConfig() async throws
    
    // 오프라인 지원
    func isOfflineMode() -> Bool
    func getCachedData<T>(_ type: T.Type) -> T?
}

enum SyncStatus {
    case idle
    case syncing(progress: Double)
    case completed
    case failed(Error)
}

struct StaticConfig {
    let quizVersion: String
    let downloadUrl: String
    let categories: [String]
    let maintenanceMode: Bool
    let minAppVersion: String
    let featureFlags: FeatureFlags
}

struct FeatureFlags {
    let aiQuiz: Bool
    let voiceMode: Bool
    let offlineMode: Bool
}
```

## Data Models

### Core Entities

#### User
```swift
@Model
class User {
    @Attribute(.unique) var id: String
    var email: String?
    var displayName: String
    var authProvider: AuthProvider
    var accountStatus: AccountStatus = .active
    var isVerified: Bool = false
    var createdAt: Date
    var lastLoginAt: Date?
    var lastSyncAt: Date?
    var failedLoginAttempts: Int = 0
    var lockedUntil: Date?
    
    // 사용자 설정 (로컬 저장)
    var preferences: UserPreferences = UserPreferences()
    var featureFlags: [String: Bool] = [:]
    
    // 세션 정보
    var currentSessionId: String?
    var sessionExpiresAt: Date?
    
    @Relationship(deleteRule: .cascade) var quizResults: [QuizResult]
    @Relationship(deleteRule: .cascade) var quizSessions: [QuizSession]
}

enum AccountStatus: String, CaseIterable, Codable {
    case active, suspended, locked
}

struct UserPreferences: Codable {
    var language: String = "ko"
    var notificationEnabled: Bool = true
    var autoSyncEnabled: Bool = false // 수동 동기화 기본값
    var theme: String = "system"
    var offlineModeEnabled: Bool = true
}
```

#### QuizQuestion
```swift
@Model
class QuizQuestion {
    @Attribute(.unique) var id: String
    var question: String
    var correctAnswer: String
    var options: [String]? // 객관식인 경우
    var category: QuizCategory
    var difficulty: QuizDifficulty
    var type: QuizType
    var audioURL: String? // 음성모드인 경우
    var isCompleted: Bool = false
}
```

#### QuizResult
```swift
@Model
class QuizResult: Syncable {
    @Attribute(.unique) var id: String
    var userId: String
    var questionId: String
    var userAnswer: String
    var isCorrect: Bool
    var timeSpent: TimeInterval
    var completedAt: Date
    var category: QuizCategory
    var quizMode: QuizMode
    
    // 동기화 관련
    var needsSync: Bool = true
    var lastModified: Date = Date()
    var syncedAt: Date?
    
    @Relationship var user: User?
    @Relationship var session: QuizSession?
}
```

#### QuizSession
```swift
@Model
class QuizSession: Syncable {
    @Attribute(.unique) var id: String
    var userId: String
    var category: QuizCategory
    var mode: QuizMode
    var totalQuestions: Int
    var correctAnswers: Int
    var totalTime: TimeInterval
    var startedAt: Date
    var completedAt: Date?
    
    // 동기화 관련
    var needsSync: Bool = true
    var lastModified: Date = Date()
    var syncedAt: Date?
    
    // 로컬 통계 계산용
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
    
    @Relationship var results: [QuizResult]
    @Relationship var user: User?
}

// 로컬 통계 데이터
struct UserStats: Codable {
    let totalQuizzes: Int
    let totalCorrectAnswers: Int
    let totalQuestions: Int
    let averageAccuracy: Double
    let totalTimeSpent: TimeInterval
    let categoryStats: [QuizCategory: CategoryStats]
    let streakDays: Int
    let lastPlayedAt: Date?
    
    // 로컬에서 계산
    static func calculate(from sessions: [QuizSession]) -> UserStats {
        // 로컬 데이터로 통계 계산 로직
    }
}

struct CategoryStats: Codable {
    let totalQuizzes: Int
    let correctAnswers: Int
    let accuracy: Double
    let bestStreak: Int
}

// 리더보드 캐시 데이터
struct LeaderboardData: Codable {
    let rankings: [LeaderboardEntry]
    let userRank: Int?
    let lastUpdated: Date
    let cacheExpiresAt: Date
}

struct LeaderboardEntry: Codable {
    let userId: String
    let displayName: String
    let score: Int
    let accuracy: Double
    let rank: Int
}
```

### Enums

```swift
enum AuthProvider: String, CaseIterable, Codable {
    case email, google, apple
}

enum QuizCategory: String, CaseIterable, Codable {
    case person = "인물"
    case general = "상식"
    case country = "나라"
    case drama = "드라마"
    case music = "음악"
}

enum QuizType: String, CaseIterable, Codable {
    case multipleChoice = "객관식"
    case shortAnswer = "주관식"
    case voice = "음성모드"
    case ai = "AI모드"
}

enum QuizMode: String, CaseIterable, Codable {
    case stage = "스테이지"
    case individual = "개별"
}

enum QuizDifficulty: String, CaseIterable, Codable {
    case easy = "쉬움"
    case medium = "보통"
    case hard = "어려움"
}
```

## Error Handling

### Custom Error Types

```swift
enum BrainyError: LocalizedError {
    case authenticationFailed(String)
    case networkUnavailable
    case dataCorrupted
    case quizNotFound
    case syncFailed(String)
    case adLoadFailed
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "로그인 실패: \(message)"
        case .networkUnavailable:
            return "네트워크 연결을 확인해주세요"
        case .dataCorrupted:
            return "데이터가 손상되었습니다"
        case .quizNotFound:
            return "퀴즈를 찾을 수 없습니다"
        case .syncFailed(let message):
            return "동기화 실패: \(message)"
        case .adLoadFailed:
            return "광고 로드에 실패했습니다"
        }
    }
}
```

### Error Handling Strategy

1. **Network Errors**: 자동 재시도 및 오프라인 모드 지원
2. **Authentication Errors**: 사용자 친화적 메시지 표시 및 재로그인 유도
3. **Data Errors**: 로컬 데이터 복구 시도 및 서버 동기화
4. **Ad Errors**: 광고 실패 시에도 앱 기능 정상 동작 보장

## Testing Strategy

### Unit Testing
- Domain Layer의 Use Cases 테스트
- ViewModel 로직 테스트
- Repository 구현체 테스트

### Integration Testing
- SwiftData 저장소 테스트
- 네트워크 통신 테스트
- 인증 플로우 테스트

### UI Testing
- 주요 사용자 플로우 테스트
- 접근성 테스트
- 다크모드 테스트

### Test Structure
```swift
// Example: QuizViewModelTests
@MainActor
class QuizViewModelTests: XCTestCase {
    var viewModel: QuizViewModel!
    var mockQuizUseCase: MockQuizUseCase!
    
    override func setUp() async throws {
        mockQuizUseCase = MockQuizUseCase()
        viewModel = QuizViewModel(quizUseCase: mockQuizUseCase)
    }
    
    func testLoadQuestions() async throws {
        // Given
        let expectedQuestions = [QuizQuestion.mock()]
        mockQuizUseCase.questionsToReturn = expectedQuestions
        
        // When
        await viewModel.loadQuestions(category: .general, mode: .individual)
        
        // Then
        XCTAssertEqual(viewModel.questions.count, 1)
        XCTAssertEqual(viewModel.questions.first?.question, expectedQuestions.first?.question)
    }
}
```

## Design System

### Color Palette
```swift
extension Color {
    static let brainyPrimary = Color("BrainyPrimary")
    static let brainySecondary = Color("BrainySecondary")
    static let brainyAccent = Color("BrainyAccent")
    static let brainyBackground = Color("BrainyBackground")
    static let brainyText = Color("BrainyText")
}
```

### Typography
```swift
extension Font {
    static let brainyTitle = Font.custom("SF Pro Display", size: 28).weight(.bold)
    static let brainyHeadline = Font.custom("SF Pro Display", size: 22).weight(.semibold)
    static let brainyBody = Font.custom("SF Pro Text", size: 16).weight(.regular)
    static let brainyCaption = Font.custom("SF Pro Text", size: 12).weight(.medium)
}
```

### Component Library
- BrainyButton: 일관된 버튼 스타일
- BrainyCard: 퀴즈 카드 및 히스토리 카드
- BrainyTextField: 입력 필드
- BrainyProgressBar: 퀴즈 진행률 표시
- BrainyAlert: 커스텀 알림 다이얼로그

## Performance Considerations

### Memory Management
- SwiftData의 lazy loading 활용
- 이미지 캐싱 및 압축
- 백그라운드에서 불필요한 작업 정리

### Network Optimization
- 퀴즈 데이터 압축 전송
- 배치 동기화로 API 호출 최소화
- 오프라인 우선 아키텍처

### Battery Optimization
- 백그라운드 작업 최소화
- 위치 서비스 사용 안함
- 효율적인 타이머 구현

## Security

### Data Protection
- SwiftData 암호화 활성화
- 민감한 정보 Keychain 저장
- 네트워크 통신 HTTPS 강제

### Authentication Security
- OAuth 토큰 안전한 저장
- 자동 로그아웃 기능
- 생체 인증 옵션 제공

## Accessibility

### VoiceOver Support
- 모든 UI 요소에 적절한 accessibility label
- 퀴즈 문제 음성 읽기 지원
- 동적 타입 크기 지원

### Inclusive Design
- 색상 대비 WCAG 준수
- 모션 감소 옵션 지원
- 키보드 네비게이션 지원

## Localization

### Multi-language Support
- 한국어 우선 지원
- 영어 추가 지원 준비
- 퀴즈 콘텐츠 현지화 고려

### Implementation
```swift
// Localizable.strings
"quiz.start" = "퀴즈 시작";
"quiz.category.person" = "인물";
"quiz.mode.multiple_choice" = "객관식";
```