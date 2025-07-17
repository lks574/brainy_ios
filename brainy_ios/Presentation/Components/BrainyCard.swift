import SwiftUI

struct BrainyCard<Content: View>: View {
    let content: Content
    let style: BrainyCardStyle
    let padding: EdgeInsets
    let cornerRadius: CGFloat
    let shadow: BrainyCardShadow
    
    init(
        style: BrainyCardStyle = .default,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = 12,
        shadow: BrainyCardShadow = .medium,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(style.backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// MARK: - Card Styles
enum BrainyCardStyle {
    case `default`
    case elevated
    case outlined
    case quiz
    case result
    
    var backgroundColor: Color {
        switch self {
        case .default, .elevated, .outlined:
            return .brainyCardBackground
        case .quiz:
            return .brainySurface
        case .result:
            return .brainyBackground
        }
    }
    
    var borderColor: Color {
        switch self {
        case .default, .elevated, .quiz, .result:
            return .clear
        case .outlined:
            return .brainyTextSecondary.opacity(0.2)
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .default, .elevated, .quiz, .result:
            return 0
        case .outlined:
            return 1
        }
    }
}

// MARK: - Card Shadow
enum BrainyCardShadow {
    case none
    case small
    case medium
    case large
    
    var color: Color {
        switch self {
        case .none:
            return .clear
        case .small, .medium, .large:
            return .black.opacity(0.1)
        }
    }
    
    var radius: CGFloat {
        switch self {
        case .none:
            return 0
        case .small:
            return 2
        case .medium:
            return 4
        case .large:
            return 8
        }
    }
    
    var x: CGFloat {
        return 0
    }
    
    var y: CGFloat {
        switch self {
        case .none:
            return 0
        case .small:
            return 1
        case .medium:
            return 2
        case .large:
            return 4
        }
    }
}

// MARK: - Specialized Card Components
struct BrainyQuizCard<Content: View>: View {
    let content: Content
    let isSelected: Bool
    let isCorrect: Bool?
    let onTap: (() -> Void)?
    
    init(
        isSelected: Bool = false,
        isCorrect: Bool? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.isSelected = isSelected
        self.isCorrect = isCorrect
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap ?? {}) {
            BrainyCard(
                style: .quiz,
                shadow: isSelected ? .medium : .small
            ) {
                content
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil)
    }
    
    private var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .brainyCorrect : .brainyIncorrect
        } else if isSelected {
            return .brainySelected
        } else {
            return .clear
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            BrainyCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Card")
                        .font(.brainyHeadlineMedium)
                        .foregroundColor(.brainyText)
                    
                    Text("This is a default card with some content inside.")
                        .font(.brainyBodyLarge)
                        .foregroundColor(.brainyTextSecondary)
                }
            }
            
            BrainyCard(style: .elevated, shadow: .large) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Elevated Card")
                        .font(.brainyHeadlineMedium)
                        .foregroundColor(.brainyText)
                    
                    Text("This card has a larger shadow for elevation.")
                        .font(.brainyBodyLarge)
                        .foregroundColor(.brainyTextSecondary)
                }
            }
            
            BrainyCard(style: .outlined) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Outlined Card")
                        .font(.brainyHeadlineMedium)
                        .foregroundColor(.brainyText)
                    
                    Text("This card has a border outline.")
                        .font(.brainyBodyLarge)
                        .foregroundColor(.brainyTextSecondary)
                }
            }
            
            BrainyQuizCard(isSelected: true) {
                Text("Selected Quiz Option")
                    .font(.brainyBodyLarge)
                    .foregroundColor(.brainyText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            BrainyQuizCard(isCorrect: true) {
                Text("Correct Answer")
                    .font(.brainyBodyLarge)
                    .foregroundColor(.brainyText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            BrainyQuizCard(isCorrect: false) {
                Text("Incorrect Answer")
                    .font(.brainyBodyLarge)
                    .foregroundColor(.brainyText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}