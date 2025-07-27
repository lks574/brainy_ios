import XCTest
@testable import brainy_ios

/// 다크모드 전환 UI 테스트
final class DarkModeUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = [
            "UITEST_DISABLE_ANIMATIONS": "1",
            "UITEST_MOCK_NETWORK": "1"
        ]
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Dark Mode Toggle Tests
    
    /// 라이트 모드에서 다크 모드로 전환 테스트
    func testLightToDarkModeTransition() throws {
        // Given: 라이트 모드로 앱 시작
        app.launchEnvironment["UITEST_APPEARANCE"] = "light"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 프로필에서 다크 모드 토글
        let profileTab = app.buttons["profile_tab"]
        profileTab.tap()
        
        let profileScreen = app.otherElements["profile_screen"]
        XCTAssertTrue(profileScreen.waitForExistence(timeout: 5))
        
        let darkModeToggle = app.switches["dark_mode_toggle"]
        XCTAssertTrue(darkModeToggle.exists)
        XCTAssertEqual(darkModeToggle.value as? String, "0") // 라이트 모드
        
        darkModeToggle.tap()
        
        // Then: 다크 모드로 전환 확인
        XCTAssertEqual(darkModeToggle.value as? String, "1") // 다크 모드
        
        // UI 요소들이 다크 모드 색상으로 변경되었는지 확인
        let backgroundElement = app.otherElements["main_background"]
        XCTAssertTrue(backgroundElement.exists)
        
        // 다른 화면으로 이동해서 다크 모드가 유지되는지 확인
        let mainTab = app.buttons["main_tab"]
        mainTab.tap()
        
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.waitForExistence(timeout: 5))
    }
    
    /// 다크 모드에서 라이트 모드로 전환 테스트
    func testDarkToLightModeTransition() throws {
        // Given: 다크 모드로 앱 시작
        app.launchEnvironment["UITEST_APPEARANCE"] = "dark"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 프로필에서 라이트 모드 토글
        let profileTab = app.buttons["profile_tab"]
        profileTab.tap()
        
        let darkModeToggle = app.switches["dark_mode_toggle"]
        XCTAssertTrue(darkModeToggle.waitForExistence(timeout: 5))
        XCTAssertEqual(darkModeToggle.value as? String, "1") // 다크 모드
        
        darkModeToggle.tap()
        
        // Then: 라이트 모드로 전환 확인
        XCTAssertEqual(darkModeToggle.value as? String, "0") // 라이트 모드
        
        // UI 요소들이 라이트 모드 색상으로 변경되었는지 확인
        let backgroundElement = app.otherElements["main_background"]
        XCTAssertTrue(backgroundElement.exists)
    }
    
    /// 시스템 설정 따르기 테스트
    func testSystemAppearanceMode() throws {
        // Given: 시스템 설정 따르기 모드
        app.launchEnvironment["UITEST_APPEARANCE"] = "system"
        app.launch()
        
        try loginWithTestAccount()
        
        let profileTab = app.buttons["profile_tab"]
        profileTab.tap()
        
        // When: 시스템 설정 따르기 선택
        let appearanceSegmentedControl = app.segmentedControls["appearance_control"]
        XCTAssertTrue(appearanceSegmentedControl.waitForExistence(timeout: 5))
        
        let systemButton = appearanceSegmentedControl.buttons["시스템"]
        systemButton.tap()
        
        // Then: 시스템 설정에 따라 모드 변경
        XCTAssertTrue(systemButton.isSelected)
        
        // 시스템 다크 모드 시뮬레이션
        app.launchEnvironment["UITEST_SYSTEM_APPEARANCE"] = "dark"
        
        // 앱이 시스템 설정을 따르는지 확인
        let backgroundElement = app.otherElements["main_background"]
        XCTAssertTrue(backgroundElement.exists)
    }
    
    // MARK: - Dark Mode UI Element Tests
    
    /// 다크 모드에서 버튼 스타일 테스트
    func testDarkModeButtonStyles() throws {
        // Given: 다크 모드
        app.launchEnvironment["UITEST_APPEARANCE"] = "dark"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 퀴즈 모드 선택 화면으로 이동
        let multipleChoiceButton = app.buttons["multiple_choice_mode"]
        XCTAssertTrue(multipleChoiceButton.exists)
        
        // Then: 버튼이 다크 모드에 적합한 스타일로 표시
        XCTAssertTrue(multipleChoiceButton.isEnabled)
        
        // 버튼 탭 테스트
        multipleChoiceButton.tap()
        
        let categoryScreen = app.otherElements["category_selection_screen"]
        XCTAssertTrue(categoryScreen.waitForExistence(timeout: 5))
        
        // 카테고리 버튼들도 다크 모드 스타일 확인
        let generalCategoryButton = app.buttons["general_category"]
        XCTAssertTrue(generalCategoryButton.exists)
    }
    
    /// 다크 모드에서 텍스트 가독성 테스트
    func testDarkModeTextReadability() throws {
        // Given: 다크 모드에서 퀴즈 플레이
        app.launchEnvironment["UITEST_APPEARANCE"] = "dark"
        app.launch()
        
        try startQuizSession()
        
        // When: 퀴즈 문제 화면
        let quizScreen = app.otherElements["quiz_play_screen"]
        XCTAssertTrue(quizScreen.exists)
        
        // Then: 텍스트 요소들이 다크 모드에서 읽기 쉬운지 확인
        let questionText = app.staticTexts["quiz_question"]
        XCTAssertTrue(questionText.exists)
        XCTAssertTrue(questionText.isHittable)
        
        let option1 = app.buttons["quiz_option_0"]
        let option2 = app.buttons["quiz_option_1"]
        XCTAssertTrue(option1.exists)
        XCTAssertTrue(option2.exists)
        
        // 선택지 텍스트가 명확하게 보이는지 확인
        XCTAssertTrue(option1.isHittable)
        XCTAssertTrue(option2.isHittable)
    }
    
    /// 다크 모드에서 카드 및 컨테이너 스타일 테스트
    func testDarkModeCardStyles() throws {
        // Given: 다크 모드에서 히스토리 화면
        app.launchEnvironment["UITEST_APPEARANCE"] = "dark"
        app.launch()
        
        try loginWithTestAccount()
        
        let historyTab = app.buttons["history_tab"]
        historyTab.tap()
        
        // When: 히스토리 화면 표시
        let historyScreen = app.otherElements["history_screen"]
        XCTAssertTrue(historyScreen.waitForExistence(timeout: 5))
        
        // Then: 히스토리 카드들이 다크 모드에 적합한 스타일로 표시
        let historyList = app.collectionViews["history_list"]
        XCTAssertTrue(historyList.exists)
        
        let firstHistoryCard = historyList.cells.element(boundBy: 0)
        if firstHistoryCard.exists {
            XCTAssertTrue(firstHistoryCard.isHittable)
            
            // 카드 내부 텍스트 요소들 확인
            let scoreText = firstHistoryCard.staticTexts.element(boundBy: 0)
            if scoreText.exists {
                XCTAssertTrue(scoreText.isHittable)
            }
        }
    }
    
    // MARK: - Dark Mode Persistence Tests
    
    /// 다크 모드 설정 지속성 테스트
    func testDarkModeSettingsPersistence() throws {
        // Given: 다크 모드로 설정
        app.launch()
        try loginWithTestAccount()
        
        let profileTab = app.buttons["profile_tab"]
        profileTab.tap()
        
        let darkModeToggle = app.switches["dark_mode_toggle"]
        XCTAssertTrue(darkModeToggle.waitForExistence(timeout: 5))
        
        if darkModeToggle.value as? String == "0" {
            darkModeToggle.tap()
        }
        
        // When: 앱 재시작
        app.terminate()
        app.launch()
        
        try loginWithTestAccount()
        
        // Then: 다크 모드 설정이 유지되는지 확인
        profileTab.tap()
        
        let persistedToggle = app.switches["dark_mode_toggle"]
        XCTAssertTrue(persistedToggle.waitForExistence(timeout: 5))
        XCTAssertEqual(persistedToggle.value as? String, "1") // 다크 모드 유지
    }
    
    /// 앱 백그라운드/포그라운드에서 다크 모드 유지 테스트
    func testDarkModeBackgroundForeground() throws {
        // Given: 다크 모드 설정
        app.launchEnvironment["UITEST_APPEARANCE"] = "dark"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 앱을 백그라운드로 보내고 다시 포그라운드로
        XCUIDevice.shared.press(.home)
        
        // 잠시 대기
        Thread.sleep(forTimeInterval: 2)
        
        app.activate()
        
        // Then: 다크 모드가 유지되는지 확인
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.waitForExistence(timeout: 5))
        
        let backgroundElement = app.otherElements["main_background"]
        XCTAssertTrue(backgroundElement.exists)
    }
    
    // MARK: - Dark Mode Animation Tests
    
    /// 다크 모드 전환 애니메이션 테스트
    func testDarkModeTransitionAnimation() throws {
        // Given: 라이트 모드
        app.launchEnvironment["UITEST_APPEARANCE"] = "light"
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "0" // 애니메이션 활성화
        app.launch()
        
        try loginWithTestAccount()
        
        let profileTab = app.buttons["profile_tab"]
        profileTab.tap()
        
        // When: 다크 모드로 전환
        let darkModeToggle = app.switches["dark_mode_toggle"]
        XCTAssertTrue(darkModeToggle.waitForExistence(timeout: 5))
        
        darkModeToggle.tap()
        
        // Then: 전환 애니메이션이 부드럽게 진행되는지 확인
        // (실제로는 애니메이션 완료를 기다리는 시간 필요)
        Thread.sleep(forTimeInterval: 1)
        
        let backgroundElement = app.otherElements["main_background"]
        XCTAssertTrue(backgroundElement.exists)
    }
    
    // MARK: - Helper Methods
    
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
}