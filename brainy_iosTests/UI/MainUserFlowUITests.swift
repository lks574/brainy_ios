import XCTest
@testable import brainy_ios

/// 주요 사용자 플로우 UI 테스트
final class MainUserFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // 테스트용 환경 설정
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = [
            "UITEST_DISABLE_ANIMATIONS": "1",
            "UITEST_MOCK_NETWORK": "1"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Authentication Flow Tests
    
    /// 로그인 플로우 테스트
    func testLoginFlow() throws {
        // Given: 앱이 시작되고 로그인 화면이 표시됨
        let loginScreen = app.otherElements["login_screen"]
        XCTAssertTrue(loginScreen.waitForExistence(timeout: 5))
        
        // When: 이메일 로그인 시도
        let emailField = app.textFields["email_input"]
        let passwordField = app.secureTextFields["password_input"]
        let loginButton = app.buttons["email_login_button"]
        
        XCTAssertTrue(emailField.exists)
        XCTAssertTrue(passwordField.exists)
        XCTAssertTrue(loginButton.exists)
        
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        loginButton.tap()
        
        // Then: 메인 화면으로 이동
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.waitForExistence(timeout: 10))
    }
    
    /// 소셜 로그인 플로우 테스트
    func testSocialLoginFlow() throws {
        // Given: 로그인 화면
        let loginScreen = app.otherElements["login_screen"]
        XCTAssertTrue(loginScreen.waitForExistence(timeout: 5))
        
        // When: Apple 로그인 버튼 탭
        let appleLoginButton = app.buttons["apple_login_button"]
        XCTAssertTrue(appleLoginButton.exists)
        appleLoginButton.tap()
        
        // Then: Apple 로그인 처리 (모킹된 환경에서)
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.waitForExistence(timeout: 10))
    }
    
    /// 로그인 에러 처리 테스트
    func testLoginErrorHandling() throws {
        // Given: 로그인 화면
        let loginScreen = app.otherElements["login_screen"]
        XCTAssertTrue(loginScreen.waitForExistence(timeout: 5))
        
        // When: 잘못된 정보로 로그인 시도
        let emailField = app.textFields["email_input"]
        let passwordField = app.secureTextFields["password_input"]
        let loginButton = app.buttons["email_login_button"]
        
        emailField.tap()
        emailField.typeText("invalid@example.com")
        
        passwordField.tap()
        passwordField.typeText("wrongpassword")
        
        loginButton.tap()
        
        // Then: 에러 메시지 표시
        let errorAlert = app.alerts["로그인 오류"]
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5))
        
        let okButton = errorAlert.buttons["확인"]
        okButton.tap()
        
        // 로그인 화면에 여전히 있어야 함
        XCTAssertTrue(loginScreen.exists)
    }
    
    // MARK: - Quiz Flow Tests
    
    /// 퀴즈 플레이 플로우 테스트
    func testQuizPlayFlow() throws {
        // Given: 로그인 후 메인 화면
        try loginWithTestAccount()
        
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.exists)
        
        // When: 퀴즈 모드 선택
        let multipleChoiceButton = app.buttons["multiple_choice_mode"]
        XCTAssertTrue(multipleChoiceButton.exists)
        multipleChoiceButton.tap()
        
        // 카테고리 선택
        let categoryScreen = app.otherElements["category_selection_screen"]
        XCTAssertTrue(categoryScreen.waitForExistence(timeout: 5))
        
        let generalCategoryButton = app.buttons["general_category"]
        XCTAssertTrue(generalCategoryButton.exists)
        generalCategoryButton.tap()
        
        // 퀴즈 시작
        let startQuizButton = app.buttons["start_quiz_button"]
        XCTAssertTrue(startQuizButton.exists)
        startQuizButton.tap()
        
        // Then: 퀴즈 화면 표시
        let quizScreen = app.otherElements["quiz_play_screen"]
        XCTAssertTrue(quizScreen.waitForExistence(timeout: 5))
        
        // 문제와 선택지 확인
        let questionText = app.staticTexts["quiz_question"]
        XCTAssertTrue(questionText.exists)
        
        let option1 = app.buttons["quiz_option_0"]
        let option2 = app.buttons["quiz_option_1"]
        XCTAssertTrue(option1.exists)
        XCTAssertTrue(option2.exists)
    }
    
    /// 퀴즈 답안 선택 및 완료 테스트
    func testQuizAnswerSelectionAndCompletion() throws {
        // Given: 퀴즈 화면
        try startQuizSession()
        
        let quizScreen = app.otherElements["quiz_play_screen"]
        XCTAssertTrue(quizScreen.exists)
        
        // When: 답안 선택 및 다음 문제로 진행
        for questionIndex in 0..<5 { // 5문제 풀이
            let option1 = app.buttons["quiz_option_0"]
            XCTAssertTrue(option1.waitForExistence(timeout: 5))
            option1.tap()
            
            let nextButton = app.buttons["next_question_button"]
            if nextButton.exists {
                nextButton.tap()
            }
        }
        
        // Then: 결과 화면 표시
        let resultScreen = app.otherElements["quiz_result_screen"]
        XCTAssertTrue(resultScreen.waitForExistence(timeout: 10))
        
        let scoreText = app.staticTexts["quiz_score"]
        XCTAssertTrue(scoreText.exists)
        
        let finishButton = app.buttons["finish_quiz_button"]
        XCTAssertTrue(finishButton.exists)
        finishButton.tap()
        
        // 메인 화면으로 돌아가기
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.waitForExistence(timeout: 5))
    }
    
    // MARK: - History Flow Tests
    
    /// 히스토리 조회 플로우 테스트
    func testHistoryFlow() throws {
        // Given: 로그인 후 메인 화면
        try loginWithTestAccount()
        
        // When: 히스토리 탭 선택
        let historyTab = app.buttons["history_tab"]
        XCTAssertTrue(historyTab.exists)
        historyTab.tap()
        
        // Then: 히스토리 화면 표시
        let historyScreen = app.otherElements["history_screen"]
        XCTAssertTrue(historyScreen.waitForExistence(timeout: 5))
        
        // 히스토리 항목들 확인
        let historyList = app.collectionViews["history_list"]
        XCTAssertTrue(historyList.exists)
        
        // 첫 번째 히스토리 항목 탭
        let firstHistoryItem = historyList.cells.element(boundBy: 0)
        if firstHistoryItem.exists {
            firstHistoryItem.tap()
            
            // 히스토리 상세 화면 확인
            let historyDetailScreen = app.otherElements["history_detail_screen"]
            XCTAssertTrue(historyDetailScreen.waitForExistence(timeout: 5))
        }
    }
    
    // MARK: - Profile Flow Tests
    
    /// 프로필 및 설정 플로우 테스트
    func testProfileFlow() throws {
        // Given: 로그인 후 메인 화면
        try loginWithTestAccount()
        
        // When: 프로필 탭 선택
        let profileTab = app.buttons["profile_tab"]
        XCTAssertTrue(profileTab.exists)
        profileTab.tap()
        
        // Then: 프로필 화면 표시
        let profileScreen = app.otherElements["profile_screen"]
        XCTAssertTrue(profileScreen.waitForExistence(timeout: 5))
        
        // 사용자 정보 확인
        let userNameText = app.staticTexts["user_name"]
        let userEmailText = app.staticTexts["user_email"]
        XCTAssertTrue(userNameText.exists)
        XCTAssertTrue(userEmailText.exists)
        
        // 동기화 버튼 테스트
        let syncButton = app.buttons["sync_button"]
        XCTAssertTrue(syncButton.exists)
        syncButton.tap()
        
        // 동기화 진행 상태 확인
        let syncProgressIndicator = app.progressIndicators["sync_progress"]
        if syncProgressIndicator.exists {
            XCTAssertTrue(syncProgressIndicator.waitForExistence(timeout: 3))
        }
    }
    
    /// 로그아웃 플로우 테스트
    func testLogoutFlow() throws {
        // Given: 로그인 후 프로필 화면
        try loginWithTestAccount()
        
        let profileTab = app.buttons["profile_tab"]
        profileTab.tap()
        
        let profileScreen = app.otherElements["profile_screen"]
        XCTAssertTrue(profileScreen.waitForExistence(timeout: 5))
        
        // When: 로그아웃 버튼 탭
        let logoutButton = app.buttons["logout_button"]
        XCTAssertTrue(logoutButton.exists)
        logoutButton.tap()
        
        // 로그아웃 확인 알림
        let logoutAlert = app.alerts["로그아웃"]
        XCTAssertTrue(logoutAlert.waitForExistence(timeout: 5))
        
        let confirmButton = logoutAlert.buttons["로그아웃"]
        confirmButton.tap()
        
        // Then: 로그인 화면으로 이동
        let loginScreen = app.otherElements["login_screen"]
        XCTAssertTrue(loginScreen.waitForExistence(timeout: 10))
    }
    
    // MARK: - Error Handling Tests
    
    /// 네트워크 에러 처리 테스트
    func testNetworkErrorHandling() throws {
        // Given: 네트워크 에러 환경 설정
        app.launchEnvironment["UITEST_NETWORK_ERROR"] = "1"
        app.terminate()
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 동기화 시도 (네트워크 에러 발생)
        let profileTab = app.buttons["profile_tab"]
        profileTab.tap()
        
        let syncButton = app.buttons["sync_button"]
        syncButton.tap()
        
        // Then: 에러 토스트 메시지 표시
        let errorToast = app.otherElements["error_toast"]
        XCTAssertTrue(errorToast.waitForExistence(timeout: 5))
        
        let retryButton = errorToast.buttons["다시 시도"]
        if retryButton.exists {
            retryButton.tap()
        }
    }
    
    /// 오프라인 모드 테스트
    func testOfflineMode() throws {
        // Given: 오프라인 환경 설정
        app.launchEnvironment["UITEST_OFFLINE_MODE"] = "1"
        app.terminate()
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 오프라인 상태에서 퀴즈 플레이
        let offlineIndicator = app.otherElements["offline_indicator"]
        XCTAssertTrue(offlineIndicator.waitForExistence(timeout: 5))
        
        // 퀴즈는 여전히 플레이 가능해야 함
        let multipleChoiceButton = app.buttons["multiple_choice_mode"]
        XCTAssertTrue(multipleChoiceButton.exists)
        multipleChoiceButton.tap()
        
        // Then: 오프라인에서도 퀴즈 진행 가능
        let categoryScreen = app.otherElements["category_selection_screen"]
        XCTAssertTrue(categoryScreen.waitForExistence(timeout: 5))
    }
    
    // MARK: - Helper Methods
    
    /// 테스트 계정으로 로그인
    private func loginWithTestAccount() throws {
        let loginScreen = app.otherElements["login_screen"]
        XCTAssertTrue(loginScreen.waitForExistence(timeout: 5))
        
        let emailField = app.textFields["email_input"]
        let passwordField = app.secureTextFields["password_input"]
        let loginButton = app.buttons["email_login_button"]
        
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        loginButton.tap()
        
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.waitForExistence(timeout: 10))
    }
    
    /// 퀴즈 세션 시작
    private func startQuizSession() throws {
        try loginWithTestAccount()
        
        let multipleChoiceButton = app.buttons["multiple_choice_mode"]
        multipleChoiceButton.tap()
        
        let categoryScreen = app.otherElements["category_selection_screen"]
        XCTAssertTrue(categoryScreen.waitForExistence(timeout: 5))
        
        let generalCategoryButton = app.buttons["general_category"]
        generalCategoryButton.tap()
        
        let startQuizButton = app.buttons["start_quiz_button"]
        startQuizButton.tap()
        
        let quizScreen = app.otherElements["quiz_play_screen"]
        XCTAssertTrue(quizScreen.waitForExistence(timeout: 5))
    }
    
    // MARK: - Performance Tests
    
    /// 앱 시작 성능 테스트
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    /// 퀴즈 로딩 성능 테스트
    func testQuizLoadingPerformance() throws {
        try loginWithTestAccount()
        
        measure(metrics: [XCTClockMetric()]) {
            let multipleChoiceButton = app.buttons["multiple_choice_mode"]
            multipleChoiceButton.tap()
            
            let categoryScreen = app.otherElements["category_selection_screen"]
            _ = categoryScreen.waitForExistence(timeout: 10)
        }
    }
}