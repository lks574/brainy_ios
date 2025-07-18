import SwiftUI

/// 카테고리 선택 화면
struct CategorySelectionView: View {
    @ObservedObject var coordinator: AppCoordinator
    let quizMode: QuizMode
    let quizType: QuizType
    
    @State private var selectedCategory: QuizCategory?
    @State private var selectedPlayMode: QuizMode = .individual
    @State private var selectedQuestionFilter: QuestionFilter = .random
    
    var body: some View {
        VStack(spacing: 24) {
            // 헤더
            headerSection
            
            ScrollView {
                VStack(spacing: 20) {
                    // 플레이 모드 선택 (스테이지 vs 개별)
                    playModeSection
                    
                    // 문제 필터 선택 (전체 무작위 vs 풀었던 것 제외)
                    questionFilterSection
                    
                    // 카테고리 선택
                    categorySection
                }
                .padding(.horizontal, 24)
            }
            
            // 하단 버튼
            bottomSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brainyBackground)
        .navigationBarHidden(true)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("카테고리 선택")
                .font(.brainyTitle)
                .foregroundColor(.brainyText)
            
            Text("퀴즈 모드: \(quizMode.rawValue)")
                .font(.brainyBodyMedium)
                .foregroundColor(.brainyTextSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Play Mode Section
    private var playModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("플레이 형식")
                .font(.brainyHeadlineSmall)
                .foregroundColor(.brainyText)
            
            HStack(spacing: 12) {
                PlayModeToggle(
                    title: "스테이지",
                    description: "순차적 진행",
                    icon: "list.number",
                    mode: .stage,
                    isSelected: selectedPlayMode == .stage
                ) {
                    selectedPlayMode = .stage
                }
                
                PlayModeToggle(
                    title: "개별",
                    description: "독립적 풀이",
                    icon: "square.grid.2x2",
                    mode: .individual,
                    isSelected: selectedPlayMode == .individual
                ) {
                    selectedPlayMode = .individual
                }
            }
        }
    }
    
    // MARK: - Question Filter Section
    private var questionFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("문제 선택")
                .font(.brainyHeadlineSmall)
                .foregroundColor(.brainyText)
            
            VStack(spacing: 8) {
                QuestionFilterOption(
                    title: "전체 무작위",
                    description: "모든 문제에서 랜덤 선택",
                    icon: "shuffle",
                    filter: .random,
                    isSelected: selectedQuestionFilter == .random
                ) {
                    selectedQuestionFilter = .random
                }
                
                QuestionFilterOption(
                    title: "풀었던 것 제외",
                    description: "이전에 풀지 않은 문제만",
                    icon: "checkmark.circle.badge.xmark",
                    filter: .excludeSolved,
                    isSelected: selectedQuestionFilter == .excludeSolved
                ) {
                    selectedQuestionFilter = .excludeSolved
                }
            }
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카테고리")
                .font(.brainyHeadlineSmall)
                .foregroundColor(.brainyText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(QuizCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 16) {
            // 시작 버튼
            BrainyButton(
                "퀴즈 시작",
                style: .primary,
                size: .large,
                isEnabled: selectedCategory != nil
            ) {
                if let category = selectedCategory {
                    coordinator.navigateToQuizPlay(category: category, mode: selectedPlayMode, type: quizType)
                }
            }
            
            // 뒤로 가기 버튼
            BrainyButton("뒤로 가기", style: .secondary, size: .medium) {
                coordinator.navigateBack()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Question Filter Enum
enum QuestionFilter: String, CaseIterable {
    case random = "전체 무작위"
    case excludeSolved = "풀었던 것 제외"
}

// MARK: - Play Mode Toggle
private struct PlayModeToggle: View {
    let title: String
    let description: String
    let icon: String
    let mode: QuizMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.brainyLabelLarge)
                    .foregroundColor(titleColor)
                
                Text(description)
                    .font(.brainyLabelSmall)
                    .foregroundColor(.brainyTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconColor: Color {
        isSelected ? .white : .brainyPrimary
    }
    
    private var titleColor: Color {
        isSelected ? .white : .brainyText
    }
    
    private var backgroundColor: Color {
        isSelected ? .brainyPrimary : .brainyCardBackground
    }
    
    private var borderColor: Color {
        isSelected ? .brainyPrimary : Color.brainySecondary.opacity(0.2)
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2.0 : 1.0
    }
}

// MARK: - Question Filter Option
private struct QuestionFilterOption: View {
    let title: String
    let description: String
    let icon: String
    let filter: QuestionFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.brainyBodyLarge)
                        .foregroundColor(titleColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(description)
                        .font(.brainyBodySmall)
                        .foregroundColor(.brainyTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(checkmarkColor)
            }
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconColor: Color {
        isSelected ? .brainyPrimary : .brainyTextSecondary
    }
    
    private var titleColor: Color {
        isSelected ? .brainyPrimary : .brainyText
    }
    
    private var backgroundColor: Color {
        isSelected ? Color.brainyPrimary.opacity(0.05) : .brainyCardBackground
    }
    
    private var borderColor: Color {
        isSelected ? .brainyPrimary : Color.brainySecondary.opacity(0.2)
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2.0 : 1.0
    }
    
    private var checkmarkColor: Color {
        isSelected ? .brainyPrimary : .brainyTextSecondary
    }
}

// MARK: - Category Card
private struct CategoryCard: View {
    let category: QuizCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(categoryIcon)
                    .font(.system(size: 32))
                
                Text(category.rawValue)
                    .font(.brainyBodyLarge)
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)
                
                Text(categoryDescription)
                    .font(.brainyBodySmall)
                    .foregroundColor(.brainyTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryIcon: String {
        switch category {
        case .person:
            return "👤"
        case .general:
            return "🧠"
        case .country:
            return "🌍"
        case .drama:
            return "🎭"
        case .music:
            return "🎵"
        }
    }
    
    private var categoryDescription: String {
        switch category {
        case .person:
            return "유명인물에 대한 퀴즈"
        case .general:
            return "일반상식 퀴즈"
        case .country:
            return "세계 각국에 대한 퀴즈"
        case .drama:
            return "드라마와 영화 퀴즈"
        case .music:
            return "음악과 가수 퀴즈"
        }
    }
    
    private var titleColor: Color {
        isSelected ? .brainyPrimary : .brainyText
    }
    
    private var backgroundColor: Color {
        isSelected ? Color.brainyPrimary.opacity(0.05) : .brainyCardBackground
    }
    
    private var borderColor: Color {
        isSelected ? .brainyPrimary : Color.brainySecondary.opacity(0.2)
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2.0 : 1.0
    }
}

