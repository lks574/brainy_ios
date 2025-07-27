import Foundation
import SwiftUI
import UIKit

/// 접근성 관리자
@MainActor
class AccessibilityManager: ObservableObject {
    // MARK: - Properties
    @Published var isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
    @Published var isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    @Published var isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
    @Published var isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
    @Published var isButtonShapesEnabled = UIAccessibility.isButtonShapesEnabled
    @Published var isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    @Published var preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    
    // MARK: - Singleton
    static let shared = AccessibilityManager()
    
    private init() {
        setupAccessibilityNotifications()
    }
    
    // MARK: - Setup
    
    private func setupAccessibilityNotifications() {
        // VoiceOver 상태 변경 알림
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        }
        
        // 모션 감소 설정 변경 알림
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        }
        
        // 투명도 감소 설정 변경 알림
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        }
        
        // 굵은 텍스트 설정 변경 알림
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.boldTextStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        }
        
        // 버튼 모양 설정 변경 알림
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isButtonShapesEnabled = UIAccessibility.isButtonShapesEnabled
        }
        
        // 어두운 색상 설정 변경 알림
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        }
        
        // 텍스트 크기 변경 알림
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        }
    }
    
    // MARK: - Accessibility Helpers
    
    /// VoiceOver 포커스 설정
    func setVoiceOverFocus(to view: UIView) {
        guard isVoiceOverEnabled else { return }
        UIAccessibility.post(notification: .screenChanged, argument: view)
    }
    
    /// VoiceOver 알림 발송
    func announceForVoiceOver(_ message: String) {
        guard isVoiceOverEnabled else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    /// 레이아웃 변경 알림
    func announceLayoutChange(focusedElement: Any? = nil) {
        guard isVoiceOverEnabled else { return }
        UIAccessibility.post(notification: .layoutChanged, argument: focusedElement)
    }
    
    /// 화면 변경 알림
    func announceScreenChange(focusedElement: Any? = nil) {
        guard isVoiceOverEnabled else { return }
        UIAccessibility.post(notification: .screenChanged, argument: focusedElement)
    }
    
    /// 페이지 스크롤 알림
    func announcePageScrolled() {
        guard isVoiceOverEnabled else { return }
        UIAccessibility.post(notification: .pageScrolled, argument: nil)
    }
    
    // MARK: - Dynamic Type Support
    
    /// 동적 타입 크기가 큰지 확인
    var isLargeContentSize: Bool {
        return preferredContentSizeCategory.isAccessibilityCategory
    }
    
    /// 동적 타입 크기가 매우 큰지 확인
    var isExtraLargeContentSize: Bool {
        return preferredContentSizeCategory >= .accessibilityLarge
    }
    
    /// 텍스트 크기 배율 반환
    var textSizeMultiplier: CGFloat {
        switch preferredContentSizeCategory {
        case .extraSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium:
            return 1.0
        case .large:
            return 1.1
        case .extraLarge:
            return 1.2
        case .extraExtraLarge:
            return 1.3
        case .extraExtraExtraLarge:
            return 1.4
        case .accessibilityMedium:
            return 1.6
        case .accessibilityLarge:
            return 1.8
        case .accessibilityExtraLarge:
            return 2.0
        case .accessibilityExtraExtraLarge:
            return 2.2
        case .accessibilityExtraExtraExtraLarge:
            return 2.4
        default:
            return 1.0
        }
    }
    
    // MARK: - Animation Support
    
    /// 애니메이션 지속 시간 (모션 감소 고려)
    func animationDuration(_ defaultDuration: TimeInterval) -> TimeInterval {
        return isReduceMotionEnabled ? 0.0 : defaultDuration
    }
    
    /// 스프링 애니메이션 (모션 감소 고려)
    func springAnimation(response: Double = 0.5, dampingFraction: Double = 0.8) -> Animation {
        if isReduceMotionEnabled {
            return .linear(duration: 0.0)
        } else {
            return .spring(response: response, dampingFraction: dampingFraction)
        }
    }
    
    /// 이징 애니메이션 (모션 감소 고려)
    func easingAnimation(duration: TimeInterval = 0.3) -> Animation {
        if isReduceMotionEnabled {
            return .linear(duration: 0.0)
        } else {
            return .easeInOut(duration: duration)
        }
    }
    
    // MARK: - Color Contrast Support
    
    /// 고대비 색상 반환
    func contrastColor(for color: Color) -> Color {
        if isDarkerSystemColorsEnabled {
            // 더 어두운 색상 반환
            return color.opacity(0.8)
        }
        return color
    }
    
    /// 배경색과 텍스트색의 대비 확인
    func hasGoodContrast(background: Color, text: Color) -> Bool {
        // 간단한 대비 확인 (실제로는 더 복잡한 계산 필요)
        return true // 실제 구현에서는 WCAG 가이드라인에 따른 대비 계산
    }
    
    // MARK: - Button Shape Support
    
    /// 버튼 모양 강조 여부
    var shouldEmphasizeButtonShapes: Bool {
        return isButtonShapesEnabled
    }
    
    // MARK: - Accessibility Traits
    
    /// 퀴즈 문제에 대한 접근성 레이블 생성
    func quizQuestionAccessibilityLabel(
        question: String,
        questionNumber: Int,
        totalQuestions: Int,
        category: String
    ) -> String {
        return "\(category) 카테고리, \(totalQuestions)개 문제 중 \(questionNumber)번째 문제. \(question)"
    }
    
    /// 퀴즈 선택지에 대한 접근성 레이블 생성
    func quizOptionAccessibilityLabel(
        option: String,
        optionNumber: Int,
        totalOptions: Int,
        isSelected: Bool = false
    ) -> String {
        let selectionStatus = isSelected ? "선택됨" : "선택 안됨"
        return "\(totalOptions)개 선택지 중 \(optionNumber)번. \(option). \(selectionStatus)"
    }
    
    /// 점수에 대한 접근성 레이블 생성
    func scoreAccessibilityLabel(correct: Int, total: Int) -> String {
        let percentage = Int(Double(correct) / Double(total) * 100)
        return "\(total)문제 중 \(correct)문제 정답. 정답률 \(percentage)퍼센트"
    }
    
    /// 시간에 대한 접근성 레이블 생성
    func timeAccessibilityLabel(seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        let remainingSeconds = Int(seconds.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)분 \(remainingSeconds)초"
        } else {
            return "\(remainingSeconds)초"
        }
    }
    
    /// 진행률에 대한 접근성 레이블 생성
    func progressAccessibilityLabel(current: Int, total: Int) -> String {
        let percentage = Int(Double(current) / Double(total) * 100)
        return "\(total)개 중 \(current)개 완료. 진행률 \(percentage)퍼센트"
    }
}

// MARK: - Accessibility Modifiers

extension View {
    /// VoiceOver 레이블 설정
    func accessibilityLabel(_ label: String) -> some View {
        self.accessibilityLabel(Text(label))
    }
    
    /// VoiceOver 힌트 설정
    func accessibilityHint(_ hint: String) -> some View {
        self.accessibilityHint(Text(hint))
    }
    
    /// VoiceOver 값 설정
    func accessibilityValue(_ value: String) -> some View {
        self.accessibilityValue(Text(value))
    }
    
    /// 퀴즈 문제 접근성 설정
    func quizQuestionAccessibility(
        question: String,
        questionNumber: Int,
        totalQuestions: Int,
        category: String
    ) -> some View {
        let accessibilityManager = AccessibilityManager.shared
        let label = accessibilityManager.quizQuestionAccessibilityLabel(
            question: question,
            questionNumber: questionNumber,
            totalQuestions: totalQuestions,
            category: category
        )
        
        return self
            .accessibilityLabel(label)
            .accessibilityTraits(.staticText)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// 퀴즈 선택지 접근성 설정
    func quizOptionAccessibility(
        option: String,
        optionNumber: Int,
        totalOptions: Int,
        isSelected: Bool = false
    ) -> some View {
        let accessibilityManager = AccessibilityManager.shared
        let label = accessibilityManager.quizOptionAccessibilityLabel(
            option: option,
            optionNumber: optionNumber,
            totalOptions: totalOptions,
            isSelected: isSelected
        )
        
        return self
            .accessibilityLabel(label)
            .accessibilityTraits(.button)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint("선택하려면 두 번 탭하세요")
    }
    
    /// 점수 접근성 설정
    func scoreAccessibility(correct: Int, total: Int) -> some View {
        let accessibilityManager = AccessibilityManager.shared
        let label = accessibilityManager.scoreAccessibilityLabel(correct: correct, total: total)
        
        return self
            .accessibilityLabel(label)
            .accessibilityTraits(.staticText)
    }
    
    /// 진행률 접근성 설정
    func progressAccessibility(current: Int, total: Int) -> some View {
        let accessibilityManager = AccessibilityManager.shared
        let label = accessibilityManager.progressAccessibilityLabel(current: current, total: total)
        
        return self
            .accessibilityLabel(label)
            .accessibilityTraits(.updatesFrequently)
    }
    
    /// 동적 타입 지원
    func dynamicTypeSize(min: DynamicTypeSize = .xSmall, max: DynamicTypeSize = .accessibility5) -> some View {
        self.dynamicTypeSize(min...max)
    }
    
    /// 모션 감소 고려 애니메이션
    func accessibleAnimation(_ animation: Animation?) -> some View {
        let accessibilityManager = AccessibilityManager.shared
        if accessibilityManager.isReduceMotionEnabled {
            return self.animation(nil, value: UUID())
        } else {
            return self.animation(animation, value: UUID())
        }
    }
    
    /// 고대비 색상 적용
    func accessibleForegroundColor(_ color: Color) -> some View {
        let accessibilityManager = AccessibilityManager.shared
        return self.foregroundColor(accessibilityManager.contrastColor(for: color))
    }
    
    /// 버튼 모양 강조
    func accessibleButtonStyle() -> some View {
        let accessibilityManager = AccessibilityManager.shared
        
        if accessibilityManager.shouldEmphasizeButtonShapes {
            return self
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.brainyPrimary, lineWidth: 2)
                )
        } else {
            return self
        }
    }
}