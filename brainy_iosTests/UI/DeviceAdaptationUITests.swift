import XCTest
@testable import brainy_ios

/// 다양한 디바이스 크기 대응 UI 테스트
final class DeviceAdaptationUITests: XCTestCase {
    
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
    
    // MARK: - iPhone SE (Small Screen) Tests
    
    /// iPhone SE 크기에서 UI 적응 테스트
    func testIPhoneSEAdaptation() throws {
        // Given: iPhone SE 크기 시뮬레이션
        app.launchEnvironment["UITEST_DEVICE_SIZE"] = "iphone_se"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 메인 화면에서 모든 요소 확인
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.exists)
        
        // Then: 작은 화면에서도 모든 퀴즈 모드 버튼이 표시되는지 확인
        let quizModeButtons = [
            app.buttons["multiple_choice_mode"],
            app.buttons["short_answer_mode"],
            app.buttons["voice_mode"],
            app.buttons["ai_mode"]
        ]
        
        for button in quizModeButtons {
            XCTAssertTrue(button.exists, "Button should exist on small screen")
            XCTAssertTrue(button.isHittable, "Button should be hittable on small screen")
            
            // 버튼이 최소 터치 영역을 만족하는지 확인
            let buttonFrame = button.frame
            XCTAssertGreaterThanOrEqual(buttonFrame.height, 44, "Button height should be at least 44pt")
            XCTAssertGreaterThanOrEqual(buttonFrame.width, 44, "Button width should be at least 44pt")
        }
        
        // 스크롤 가능한지 확인
        let scrollView = app.scrollViews.element(boundBy: 0)
        if scrollView.exists {
            // 스크롤하여 모든 콘텐츠에 접근 가능한지 확인
            scrollView.swipeUp()
            scrollView.swipeDown()
        }
    }
    
    /// iPhone SE에서 퀴즈 플레이 화면 테스트
    func testIPhoneSEQuizPlayScreen() throws {
        // Given: iPhone SE 크기에서 퀴즈 시작
        app.launchEnvironment["UITEST_DEVICE_SIZE"] = "iphone_se"
        app.launch()
        
        try loginWithTestAccount()
        try startQuizSession()
        
        // When: 퀴즈 화면 요소들 확인
        let quizScreen = app.otherElements["quiz_play_screen"]
        XCTAssertTrue(quizScreen.exists)
        
        let questionText = app.staticTexts["quiz_question"]
        XCTAssertTrue(questionText.exists)
        XCTAssertTrue(questionText.isHittable)
        
        // Then: 선택지들이 작은 화면에서도 적절히 표시되는지 확인
        let options = [
            app.buttons["quiz_option_0"],
            app.buttons["quiz_option_1"],
            app.buttons["quiz_option_2"],
            app.buttons["quiz_option_3"]
        ]
        
        for (index, option) in options.enumerated() {
            if option.exists {
                XCTAssertTrue(option.isHittable, "Option \(index) should be hittable")
                
                let optionFrame = option.frame
                XCTAssertGreaterThanOrEqual(optionFrame.height, 44, "Option height should be at least 44pt")
                
                // 선택지 텍스트가 잘리지 않는지 확인
                XCTAssertFalse(option.label.isEmpty, "Option label should not be empty")
            }
        }
        
        // 진행률 표시가 보이는지 확인
        let progressIndicator = app.progressIndicators["quiz_progress"]
        if progressIndicator.exists {
            XCTAssertTrue(progressIndicator.isHittable)
        }
    }
    
    // MARK: - iPhone Pro Max (Large Screen) Tests
    
    /// iPhone Pro Max 크기에서 UI 적응 테스트
    func testIPhoneProMaxAdaptation() throws {
        // Given: iPhone Pro Max 크기 시뮬레이션
        app.launchEnvironment["UITEST_DEVICE_SIZE"] = "iphone_pro_max"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 메인 화면에서 레이아웃 확인
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.exists)
        
        // Then: 큰 화면에서 요소들이 적절히 배치되는지 확인
        let quizModeButtons = [
            app.buttons["multiple_choice_mode"],
            app.buttons["short_answer_mode"],
            app.buttons["voice_mode"],
            app.buttons["ai_mode"]
        ]
        
        // 버튼들이 화면을 효율적으로 사용하는지 확인
        for button in quizModeButtons {
            XCTAssertTrue(button.exists)
            XCTAssertTrue(button.isHittable)
            
            let buttonFrame = button.frame
            // 큰 화면에서는 버튼이 더 넓을 수 있음
            XCTAssertGreaterThanOrEqual(buttonFrame.width, 100)
        }
        
        // 여백이 적절히 활용되는지 확인
        let screenBounds = app.frame
        XCTAssertGreaterThan(screenBounds.width, 400) // Pro Max 화면 너비
    }
    
    /// iPhone Pro Max에서 히스토리 화면 테스트
    func testIPhoneProMaxHistoryScreen() throws {
        // Given: iPhone Pro Max 크기에서 히스토리 화면
        app.launchEnvironment["UITEST_DEVICE_SIZE"] = "iphone_pro_max"
        app.launch()
        
        try loginWithTestAccount()
        
        let historyTab = app.buttons["history_tab"]
        historyTab.tap()
        
        // When: 히스토리 화면 확인
        let historyScreen = app.otherElements["history_screen"]
        XCTAssertTrue(historyScreen.waitForExistence(timeout: 5))
        
        let historyList = app.collectionViews["history_list"]
        XCTAssertTrue(historyList.exists)
        
        // Then: 큰 화면에서 더 많은 히스토리 항목이 표시되는지 확인
        let visibleCells = historyList.cells
        let cellCount = visibleCells.count
        
        // 큰 화면에서는 더 많은 셀이 동시에 보여야 함
        if cellCount > 0 {
            XCTAssertGreaterThanOrEqual(cellCount, 3, "Large screen should show more history items")
            
            // 각 셀이 적절한 크기를 가지는지 확인
            let firstCell = visibleCells.element(boundBy: 0)
            let cellFrame = firstCell.frame
            XCTAssertGreaterThan(cellFrame.width, 300)
        }
    }
    
    // MARK: - iPad (Tablet) Tests
    
    /// iPad 크기에서 UI 적응 테스트
    func testIPadAdaptation() throws {
        // Given: iPad 크기 시뮬레이션
        app.launchEnvironment["UITEST_DEVICE_SIZE"] = "ipad"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 메인 화면에서 태블릿 레이아웃 확인
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.exists)
        
        // Then: iPad에서는 더 넓은 레이아웃을 활용해야 함
        let quizModeButtons = [
            app.buttons["multiple_choice_mode"],
            app.buttons["short_answer_mode"],
            app.buttons["voice_mode"],
            app.buttons["ai_mode"]
        ]
        
        // 버튼들이 그리드 형태로 배치되는지 확인
        for button in quizModeButtons {
            XCTAssertTrue(button.exists)
            XCTAssertTrue(button.isHittable)
            
            let buttonFrame = button.frame
            // iPad에서는 버튼이 더 넓고 높을 수 있음
            XCTAssertGreaterThanOrEqual(buttonFrame.width, 200)
            XCTAssertGreaterThanOrEqual(buttonFrame.height, 60)
        }
        
        // 사이드바나 분할 뷰가 있는지 확인 (iPad 특화 기능)
        let sidebar = app.otherElements["sidebar"]
        if sidebar.exists {
            XCTAssertTrue(sidebar.isHittable)
        }
    }
    
    /// iPad에서 퀴즈 플레이 화면 테스트
    func testIPadQuizPlayScreen() throws {
        // Given: iPad 크기에서 퀴즈 시작
        app.launchEnvironment["UITEST_DEVICE_SIZE"] = "ipad"
        app.launch()
        
        try loginWithTestAccount()
        try startQuizSession()
        
        // When: 퀴즈 화면 확인
        let quizScreen = app.otherElements["quiz_play_screen"]
        XCTAssertTrue(quizScreen.exists)
        
        // Then: iPad에서는 더 넓은 공간을 활용한 레이아웃
        let questionText = app.staticTexts["quiz_question"]
        XCTAssertTrue(questionText.exists)
        
        let questionFrame = questionText.frame
        XCTAssertGreaterThan(questionFrame.width, 400) // iPad에서는 더 넓은 텍스트 영역
        
        // 선택지들이 더 넓게 배치되는지 확인
        let options = [
            app.buttons["quiz_option_0"],
            app.buttons["quiz_option_1"]
        ]
        
        for option in options {
            if option.exists {
                let optionFrame = option.frame
                XCTAssertGreaterThan(optionFrame.width, 300)
                XCTAssertGreaterThanOrEqual(optionFrame.height, 50)
            }
        }
        
        // 추가 정보 패널이 있는지 확인 (iPad 전용)
        let infoPanel = app.otherElements["quiz_info_panel"]
        if infoPanel.exists {
            XCTAssertTrue(infoPanel.isHittable)
        }
    }
    
    // MARK: - Orientation Tests
    
    /// 가로 모드 적응 테스트
    func testLandscapeOrientation() throws {
        // Given: 가로 모드 시뮬레이션
        app.launchEnvironment["UITEST_ORIENTATION"] = "landscape"
        app.launch()
        
        try loginWithTestAccount()
        
        // When: 메인 화면에서 가로 모드 레이아웃 확인
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.exists)
        
        // Then: 가로 모드에서 적절한 레이아웃 적용
        let screenBounds = app.frame
        XCTAssertGreaterThan(screenBounds.width, screenBounds.height) // 가로 모드 확인
        
        let quizModeButtons = [
            app.buttons["multiple_choice_mode"],
            app.buttons["short_answer_mode"]
        ]
        
        // 버튼들이 가로 공간을 효율적으로 사용하는지 확인
        for button in quizModeButtons {
            XCTAssertTrue(button.exists)
            XCTAssertTrue(button.isHittable)
        }
    }
    
    /// 가로 모드에서 퀴즈 플레이 테스트
    func testLandscapeQuizPlay() throws {
        // Given: 가로 모드에서 퀴즈 시작
        app.launchEnvironment["UITEST_ORIENTATION"] = "landscape"
        app.launch()
        
        try loginWithTestAccount()
        try startQuizSession()
        
        // When: 퀴즈 화면 확인
        let quizScreen = app.otherElements["quiz_play_screen"]
        XCTAssertTrue(quizScreen.exists)
        
        // Then: 가로 모드에서 콘텐츠가 적절히 배치되는지 확인
        let questionText = app.staticTexts["quiz_question"]
        XCTAssertTrue(questionText.exists)
        XCTAssertTrue(questionText.isHittable)
        
        // 선택지들이 가로 공간을 활용하는지 확인
        let option1 = app.buttons["quiz_option_0"]
        let option2 = app.buttons["quiz_option_1"]
        
        if option1.exists && option2.exists {
            let option1Frame = option1.frame
            let option2Frame = option2.frame
            
            // 가로 모드에서는 선택지들이 나란히 배치될 수 있음
            XCTAssertTrue(option1.isHittable)
            XCTAssertTrue(option2.isHittable)
        }
    }
    
    // MARK: - Dynamic Layout Tests
    
    /// 동적 레이아웃 변경 테스트
    func testDynamicLayoutChanges() throws {
        // Given: 기본 크기로 시작
        app.launch()
        try loginWithTestAccount()
        
        let mainScreen = app.otherElements["main_screen"]
        XCTAssertTrue(mainScreen.exists)
        
        // When: 화면 크기 변경 시뮬레이션 (iPad Split View 등)
        app.launchEnvironment["UITEST_LAYOUT_CHANGE"] = "compact"
        
        // Then: 레이아웃이 동적으로 적응하는지 확인
        let quizModeButtons = [
            app.buttons["multiple_choice_mode"],
            app.buttons["short_answer_mode"]
        ]
        
        for button in quizModeButtons {
            XCTAssertTrue(button.exists)
            XCTAssertTrue(button.isHittable)
        }
        
        // 컴팩트 모드에서도 모든 기능에 접근 가능한지 확인
        let profileTab = app.buttons["profile_tab"]
        XCTAssertTrue(profileTab.exists)
        XCTAssertTrue(profileTab.isHittable)
    }
    
    /// 텍스트 크기 변경에 따른 레이아웃 적응 테스트
    func testTextSizeLayoutAdaptation() throws {
        // Given: 매우 큰 텍스트 크기
        app.launchEnvironment["UITEST_CONTENT_SIZE"] = "accessibilityExtraExtraExtraLarge"
        app.launch()
        
        try loginWithTestAccount()
        try startQuizSession()
        
        // When: 퀴즈 화면에서 큰 텍스트 확인
        let questionText = app.staticTexts["quiz_question"]
        XCTAssertTrue(questionText.exists)
        
        // Then: 텍스트가 커져도 레이아웃이 깨지지 않는지 확인
        XCTAssertTrue(questionText.isHittable)
        
        let options = [
            app.buttons["quiz_option_0"],
            app.buttons["quiz_option_1"]
        ]
        
        for option in options {
            if option.exists {
                XCTAssertTrue(option.isHittable)
                
                // 큰 텍스트에서도 버튼이 충분한 크기를 가지는지 확인
                let optionFrame = option.frame
                XCTAssertGreaterThanOrEqual(optionFrame.height, 60) // 큰 텍스트용 최소 높이
            }
        }
        
        // 스크롤이 필요한 경우 스크롤 가능한지 확인
        let scrollView = app.scrollViews.element(boundBy: 0)
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }
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