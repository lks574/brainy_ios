import SwiftUI

extension Font {
    // MARK: - Display Fonts
    static let brainyDisplayLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let brainyDisplayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let brainyDisplaySmall = Font.system(size: 24, weight: .semibold, design: .rounded)
    
    // MARK: - Headline Fonts
    static let brainyHeadlineLarge = Font.system(size: 22, weight: .semibold, design: .default)
    static let brainyHeadlineMedium = Font.system(size: 20, weight: .semibold, design: .default)
    static let brainyHeadlineSmall = Font.system(size: 18, weight: .medium, design: .default)
    
    // MARK: - Title Fonts
    static let brainyTitleLarge = Font.system(size: 20, weight: .medium, design: .default)
    static let brainyTitleMedium = Font.system(size: 18, weight: .medium, design: .default)
    static let brainyTitleSmall = Font.system(size: 16, weight: .medium, design: .default)
    
    // MARK: - Body Fonts
    static let brainyBodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let brainyBodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let brainyBodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Label Fonts
    static let brainyLabelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let brainyLabelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let brainyLabelSmall = Font.system(size: 10, weight: .medium, design: .default)
    
    // MARK: - Quiz Specific Fonts
    static let brainyQuizQuestion = Font.system(size: 18, weight: .medium, design: .default)
    static let brainyQuizAnswer = Font.system(size: 16, weight: .regular, design: .default)
    static let brainyQuizScore = Font.system(size: 24, weight: .bold, design: .rounded)
}

// MARK: - Text Styles
struct BrainyTextStyle {
    let font: Font
    let color: Color
    let lineSpacing: CGFloat
    
    static let displayLarge = BrainyTextStyle(
        font: .brainyDisplayLarge,
        color: .brainyText,
        lineSpacing: 4
    )
    
    static let headlineLarge = BrainyTextStyle(
        font: .brainyHeadlineLarge,
        color: .brainyText,
        lineSpacing: 2
    )
    
    static let bodyLarge = BrainyTextStyle(
        font: .brainyBodyLarge,
        color: .brainyText,
        lineSpacing: 1
    )
    
    static let labelMedium = BrainyTextStyle(
        font: .brainyLabelMedium,
        color: .brainyTextSecondary,
        lineSpacing: 0
    )
}

// MARK: - Text Modifier
struct BrainyTextModifier: ViewModifier {
    let style: BrainyTextStyle
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(style.color)
            .lineSpacing(style.lineSpacing)
    }
}

extension View {
    func brainyTextStyle(_ style: BrainyTextStyle) -> some View {
        modifier(BrainyTextModifier(style: style))
    }
}