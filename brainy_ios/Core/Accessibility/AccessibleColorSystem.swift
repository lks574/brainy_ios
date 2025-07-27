import Foundation
import SwiftUI

/// 접근성을 고려한 색상 시스템
struct AccessibleColorSystem {
    // MARK: - Color Contrast Ratios (WCAG 2.1 기준)
    static let minimumContrastRatio: Double = 4.5 // AA 등급
    static let enhancedContrastRatio: Double = 7.0 // AAA 등급
    
    // MARK: - Accessible Color Palette
    
    /// 기본 색상 팔레트 (접근성 고려)
    struct Colors {
        // Primary Colors (충분한 대비 보장)
        static let primary = Color(red: 0.0, green: 0.48, blue: 0.8) // #007ACC
        static let primaryDark = Color(red: 0.0, green: 0.36, blue: 0.6) // #005C99
        static let primaryLight = Color(red: 0.2, green: 0.6, blue: 0.9) // #3399E6
        
        // Secondary Colors
        static let secondary = Color(red: 0.4, green: 0.4, blue: 0.4) // #666666
        static let secondaryDark = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
        static let secondaryLight = Color(red: 0.6, green: 0.6, blue: 0.6) // #999999
        
        // Semantic Colors
        static let success = Color(red: 0.0, green: 0.6, blue: 0.0) // #009900
        static let warning = Color(red: 0.8, green: 0.6, blue: 0.0) // #CC9900
        static let error = Color(red: 0.8, green: 0.0, blue: 0.0) // #CC0000
        static let info = Color(red: 0.0, green: 0.4, blue: 0.8) // #0066CC
        
        // Background Colors
        static let backgroundPrimary = Color(red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF
        static let backgroundSecondary = Color(red: 0.96, green: 0.96, blue: 0.96) // #F5F5F5
        static let backgroundTertiary = Color(red: 0.92, green: 0.92, blue: 0.92) // #EBEBEB
        
        // Text Colors
        static let textPrimary = Color(red: 0.13, green: 0.13, blue: 0.13) // #212121
        static let textSecondary = Color(red: 0.38, green: 0.38, blue: 0.38) // #616161
        static let textTertiary = Color(red: 0.62, green: 0.62, blue: 0.62) // #9E9E9E
        
        // Dark Mode Colors
        static let darkBackgroundPrimary = Color(red: 0.07, green: 0.07, blue: 0.07) // #121212
        static let darkBackgroundSecondary = Color(red: 0.12, green: 0.12, blue: 0.12) // #1E1E1E
        static let darkTextPrimary = Color(red: 0.87, green: 0.87, blue: 0.87) // #DEDEDE
        static let darkTextSecondary = Color(red: 0.74, green: 0.74, blue: 0.74) // #BDBDBD
    }
    
    // MARK: - Color Contrast Calculation
    
    /// 두 색상 간의 대비 비율 계산
    static func contrastRatio(between color1: Color, and color2: Color) -> Double {
        let luminance1 = relativeLuminance(of: color1)
        let luminance2 = relativeLuminance(of: color2)
        
        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// 색상의 상대 휘도 계산
    private static func relativeLuminance(of color: Color) -> Double {
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        let red = gammaCorrect(components[0])
        let green = gammaCorrect(components[1])
        let blue = gammaCorrect(components[2])
        
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }
    
    /// 감마 보정
    private static func gammaCorrect(_ value: CGFloat) -> Double {
        let normalizedValue = Double(value)
        if normalizedValue <= 0.03928 {
            return normalizedValue / 12.92
        } else {
            return pow((normalizedValue + 0.055) / 1.055, 2.4)
        }
    }
    
    // MARK: - Accessibility Validation
    
    /// 색상 조합이 WCAG AA 기준을 만족하는지 확인
    static func meetsAAStandard(foreground: Color, background: Color) -> Bool {
        return contrastRatio(between: foreground, and: background) >= minimumContrastRatio
    }
    
    /// 색상 조합이 WCAG AAA 기준을 만족하는지 확인
    static func meetsAAAStandard(foreground: Color, background: Color) -> Bool {
        return contrastRatio(between: foreground, and: background) >= enhancedContrastRatio
    }
    
    /// 접근성을 고려한 색상 조합 추천
    static func recommendedTextColor(for backgroundColor: Color) -> Color {
        let whiteContrast = contrastRatio(between: .white, and: backgroundColor)
        let blackContrast = contrastRatio(between: .black, and: backgroundColor)
        
        return whiteContrast > blackContrast ? .white : .black
    }
    
    // MARK: - Dynamic Color Adjustment
    
    /// 시스템 설정에 따른 색상 조정
    static func adjustedColor(_ color: Color, for environment: EnvironmentValues) -> Color {
        var adjustedColor = color
        
        // 다크 모드 지원
        if environment.colorScheme == .dark {
            adjustedColor = darkModeVariant(of: color)
        }
        
        // 고대비 모드 지원
        if environment.accessibilityDifferentiateWithoutColor {
            adjustedColor = highContrastVariant(of: adjustedColor)
        }
        
        // 색상 반전 지원
        if environment.accessibilityInvertColors {
            adjustedColor = invertedColor(adjustedColor)
        }
        
        return adjustedColor
    }
    
    /// 다크 모드 색상 변형
    private static func darkModeVariant(of color: Color) -> Color {
        // 기본 색상들의 다크 모드 변형 반환
        switch color {
        case Colors.primary:
            return Colors.primaryLight
        case Colors.backgroundPrimary:
            return Colors.darkBackgroundPrimary
        case Colors.backgroundSecondary:
            return Colors.darkBackgroundSecondary
        case Colors.textPrimary:
            return Colors.darkTextPrimary
        case Colors.textSecondary:
            return Colors.darkTextSecondary
        default:
            return color
        }
    }
    
    /// 고대비 색상 변형
    private static func highContrastVariant(of color: Color) -> Color {
        // 고대비 모드에서 더 강한 대비를 위한 색상 조정
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        let brightness = (components[0] + components[1] + components[2]) / 3
        
        if brightness > 0.5 {
            return Color.white
        } else {
            return Color.black
        }
    }
    
    /// 색상 반전
    private static func invertedColor(_ color: Color) -> Color {
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        return Color(
            red: 1.0 - components[0],
            green: 1.0 - components[1],
            blue: 1.0 - components[2],
            opacity: components[3]
        )
    }
}

// MARK: - Accessible Color Extensions

extension Color {
    /// 접근성을 고려한 브레이니 색상들
    static var accessibleBrainyPrimary: Color {
        AccessibleColorSystem.Colors.primary
    }
    
    static var accessibleBrainySecondary: Color {
        AccessibleColorSystem.Colors.secondary
    }
    
    static var accessibleBrainySuccess: Color {
        AccessibleColorSystem.Colors.success
    }
    
    static var accessibleBrainyWarning: Color {
        AccessibleColorSystem.Colors.warning
    }
    
    static var accessibleBrainyError: Color {
        AccessibleColorSystem.Colors.error
    }
    
    static var accessibleBrainyInfo: Color {
        AccessibleColorSystem.Colors.info
    }
    
    static var accessibleBrainyBackground: Color {
        AccessibleColorSystem.Colors.backgroundPrimary
    }
    
    static var accessibleBrainySurface: Color {
        AccessibleColorSystem.Colors.backgroundSecondary
    }
    
    static var accessibleBrainyText: Color {
        AccessibleColorSystem.Colors.textPrimary
    }
    
    static var accessibleBrainyTextSecondary: Color {
        AccessibleColorSystem.Colors.textSecondary
    }
    
    /// 배경색에 대한 최적의 텍스트 색상 반환
    func optimalTextColor() -> Color {
        return AccessibleColorSystem.recommendedTextColor(for: self)
    }
    
    /// 다른 색상과의 대비 비율 확인
    func contrastRatio(with otherColor: Color) -> Double {
        return AccessibleColorSystem.contrastRatio(between: self, and: otherColor)
    }
    
    /// WCAG AA 기준 만족 여부 확인
    func meetsAAStandard(with backgroundColor: Color) -> Bool {
        return AccessibleColorSystem.meetsAAStandard(foreground: self, background: backgroundColor)
    }
    
    /// WCAG AAA 기준 만족 여부 확인
    func meetsAAAStandard(with backgroundColor: Color) -> Bool {
        return AccessibleColorSystem.meetsAAAStandard(foreground: self, background: backgroundColor)
    }
}

// MARK: - Accessible Color Modifier

struct AccessibleColorModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.accessibilityInvertColors) var invertColors
    
    let originalColor: Color
    
    func body(content: Content) -> some View {
        let adjustedColor = AccessibleColorSystem.adjustedColor(
            originalColor,
            for: EnvironmentValues()
        )
        
        content.foregroundColor(adjustedColor)
    }
}

extension View {
    /// 접근성을 고려한 색상 적용
    func accessibleColor(_ color: Color) -> some View {
        self.modifier(AccessibleColorModifier(originalColor: color))
    }
    
    /// 접근성을 고려한 배경색 적용
    func accessibleBackground(_ color: Color) -> some View {
        self.background(
            AccessibleColorSystem.adjustedColor(color, for: EnvironmentValues())
        )
    }
}

// MARK: - Color Contrast Validator

/// 색상 대비 검증기
struct ColorContrastValidator {
    /// 앱의 모든 색상 조합 검증
    static func validateAppColors() -> [ColorValidationResult] {
        var results: [ColorValidationResult] = []
        
        // 주요 색상 조합들 검증
        let colorCombinations: [(foreground: Color, background: Color, context: String)] = [
            (.accessibleBrainyText, .accessibleBrainyBackground, "기본 텍스트"),
            (.accessibleBrainyTextSecondary, .accessibleBrainyBackground, "보조 텍스트"),
            (.white, .accessibleBrainyPrimary, "기본 버튼"),
            (.accessibleBrainyPrimary, .accessibleBrainyBackground, "링크 텍스트"),
            (.accessibleBrainyError, .accessibleBrainyBackground, "에러 텍스트"),
            (.accessibleBrainySuccess, .accessibleBrainyBackground, "성공 텍스트"),
            (.accessibleBrainyWarning, .accessibleBrainyBackground, "경고 텍스트")
        ]
        
        for combination in colorCombinations {
            let contrastRatio = AccessibleColorSystem.contrastRatio(
                between: combination.foreground,
                and: combination.background
            )
            
            let result = ColorValidationResult(
                context: combination.context,
                foregroundColor: combination.foreground,
                backgroundColor: combination.background,
                contrastRatio: contrastRatio,
                meetsAA: contrastRatio >= AccessibleColorSystem.minimumContrastRatio,
                meetsAAA: contrastRatio >= AccessibleColorSystem.enhancedContrastRatio
            )
            
            results.append(result)
        }
        
        return results
    }
}

/// 색상 검증 결과
struct ColorValidationResult {
    let context: String
    let foregroundColor: Color
    let backgroundColor: Color
    let contrastRatio: Double
    let meetsAA: Bool
    let meetsAAA: Bool
    
    var status: String {
        if meetsAAA {
            return "AAA (우수)"
        } else if meetsAA {
            return "AA (양호)"
        } else {
            return "부적합"
        }
    }
    
    var statusColor: Color {
        if meetsAAA {
            return .green
        } else if meetsAA {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Color Accessibility Debug View

#if DEBUG
struct ColorAccessibilityDebugView: View {
    @State private var validationResults: [ColorValidationResult] = []
    
    var body: some View {
        NavigationView {
            List(validationResults, id: \.context) { result in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(result.context)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(result.status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(result.statusColor.opacity(0.2))
                            .foregroundColor(result.statusColor)
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Rectangle()
                            .fill(result.backgroundColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Rectangle()
                                    .fill(result.foregroundColor)
                                    .frame(width: 20, height: 20)
                            )
                        
                        VStack(alignment: .leading) {
                            Text("대비 비율: \(String(format: "%.2f", result.contrastRatio)):1")
                                .font(.caption)
                            
                            Text("AA: \(result.meetsAA ? "✓" : "✗") | AAA: \(result.meetsAAA ? "✓" : "✗")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("색상 접근성 검증")
            .onAppear {
                validationResults = ColorContrastValidator.validateAppColors()
            }
        }
    }
}
#endif