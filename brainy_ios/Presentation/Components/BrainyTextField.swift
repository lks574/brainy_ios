import SwiftUI

struct BrainyTextField: View {
    @Binding var text: String
    let placeholder: String
    let style: BrainyTextFieldStyle
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    let isEnabled: Bool
    let errorMessage: String?
    let leadingIcon: String?
    let trailingIcon: String?
    let onTrailingIconTap: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    init(
        text: Binding<String>,
        placeholder: String,
        style: BrainyTextFieldStyle = .default,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        isEnabled: Bool = true,
        errorMessage: String? = nil,
        leadingIcon: String? = nil,
        trailingIcon: String? = nil,
        onTrailingIconTap: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.style = style
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.isEnabled = isEnabled
        self.errorMessage = errorMessage
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.onTrailingIconTap = onTrailingIconTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                // Leading Icon
                if let leadingIcon = leadingIcon {
                    Image(systemName: leadingIcon)
                        .foregroundColor(iconColor)
                        .frame(width: 20, height: 20)
                }
                
                // Text Field
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.brainyBodyLarge)
                .foregroundColor(.brainyText)
                .keyboardType(keyboardType)
                .focused($isFocused)
                .disabled(!isEnabled)
                
                // Trailing Icon
                if let trailingIcon = trailingIcon {
                    Button(action: onTrailingIconTap ?? {}) {
                        Image(systemName: trailingIcon)
                            .foregroundColor(iconColor)
                            .frame(width: 20, height: 20)
                    }
                    .disabled(onTrailingIconTap == nil)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(style.backgroundColor)
            .cornerRadius(style.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .opacity(isEnabled ? 1.0 : 0.6)
            
            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.brainyLabelMedium)
                    .foregroundColor(.brainyError)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    private var borderColor: Color {
        if errorMessage != nil {
            return .brainyError
        } else if isFocused {
            return .brainyPrimary
        } else {
            return style.borderColor
        }
    }
    
    private var borderWidth: CGFloat {
        if errorMessage != nil || isFocused {
            return 2
        } else {
            return style.borderWidth
        }
    }
    
    private var iconColor: Color {
        if errorMessage != nil {
            return .brainyError
        } else if isFocused {
            return .brainyPrimary
        } else {
            return .brainyTextSecondary
        }
    }
}

// MARK: - Text Field Styles
enum BrainyTextFieldStyle {
    case `default`
    case outlined
    case filled
    
    var backgroundColor: Color {
        switch self {
        case .default:
            return .brainyBackground
        case .outlined:
            return .clear
        case .filled:
            return .brainySurface
        }
    }
    
    var borderColor: Color {
        switch self {
        case .default, .filled:
            return .brainyTextSecondary.opacity(0.3)
        case .outlined:
            return .brainyTextSecondary.opacity(0.5)
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .default, .filled:
            return 1
        case .outlined:
            return 1.5
        }
    }
    
    var cornerRadius: CGFloat {
        return 10
    }
}

// MARK: - Specialized Text Fields
struct BrainySearchField: View {
    @Binding var text: String
    let placeholder: String
    let onSearchTap: (() -> Void)?
    
    init(
        text: Binding<String>,
        placeholder: String = "검색...",
        onSearchTap: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearchTap = onSearchTap
    }
    
    var body: some View {
        BrainyTextField(
            text: $text,
            placeholder: placeholder,
            style: .filled,
            leadingIcon: "magnifyingglass",
            trailingIcon: text.isEmpty ? nil : "xmark.circle.fill",
            onTrailingIconTap: text.isEmpty ? nil : {
                text = ""
            }
        )
    }
}

struct BrainyPasswordField: View {
    @Binding var password: String
    @State private var isPasswordVisible = false
    let placeholder: String
    let errorMessage: String?
    
    init(
        password: Binding<String>,
        placeholder: String = "비밀번호",
        errorMessage: String? = nil
    ) {
        self._password = password
        self.placeholder = placeholder
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        BrainyTextField(
            text: $password,
            placeholder: placeholder,
            isSecure: !isPasswordVisible,
            errorMessage: errorMessage,
            leadingIcon: "lock",
            trailingIcon: isPasswordVisible ? "eye.slash" : "eye",
            onTrailingIconTap: {
                isPasswordVisible.toggle()
            }
        )
    }
}
