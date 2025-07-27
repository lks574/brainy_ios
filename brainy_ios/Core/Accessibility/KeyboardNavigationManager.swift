import Foundation
import SwiftUI

/// 키보드 네비게이션 관리자
@MainActor
class KeyboardNavigationManager: ObservableObject {
    // MARK: - Properties
    @Published var currentFocusedIndex: Int = 0
    @Published var focusableElements: [FocusableElement] = []
    @Published var isKeyboardNavigationEnabled = false
    
    // MARK: - Singleton
    static let shared = KeyboardNavigationManager()
    
    private init() {
        setupKeyboardDetection()
    }
    
    // MARK: - Setup
    
    private func setupKeyboardDetection() {
        // 외부 키보드 연결 감지
        NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isKeyboardNavigationEnabled = true
        }
        
        NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isKeyboardNavigationEnabled = false
        }
    }
    
    // MARK: - Focus Management
    
    /// 포커스 가능한 요소 등록
    func registerFocusableElement(_ element: FocusableElement) {
        if !focusableElements.contains(where: { $0.id == element.id }) {
            focusableElements.append(element)
            focusableElements.sort { $0.tabIndex < $1.tabIndex }
        }
    }
    
    /// 포커스 가능한 요소 제거
    func unregisterFocusableElement(id: String) {
        focusableElements.removeAll { $0.id == id }
    }
    
    /// 다음 요소로 포커스 이동
    func focusNext() {
        guard !focusableElements.isEmpty else { return }
        
        currentFocusedIndex = (currentFocusedIndex + 1) % focusableElements.count
        updateFocus()
    }
    
    /// 이전 요소로 포커스 이동
    func focusPrevious() {
        guard !focusableElements.isEmpty else { return }
        
        currentFocusedIndex = currentFocusedIndex > 0 ? currentFocusedIndex - 1 : focusableElements.count - 1
        updateFocus()
    }
    
    /// 특정 인덱스로 포커스 이동
    func focusElement(at index: Int) {
        guard index >= 0 && index < focusableElements.count else { return }
        
        currentFocusedIndex = index
        updateFocus()
    }
    
    /// 특정 ID의 요소로 포커스 이동
    func focusElement(id: String) {
        if let index = focusableElements.firstIndex(where: { $0.id == id }) {
            focusElement(at: index)
        }
    }
    
    /// 현재 포커스된 요소 활성화
    func activateCurrentElement() {
        guard currentFocusedIndex < focusableElements.count else { return }
        
        let element = focusableElements[currentFocusedIndex]
        element.onActivate?()
    }
    
    /// 포커스 업데이트
    private func updateFocus() {
        // 모든 요소의 포커스 해제
        for element in focusableElements {
            element.onFocusChange?(false)
        }
        
        // 현재 요소에 포커스 설정
        if currentFocusedIndex < focusableElements.count {
            let currentElement = focusableElements[currentFocusedIndex]
            currentElement.onFocusChange?(true)
        }
    }
    
    // MARK: - Keyboard Shortcuts
    
    /// 키보드 단축키 처리
    func handleKeyPress(_ key: KeyEquivalent, modifiers: EventModifiers = []) -> Bool {
        guard isKeyboardNavigationEnabled else { return false }
        
        switch key {
        case .tab:
            if modifiers.contains(.shift) {
                focusPrevious()
            } else {
                focusNext()
            }
            return true
            
        case .space, .return:
            activateCurrentElement()
            return true
            
        case .upArrow:
            focusPrevious()
            return true
            
        case .downArrow:
            focusNext()
            return true
            
        case .escape:
            clearFocus()
            return true
            
        default:
            return false
        }
    }
    
    /// 포커스 초기화
    func clearFocus() {
        for element in focusableElements {
            element.onFocusChange?(false)
        }
        currentFocusedIndex = 0
    }
    
    /// 포커스 가능한 요소 초기화
    func clearFocusableElements() {
        focusableElements.removeAll()
        currentFocusedIndex = 0
    }
}

// MARK: - Focusable Element

struct FocusableElement: Identifiable, Equatable {
    let id: String
    let tabIndex: Int
    let accessibilityLabel: String
    let accessibilityHint: String?
    let onFocusChange: ((Bool) -> Void)?
    let onActivate: (() -> Void)?
    
    static func == (lhs: FocusableElement, rhs: FocusableElement) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Keyboard Navigation Modifiers

extension View {
    /// 키보드 네비게이션 지원 추가
    func keyboardNavigable(
        id: String,
        tabIndex: Int = 0,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        onActivate: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            KeyboardNavigationModifier(
                id: id,
                tabIndex: tabIndex,
                accessibilityLabel: accessibilityLabel,
                accessibilityHint: accessibilityHint,
                onActivate: onActivate
            )
        )
    }
    
    /// 키보드 단축키 처리
    func onKeyPress(
        _ key: KeyEquivalent,
        modifiers: EventModifiers = [],
        action: @escaping () -> Void
    ) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .keyPressed)) { notification in
            if let keyInfo = notification.userInfo as? [String: Any],
               let pressedKey = keyInfo["key"] as? KeyEquivalent,
               let pressedModifiers = keyInfo["modifiers"] as? EventModifiers,
               pressedKey == key && pressedModifiers == modifiers {
                action()
            }
        }
    }
}

// MARK: - Keyboard Navigation Modifier

struct KeyboardNavigationModifier: ViewModifier {
    let id: String
    let tabIndex: Int
    let accessibilityLabel: String
    let accessibilityHint: String?
    let onActivate: (() -> Void)?
    
    @State private var isFocused = false
    @StateObject private var navigationManager = KeyboardNavigationManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(
                focusIndicator
                    .opacity(isFocused ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint ?? "")
            .accessibilityAddTraits(isFocused ? .isKeyboardKey : [])
            .onAppear {
                registerElement()
            }
            .onDisappear {
                navigationManager.unregisterFocusableElement(id: id)
            }
    }
    
    private var focusIndicator: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(Color.brainyPrimary, lineWidth: 2)
            .background(Color.brainyPrimary.opacity(0.1))
    }
    
    private func registerElement() {
        let element = FocusableElement(
            id: id,
            tabIndex: tabIndex,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            onFocusChange: { focused in
                isFocused = focused
            },
            onActivate: onActivate
        )
        
        navigationManager.registerFocusableElement(element)
    }
}

// MARK: - Keyboard Shortcut Components

/// 키보드 단축키를 표시하는 뷰
struct KeyboardShortcutIndicator: View {
    let shortcut: String
    let description: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(shortcut)
                .font(.brainyCaption)
                .foregroundColor(.brainyTextSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.brainySecondary.opacity(0.2))
                .cornerRadius(4)
            
            Text(description)
                .font(.brainyCaption)
                .foregroundColor(.brainyTextSecondary)
            
            Spacer()
        }
    }
}

/// 키보드 단축키 도움말 뷰
struct KeyboardShortcutsHelp: View {
    @StateObject private var navigationManager = KeyboardNavigationManager.shared
    
    var body: some View {
        if navigationManager.isKeyboardNavigationEnabled {
            VStack(alignment: .leading, spacing: 8) {
                Text("키보드 단축키")
                    .font(.brainyHeadline)
                    .foregroundColor(.brainyText)
                
                VStack(alignment: .leading, spacing: 4) {
                    KeyboardShortcutIndicator(shortcut: "Tab", description: "다음 요소로 이동")
                    KeyboardShortcutIndicator(shortcut: "Shift+Tab", description: "이전 요소로 이동")
                    KeyboardShortcutIndicator(shortcut: "Space/Enter", description: "선택된 요소 활성화")
                    KeyboardShortcutIndicator(shortcut: "↑/↓", description: "위/아래 요소로 이동")
                    KeyboardShortcutIndicator(shortcut: "Esc", description: "포커스 해제")
                }
            }
            .padding(16)
            .background(Color.brainySurface)
            .cornerRadius(8)
            .shadow(radius: 2)
        }
    }
}

// MARK: - Quiz-Specific Keyboard Navigation

/// 퀴즈 선택지를 위한 키보드 네비게이션
struct QuizOptionKeyboardNavigation: View {
    let options: [String]
    let selectedIndex: Int?
    let onSelect: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button(action: {
                    onSelect(index)
                }) {
                    HStack {
                        Text("\(index + 1). \(option)")
                            .font(.brainyBody)
                            .foregroundColor(.brainyText)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        if selectedIndex == index {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.brainyPrimary)
                        }
                    }
                    .padding(12)
                    .background(selectedIndex == index ? Color.brainyPrimary.opacity(0.1) : Color.brainySurface)
                    .cornerRadius(8)
                }
                .keyboardNavigable(
                    id: "quiz_option_\(index)",
                    tabIndex: index,
                    accessibilityLabel: "선택지 \(index + 1): \(option)",
                    accessibilityHint: selectedIndex == index ? "현재 선택됨" : "선택하려면 활성화하세요",
                    onActivate: { onSelect(index) }
                )
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let keyPressed = Notification.Name("keyPressed")
    static let GCKeyboardDidConnect = Notification.Name("GCKeyboardDidConnect")
    static let GCKeyboardDidDisconnect = Notification.Name("GCKeyboardDidDisconnect")
}