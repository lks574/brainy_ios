import SwiftUI

struct BrainyButton: View {
    let title: String
    let action: () -> Void
    let style: BrainyButtonStyle
    let size: BrainyButtonSize
    let isEnabled: Bool
    let isLoading: Bool
    
    init(
        _ title: String,
        style: BrainyButtonStyle = .primary,
        size: BrainyButtonSize = .medium,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(style.foregroundColor)
                }
                
                if !isLoading {
                    Text(title)
                        .font(size.font)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .foregroundColor(style.foregroundColor)
            .background(style.backgroundColor)
            .cornerRadius(size.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.1), value: isEnabled)
    }
}

// MARK: - Button Styles
enum BrainyButtonStyle {
    case primary
    case secondary
    case outline
    case ghost
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return .brainyPrimary
        case .secondary:
            return .brainySecondary
        case .outline, .ghost:
            return .clear
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary, .secondary:
            return .white
        case .outline:
            return .brainyPrimary
        case .ghost:
            return .brainyText
        }
    }
    
    var borderColor: Color {
        switch self {
        case .primary, .secondary:
            return .clear
        case .outline:
            return .brainyPrimary
        case .ghost:
            return .clear
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .primary, .secondary, .ghost:
            return 0
        case .outline:
            return 1
        }
    }
}

// MARK: - Button Sizes
enum BrainyButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small:
            return 36
        case .medium:
            return 44
        case .large:
            return 52
        }
    }
    
    var font: Font {
        switch self {
        case .small:
            return .brainyLabelMedium
        case .medium:
            return .brainyBodyLarge
        case .large:
            return .brainyTitleMedium
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small:
            return 8
        case .medium:
            return 10
        case .large:
            return 12
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        BrainyButton("Primary Button", style: .primary) {
            print("Primary tapped")
        }
        
        BrainyButton("Secondary Button", style: .secondary) {
            print("Secondary tapped")
        }
        
        BrainyButton("Outline Button", style: .outline) {
            print("Outline tapped")
        }
        
        BrainyButton("Ghost Button", style: .ghost) {
            print("Ghost tapped")
        }
        
        BrainyButton("Loading Button", style: .primary, isLoading: true) {
            print("Loading tapped")
        }
        
        BrainyButton("Disabled Button", style: .primary, isEnabled: false) {
            print("Disabled tapped")
        }
    }
    .padding()
}
