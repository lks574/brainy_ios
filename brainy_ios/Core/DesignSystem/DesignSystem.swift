import SwiftUI

// MARK: - Design System Export
// This file provides a centralized access point for all design system components

// Re-export all design system components
public typealias BrainyColors = Color
public typealias BrainyFonts = Font
public typealias BrainyTextStyles = BrainyTextStyle

// MARK: - Design System Constants
struct BrainyDesignSystem {
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 10
        static let xl: CGFloat = 12
        static let xxl: CGFloat = 16
    }
    
    // MARK: - Shadow
    struct Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let medium = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let large = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.1)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}

// MARK: - Common View Modifiers
extension View {
    /// Apply Brainy card style with shadow
    func brainyCardStyle(
        backgroundColor: Color = .brainyCardBackground,
        cornerRadius: CGFloat = BrainyDesignSystem.CornerRadius.xl,
        shadow: Bool = true
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow ? BrainyDesignSystem.Shadow.medium.color : .clear,
                radius: shadow ? BrainyDesignSystem.Shadow.medium.radius : 0,
                x: shadow ? BrainyDesignSystem.Shadow.medium.x : 0,
                y: shadow ? BrainyDesignSystem.Shadow.medium.y : 0
            )
    }
    
    /// Apply standard padding
    func brainyPadding(_ size: BrainyPaddingSize = .medium) -> some View {
        self.padding(size.value)
    }
    
    /// Apply Brainy text style
    func brainyText(_ style: BrainyTextStyle) -> some View {
        self.brainyTextStyle(style)
    }
}

// MARK: - Padding Sizes
enum BrainyPaddingSize {
    case small
    case medium
    case large
    
    var value: CGFloat {
        switch self {
        case .small:
            return BrainyDesignSystem.Spacing.sm
        case .medium:
            return BrainyDesignSystem.Spacing.lg
        case .large:
            return BrainyDesignSystem.Spacing.xl
        }
    }
}
