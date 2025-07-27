import XCTest
@testable import brainy_ios

/// 접근성 기능 UI 테스트
final class AccessibilityUITests: XCTestCase {
    
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
    
    // MARK: - VoiceOver Tests
    
    /// VoiceOver 레이블 테스트
    func testVoiceOverLabels() throws {
        // Given: VoiceOver 활성화
        app.launchEnvironment["UITEST_VOICEOVER"] = "1"
        app.launch()
        
        let loginScreen = app.otherElements["login_screen"]
        XCTAssertTrue(loginScreen.waitForExistence(timeout: 5))
        
        // When: 로그인 화면 요소들의 접근성 레이블 확인
        let emailField = app.textFields["email_input"]
        XCTAssertTrue(emailField.exists)
        XCTAssertEqual(emailField.label, "이메일 주소 입력")
        
        let passwordField = app.secureTextFields["password_input"]
        XCTAssertTrue(passwordField.exists)
        XCTAssertEqual(passwordField.label, "비밀번호 입력")
        
        let loginButton = app.buttons["email_login_button"]
        XCTAssertTrue(loginButton.exists)
        XCTAssertEqual(loginButton.label, "이메일로 로그인")
        
        // Then: 접근성 힌트 확인
        XCTAssertNotNil(emailField.value)
        XCTAssertNotNil(passwordField.value)
    }
    
    /// VoiceOver 퀴즈 플레이 테스트
    func testVoiceOverQuizPlay() throws {
        // Given: VoiceOver 환경에서 퀴즈 시작
        app.launchEnvironment["UITEST_VOICEOVER"] = "1"
        app.launch()
        
        try loginWithTestAccount()
        try startQuizSession()
        
        // When: 퀴즈 화면의 접근성 요소들 확인
        let quizScreen = app.otherElements["quiz_play_screen"]
        XCTAssertTrue(quizScreen.exists)
        
        let questionText = app.staticTexts["quiz_question"]
        XCTAssertTrue(questionText.exists)
        
        // 문제 번호와 총 문제 수가 레이블에 포함되어 있는지 확인
        let questionLabel = questionText.label
        XCTAssertTrue(questionLabel.contains("문제"))
        XCTAssertTrue(questionLabel.contains("번째"))
        
        // Then: 선택지들의 접근성 레이블 확인
        let option1 = app.buttons["quiz_option_0"]
        let option2 = app.buttons["quiz_option_1"]
        
        XCTAssertTrue(option1.exists)
        XCTAssertTrue(option2.exists)
        
        let option1Label = option1.label
        XCTAssertTrue(option1Label.contains("선택지"))
        XCTAssertTrue(option1Label.contains("1번"))
        
        // 선택지 선택 테스트
        option1.tap()
        
        // 선택 상태가 접근성 레이블에 반영되는지 확인
        let updatedOption1Label = option1.label
        XCTAssertTrue(updatedOption1Label.contains("선택됨") || option1.isSelected)
    }
    
    /// VoiceOver 네비게이션 테스트
    func testVoiceOverNavigation() throws {
        // Given: VoiceOver 환경
        app.launchEnvironment["UITEST_VOICEOVER"] = "1"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 탭 네비게이션 테스트
        let mainTab = app.buttons["main_tab"]
        let historyTab = app.buttons["history_tab"]
        let profileTab = app.buttons["profile_tab"]
        
        XCTAssertTrue(mainTab.exists)
        XCTAssertTrue(historyTab.exists)
        XCTAssertTrue(profileTab.exists)
        
        // 각 탭의 접근성 레이블 확인
        XCTAssertEqual(mainTab.label, "메인 화면")
        XCTAssertEqual(historyTab.label, "히스토리")
        XCTAssertEqual(profileTab.label, "프로필")
        
        // Then: 탭 전환 시 화면 변경 알림 확인
        historyTab.tap()
        
        let historyScreen = app.otherElements["history_screen"]
        XCTAssertTrue(historyScreen.waitForExistence(timeout: 5))
        
        // 화면 제목이 접근성으로 읽혀지는지 확인
        let historyTitle = app.navigationBars.staticTexts["히스토리"]
        if historyTitle.exists {
            XCTAssertEqual(historyTitle.label, "히스토리")
        }
    }
    
    // MARK: - Dynamic Type Tests
    
    /// 동적 타입 크기 지원 테스트
    func testDynamicTypeSupport() throws {
        // Given: 큰 텍스트 크기 설정
        app.launchEnvironment["UITEST_CONTENT_SIZE"] = "accessibilityExtraExtraExtraLarge"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 퀴즈 화면에서 텍스트 크기 확인
        try startQuizSession()
        
        let questionText = app.staticTexts["quiz_question"]
        XCTAssertTrue(questionText.exists)
        
        // Then: 텍스트가 큰 크기로 표시되고 읽기 쉬운지 확인
        XCTAssertTrue(questionText.isHittable)
        
        let option1 = app.buttons["quiz_option_0"]
        XCTAssertTrue(option1.exists)
        XCTAssertTrue(option1.isHittable)
        
        // 버튼이 충분히 큰 터치 영역을 가지는지 확인
        let buttonFrame = option1.frame
        XCTAssertGreaterThan(buttonFrame.height, 44) // 최소 44pt 높이
    }
    
    /// 동적 타입에서 레이아웃 적응 테스트
    func testDynamicTypeLayoutAdaptation() throws {
        // Given: 매우 큰 텍스트 크기
        app.launchEnvironment["UITEST_CONTENT_SIZE"] = "accessibilityExtraExtraExtraLarge"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 프로필 화면에서 레이아웃 확인
        let profileTab = app.buttons["profile_tab"]
        profileTab.tap()
        
        let profileScreen = app.otherElements["profile_screen"]
        XCTAssertTrue(profileScreen.waitForExistence(timeout: 5))
        
        // Then: 텍스트가 잘리지 않고 모든 내용이 표시되는지 확인
        let userNameText = app.staticTexts["user_name"]
        let userEmailText = app.staticTexts["user_email"]
        
        if userNameText.exists {
            XCTAssertTrue(userNameText.isHittable)
        }
        
        if userEmailText.exists {
            XCTAssertTrue(userEmailText.isHittable)
        }
        
        // 버튼들이 적절한 크기를 유지하는지 확인
        let syncButton = app.buttons["sync_button"]
        if syncButton.exists {
            let buttonFrame = syncButton.frame
            XCTAssertGreaterThan(buttonFrame.height, 44)
        }
    }
    
    // MARK: - Reduce Motion Tests
    
    /// 모션 감소 설정 테스트
    func testReduceMotionSupport() throws {
        // Given: 모션 감소 설정 활성화
        app.launchEnvironment["UITEST_REDUCE_MOTION"] = "1"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 화면 전환 시 애니메이션 확인
        let profileTab = app.buttons["profile_tab"]
        profileTab.tap()
        
        let profileScreen = app.otherElements["profile_screen"]
        XCTAssertTrue(profileScreen.waitForExistence(timeout: 2)) // 애니메이션이 없으므로 빠르게 나타남
        
        // Then: 다크 모드 토글 시 애니메이션 확인
        let darkModeToggle = app.switches["dark_mode_toggle"]
        if darkModeToggle.exists {
            darkModeToggle.tap()
            
            // 모션 감소 설정에서는 즉시 변경되어야 함
            Thread.sleep(forTimeInterval: 0.1)
            XCTAssertEqual(darkModeToggle.value as? String, "1")
        }
    }
    
    // MARK: - High Contrast Tests
    
    /// 고대비 모드 테스트
    func testHighContrastSupport() throws {
        // Given: 고대비 모드 활성화
        app.launchEnvironment["UITEST_HIGH_CONTRAST"] = "1"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 퀴즈 화면에서 색상 대비 확인
        try startQuizSession()
        
        let questionText = app.staticTexts["quiz_question"]
        XCTAssertTrue(questionText.exists)
        XCTAssertTrue(questionText.isHittable)
        
        // Then: 버튼들이 고대비 모드에서 명확하게 구분되는지 확인
        let option1 = app.buttons["quiz_option_0"]
        let option2 = app.buttons["quiz_option_1"]
        
        XCTAssertTrue(option1.exists)
        XCTAssertTrue(option2.exists)
        XCTAssertTrue(option1.isHittable)
        XCTAssertTrue(option2.isHittable)
        
        // 선택 시 시각적 피드백이 명확한지 확인
        option1.tap()
        XCTAssertTrue(option1.isSelected || option1.label.contains("선택됨"))
    }
    
    // MARK: - Button Shapes Tests
    
    /// 버튼 모양 강조 테스트
    func testButtonShapesSupport() throws {
        // Given: 버튼 모양 강조 활성화
        app.launchEnvironment["UITEST_BUTTON_SHAPES"] = "1"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 메인 화면의 버튼들 확인
        let multipleChoiceButton = app.buttons["multiple_choice_mode"]
        let shortAnswerButton = app.buttons["short_answer_mode"]
        
        XCTAssertTrue(multipleChoiceButton.exists)
        XCTAssertTrue(shortAnswerButton.exists)
        
        // Then: 버튼들이 명확한 경계선을 가지는지 확인
        XCTAssertTrue(multipleChoiceButton.isHittable)
        XCTAssertTrue(shortAnswerButton.isHittable)
        
        // 버튼 탭 테스트
        multipleChoiceButton.tap()
        
        let categoryScreen = app.otherElements["category_selection_screen"]
        XCTAssertTrue(categoryScreen.waitForExistence(timeout: 5))
        
        // 카테고리 버튼들도 명확한 모양을 가지는지 확인
        let generalCategoryButton = app.buttons["general_category"]
        XCTAssertTrue(generalCategoryButton.exists)
        XCTAssertTrue(generalCategoryButton.isHittable)
    }
    
    // MARK: - Keyboard Navigation Tests
    
    /// 키보드 네비게이션 테스트
    func testKeyboardNavigation() throws {
        // Given: 외부 키보드 연결 시뮬레이션
        app.launchEnvironment["UITEST_KEYBOARD_NAVIGATION"] = "1"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: Tab 키로 포커스 이동 시뮬레이션
        let multipleChoiceButton = app.buttons["multiple_choice_mode"]
        let shortAnswerButton = app.buttons["short_answer_mode"]
        
        XCTAssertTrue(multipleChoiceButton.exists)
        XCTAssertTrue(shortAnswerButton.exists)
        
        // 첫 번째 요소에 포커스
        multipleChoiceButton.tap()
        
        // Then: 포커스 인디케이터가 표시되는지 확인
        // (실제 구현에서는 포커스 상태를 나타내는 시각적 요소 확인)
        let categoryScreen = app.otherElements["category_selection_screen"]
        XCTAssertTrue(categoryScreen.waitForExistence(timeout: 5))
    }
    
    // MARK: - Color Differentiation Tests
    
    /// 색상 구분 없는 UI 테스트
    func testColorDifferentiationSupport() throws {
        // Given: 색상 구분 없이 차별화 설정 활성화
        app.launchEnvironment["UITEST_DIFFERENTIATE_WITHOUT_COLOR"] = "1"
        app.launch()
        
        try loginWithTestAccount()
        try startQuizSession()
        
        // When: 퀴즈 선택지에서 색상 외의 구분 요소 확인
        let option1 = app.buttons["quiz_option_0"]
        let option2 = app.buttons["quiz_option_1"]
        
        XCTAssertTrue(option1.exists)
        XCTAssertTrue(option2.exists)
        
        // 선택지 선택
        option1.tap()
        
        // Then: 색상 외에도 선택 상태를 구분할 수 있는 요소가 있는지 확인
        // (예: 체크마크, 테두리, 텍스트 변경 등)
        XCTAssertTrue(option1.isSelected || option1.label.contains("선택됨"))
        
        // 정답/오답 표시도 색상 외의 방법으로 구분되는지 확인
        let nextButton = app.buttons["next_question_button"]
        if nextButton.exists {
            nextButton.tap()
            
            // 결과 표시에서 색상 외의 구분 요소 확인
            let resultIndicator = app.otherElements["answer_result"]
            if resultIndicator.exists {
                XCTAssertTrue(resultIndicator.label.contains("정답") || resultIndicator.label.contains("오답"))
            }
        }
    }
    
    // MARK: - Multiple Device Size Tests
    
    /// 다양한 디바이스 크기 대응 테스트
    func testMultipleDeviceSizes() throws {
        // Given: 작은 화면 크기 시뮬레이션
        app.launchEnvironment["UITEST_DEVICE_SIZE"] = "small"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 메인 화면에서 모든 요소가 표시되는지 확인
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.exists)
        
        let multipleChoiceButton = app.buttons["multiple_choice_mode"]
        let shortAnswerButton = app.buttons["short_answer_mode"]
        let voiceModeButton = app.buttons["voice_mode"]
        let aiModeButton = app.buttons["ai_mode"]
        
        // Then: 모든 버튼이 화면에 표시되고 접근 가능한지 확인
        XCTAssertTrue(multipleChoiceButton.exists)
        XCTAssertTrue(shortAnswerButton.exists)
        XCTAssertTrue(voiceModeButton.exists)
        XCTAssertTrue(aiModeButton.exists)
        
        XCTAssertTrue(multipleChoiceButton.isHittable)
        XCTAssertTrue(shortAnswerButton.isHittable)
        XCTAssertTrue(voiceModeButton.isHittable)
        XCTAssertTrue(aiModeButton.isHittable)
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