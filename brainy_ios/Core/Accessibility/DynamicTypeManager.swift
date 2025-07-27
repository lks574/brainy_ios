import Foundation
import SwiftUI

/// 동적 타입 크기 관리자
@MainActor
class DynamicTypeManager: ObservableObject {
    // MARK: - Properties
    @Published var currentSizeCategory: ContentSizeCategory = .medium
    @Published var isAccessibilitySize: Bool = false
    @Published var scaleFactor: CGFloat = 1.0
    
    // MARK: - Singleton
    static let shared = DynamicTypeManager()
    
    private init() {
        updateSizeCategory()
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateSizeCategory()
        }
    }
    
    private func updateSizeCategory() {
        let uiCategory = UIApplication.shared.preferredContentSizeCategory
        currentSizeCategory = ContentSizeCategory(uiCategory)
        isAccessibilitySize = uiCategory.isAccessibilityCategory
        scaleFactor = getScaleFactor(for: uiCategory)
    }
    
    // MARK: - Scale Factor Calculation
    
    private func getScaleFactor(for category: UIContentSizeCategory) -> CGFloat {
        switch category {
        case .extraSmall:
            return 0.82
        case .small:
            return 0.88
        case .medium:
            return 1.0
        case .large:
            return 1.12
        case .extraLarge:
            return 1.23
        case .extraExtraLarge:
            return 1.35
        case .extraExtraExtraLarge:
            return 1.47
        case .accessibilityMedium:
            return 1.64
        case .accessibilityLarge:
            return 1.95
        case .accessibilityExtraLarge:
            return 2.35
        case .accessibilityExtraExtraLarge:
            return 2.76
        case .accessibilityExtraExtraExtraLarge:
            return 3.12
        default:
            return 1.0
        }
    }
    
    // MARK: - Font Scaling
    
    /// 기본 폰트 크기에 스케일 팩터 적용
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let scaledSize = size * scaleFactor
        return .system(size: scaledSize, weight: weight)
    }
    
    /// 커스텀 폰트에 스케일 팩터 적용
    func scaledCustomFont(name: String, size: CGFloat) -> Font {
        let scaledSize = size * scaleFactor
        return .custom(name, size: scaledSize)
    }
    
    /// 최대 크기 제한이 있는 스케일된 폰트
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, maxSize: CGFloat) -> Font {
        let scaledSize = min(size * scaleFactor, maxSize)
        return .system(size: scaledSize, weight: weight)
    }
    
    // MARK: - Layout Scaling
    
    /// 패딩 값 스케일링
    func scaledPadding(_ padding: CGFloat) -> CGFloat {
        return padding * min(scaleFactor, 1.5) // 패딩은 최대 1.5배까지만
    }
    
    /// 아이콘 크기 스케일링
    func scaledIconSize(_ size: CGFloat) -> CGFloat {
        return size * min(scaleFactor, 2.0) // 아이콘은 최대 2배까지만
    }
    
    /// 버튼 높이 스케일링
    func scaledButtonHeight(_ height: CGFloat) -> CGFloat {
        return height * min(scaleFactor, 1.8) // 버튼 높이는 최대 1.8배까지만
    }
    
    /// 간격 스케일링
    func scaledSpacing(_ spacing: CGFloat) -> CGFloat {
        return spacing * min(scaleFactor, 1.3) // 간격은 최대 1.3배까지만
    }
    
    // MARK: - Responsive Layout
    
    /// 접근성 크기에서 레이아웃 변경이 필요한지 확인
    var shouldUseVerticalLayout: Bool {
        return isAccessibilitySize
    }
    
    /// 접근성 크기에서 텍스트 줄바꿈이 필요한지 확인
    var shouldWrapText: Bool {
        return scaleFactor > 1.5
    }
    
    /// 접근성 크기에서 간소화된 UI가 필요한지 확인
    var shouldSimplifyUI: Bool {
        return scaleFactor > 2.0
    }
    
    // MARK: - Content Size Categories
    
    /// 현재 크기 카테고리가 작은 크기인지 확인
    var isSmallSize: Bool {
        return scaleFactor < 1.0
    }
    
    /// 현재 크기 카테고리가 큰 크기인지 확인
    var isLargeSize: Bool {
        return scaleFactor > 1.3
    }
    
    /// 현재 크기 카테고리가 매우 큰 크기인지 확인
    var isExtraLargeSize: Bool {
        return scaleFactor > 2.0
    }
}

// MARK: - Dynamic Type Extensions

extension Font {
    /// 동적 타입을 고려한 브레이니 타이틀 폰트
    static var brainyDynamicTitle: Font {
        let manager = DynamicTypeManager.shared
        return manager.scaledFont(size: 28, weight: .bold)
    }
    
    /// 동적 타입을 고려한 브레이니 헤드라인 폰트
    static var brainyDynamicHeadline: Font {
        let manager = DynamicTypeManager.shared
        return manager.scaledFont(size: 22, weight: .semibold)
    }
    
    /// 동적 타입을 고려한 브레이니 바디 폰트
    static var brainyDynamicBody: Font {
        let manager = DynamicTypeManager.shared
        return manager.scaledFont(size: 16, weight: .regular)
    }
    
    /// 동적 타입을 고려한 브레이니 캡션 폰트
    static var brainyDynamicCaption: Font {
        let manager = DynamicTypeManager.shared
        return manager.scaledFont(size: 12, weight: .medium)
    }
    
    /// 동적 타입을 고려한 브레이니 버튼 폰트
    static var brainyDynamicButton: Font {
        let manager = DynamicTypeManager.shared
        return manager.scaledFont(size: 16, weight: .semibold)
    }
}

// MARK: - View Extensions

extension View {
    /// 동적 타입 스케일링 적용
    func dynamicTypeScaling() -> some View {
        let manager = DynamicTypeManager.shared
        return self.scaleEffect(manager.scaleFactor)
    }
    
    /// 동적 패딩 적용
    func dynamicPadding(_ edges: Edge.Set = .all, _ length: CGFloat) -> some View {
        let manager = DynamicTypeManager.shared
        let scaledPadding = manager.scaledPadding(length)
        return self.padding(edges, scaledPadding)
    }
    
    /// 동적 간격 적용
    func dynamicSpacing(_ spacing: CGFloat) -> some View {
        let manager = DynamicTypeManager.shared
        let scaledSpacing = manager.scaledSpacing(spacing)
        
        if let vstack = self as? VStack<TupleView<(some View, some View)>> {
            return AnyView(vstack)
        } else if let hstack = self as? HStack<TupleView<(some View, some View)>> {
            return AnyView(hstack)
        } else {
            return AnyView(self)
        }
    }
    
    /// 접근성 크기에서 수직 레이아웃 적용
    func adaptiveLayout<Content: View>(
        @ViewBuilder vertical: () -> Content
    ) -> some View {
        let manager = DynamicTypeManager.shared
        
        if manager.shouldUseVerticalLayout {
            return AnyView(vertical())
        } else {
            return AnyView(self)
        }
    }
    
    /// 접근성 크기에서 텍스트 줄바꿈 적용
    func adaptiveTextWrapping() -> some View {
        let manager = DynamicTypeManager.shared
        
        if manager.shouldWrapText {
            return self.lineLimit(nil)
        } else {
            return self.lineLimit(1)
        }
    }
    
    /// 동적 버튼 높이 적용
    func dynamicButtonHeight(_ height: CGFloat = 44) -> some View {
        let manager = DynamicTypeManager.shared
        let scaledHeight = manager.scaledButtonHeight(height)
        return self.frame(minHeight: scaledHeight)
    }
    
    /// 동적 아이콘 크기 적용
    func dynamicIconSize(_ size: CGFloat = 24) -> some View {
        let manager = DynamicTypeManager.shared
        let scaledSize = manager.scaledIconSize(size)
        return self.frame(width: scaledSize, height: scaledSize)
    }
}

// MARK: - Responsive Components

/// 동적 타입을 고려한 반응형 텍스트
struct ResponsiveText: View {
    let text: String
    let font: Font
    let maxLines: Int?
    
    init(_ text: String, font: Font = .brainyDynamicBody, maxLines: Int? = nil) {
        self.text = text
        self.font = font
        self.maxLines = maxLines
    }
    
    var body: some View {
        let manager = DynamicTypeManager.shared
        
        Text(text)
            .font(font)
            .lineLimit(manager.shouldWrapText ? nil : maxLines)
            .multilineTextAlignment(.leading)
    }
}

/// 동적 타입을 고려한 반응형 버튼
struct ResponsiveButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary, secondary, tertiary
    }
    
    init(_ title: String, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    var body: some View {
        let manager = DynamicTypeManager.shared
        
        Button(action: action) {
            Text(title)
                .font(.brainyDynamicButton)
                .foregroundColor(textColor)
                .dynamicButtonHeight()
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .cornerRadius(8)
        }
        .dynamicPadding(.horizontal, 16)
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .brainyPrimary
        case .tertiary:
            return .brainyText
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .brainyPrimary
        case .secondary:
            return .clear
        case .tertiary:
            return .brainySecondary.opacity(0.1)
        }
    }
}

/// 동적 타입을 고려한 반응형 카드
struct ResponsiveCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        let manager = DynamicTypeManager.shared
        
        content
            .dynamicPadding(.all, 16)
            .background(Color.brainySurface)
            .cornerRadius(12)
            .shadow(
                color: .black.opacity(0.1),
                radius: manager.isAccessibilitySize ? 2 : 4,
                x: 0,
                y: manager.isAccessibilitySize ? 1 : 2
            )
    }
}