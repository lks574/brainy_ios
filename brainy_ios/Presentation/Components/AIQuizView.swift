import SwiftUI

/// AI 모드 전용 퀴즈 뷰 컴포넌트
struct AIQuizView: View {
    @StateObject private var aiQuizManager = AIQuizManager()
    @State private var userAnswer: String = ""
    @State private var showHint: Bool = false
    @State private var showExplanation: Bool = false
    @State private var isAnswerSubmitted: Bool = false
    @State private var showValidationResult: Bool = false
    @State private var currentValidation: AIAnswerValidation?
    
    let category: QuizCategory
    let onQuizComplete: () -> Void
    let onExit: () -> Void
    
    // 애니메이션 상태
    @State private var questionAppearOffset: CGFloat = 50
    @State private var questionAppearOpacity: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더
                    headerView
                    
                    // 난이도 표시
                    difficultyIndicator
                    
                    // 문제 영역
                    questionSection
                    
                    // 답안 입력 영역
                    answerInputSection
                    
                    // 힌트 및 도움말 영역
                    helpSection
                    
                    // 검증 결과 영역
                    if showValidationResult {
                        validationResultSection
                    }
                    
                    // 액션 버튼들
                    actionButtonsSection
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .background(Color.brainyBackground.ignoresSafeArea())
        .onAppear {
            loadFirstQuestion()
        }
        .alert("오류", isPresented: .constant(aiQuizManager.generationError != nil)) {
            Button("확인") {
                aiQuizManager.generationError = nil
            }
        } message: {
            if let error = aiQuizManager.generationError {
                Text(error)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.brainyText)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("AI 퀴즈")
                    .font(.brainyHeadline)
                    .foregroundColor(.brainyText)
                
                Text(category.rawValue)
                    .font(.brainyCaption)
                    .foregroundColor(.brainyTextSecondary)
            }
            
            Spacer()
            
            // 정확도 표시
            VStack(spacing: 2) {
                Text("정확도")
                    .font(.caption2)
                    .foregroundColor(.brainyTextSecondary)
                
                Text("\(Int(aiQuizManager.recentAccuracyValue * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.brainyAccent)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Difficulty Indicator
    
    private var difficultyIndicator: some View {
        HStack(spacing: 12) {
            Text("난이도:")
                .font(.brainyCaption)
                .foregroundColor(.brainyTextSecondary)
            
            HStack(spacing: 4) {
                ForEach(QuizDifficulty.allCases, id: \.self) { difficulty in
                    Circle()
                        .fill(difficulty == aiQuizManager.currentDifficultyValue ? 
                              Color.brainyAccent : Color.brainyTextSecondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(aiQuizManager.currentDifficultyValue.rawValue)
                .font(.brainyCaption)
                .fontWeight(.medium)
                .foregroundColor(.brainyAccent)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Question Section
    
    private var questionSection: some View {
        BrainyCard {
            VStack(alignment: .leading, spacing: 16) {
                if aiQuizManager.isGeneratingQuestion {
                    // 로딩 상태
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.brainyAccent)
                        
                        Text("AI가 새로운 문제를 생성하고 있습니다...")
                            .font(.brainyBody)
                            .foregroundColor(.brainyTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    
                } else if let question = aiQuizManager.currentAIQuestion {
                    // 문제 표시
                    VStack(alignment: .leading, spacing: 12) {
                        Text("문제")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                            .textCase(.uppercase)
                        
                        Text(question.question)
                            .font(.brainyBody)
                            .foregroundColor(.brainyText)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .offset(y: questionAppearOffset)
                    .opacity(questionAppearOpacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.6)) {
                            questionAppearOffset = 0
                            questionAppearOpacity = 1
                        }
                    }
                    
                } else {
                    // 에러 상태
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.orange)
                        
                        Text("문제를 불러올 수 없습니다")
                            .font(.brainyBody)
                            .foregroundColor(.brainyText)
                        
                        Button("다시 시도") {
                            loadFirstQuestion()
                        }
                        .font(.brainyCaption)
                        .foregroundColor(.brainyAccent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Answer Input Section
    
    private var answerInputSection: some View {
        BrainyCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("답안")
                    .font(.brainyCaption)
                    .foregroundColor(.brainyTextSecondary)
                    .textCase(.uppercase)
                
                BrainyTextField(
                    text: $userAnswer,
                    placeholder: "답안을 입력하세요",
                    isEnabled: !isAnswerSubmitted && aiQuizManager.currentAIQuestion != nil
                )
                .onSubmit {
                    if !userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        submitAnswer()
                    }
                }
                
                if !userAnswer.isEmpty && !isAnswerSubmitted {
                    BrainyButton(
                        "답안 제출",
                        style: .primary,
                        action: submitAnswer
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Help Section
    
    private var helpSection: some View {
        VStack(spacing: 12) {
            // 힌트 버튼
            if !showHint && !isAnswerSubmitted {
                Button(action: { showHint = true }) {
                    HStack {
                        Image(systemName: "lightbulb")
                        Text("힌트 보기")
                    }
                    .font(.brainyCaption)
                    .foregroundColor(.brainyAccent)
                }
            }
            
            // 힌트 표시
            if showHint, let hint = aiQuizManager.getHint() {
                BrainyCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("힌트")
                                .font(.brainyCaption)
                                .fontWeight(.medium)
                                .foregroundColor(.brainyText)
                        }
                        
                        Text(hint)
                            .font(.brainyBody)
                            .foregroundColor(.brainyTextSecondary)
                    }
                    .padding(16)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // 설명 표시 (답안 제출 후)
            if showExplanation, let explanation = aiQuizManager.getExplanation() {
                BrainyCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.brainyAccent)
                            Text("설명")
                                .font(.brainyCaption)
                                .fontWeight(.medium)
                                .foregroundColor(.brainyText)
                        }
                        
                        Text(explanation)
                            .font(.brainyBody)
                            .foregroundColor(.brainyTextSecondary)
                    }
                    .padding(16)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Validation Result Section
    
    private var validationResultSection: some View {
        Group {
            if let validation = currentValidation {
                BrainyCard {
                    VStack(spacing: 16) {
                        // 결과 아이콘 및 메시지
                        VStack(spacing: 8) {
                            Image(systemName: validation.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(validation.isCorrect ? .green : .red)
                            
                            Text(validation.explanation)
                                .font(.brainyBody)
                                .fontWeight(.medium)
                                .foregroundColor(.brainyText)
                                .multilineTextAlignment(.center)
                        }
                        
                        // 신뢰도 표시
                        VStack(spacing: 4) {
                            Text("AI 신뢰도: \(Int(validation.confidence * 100))%")
                                .font(.brainyCaption)
                                .foregroundColor(.brainyTextSecondary)
                            
                            ProgressView(value: validation.confidence)
                                .tint(.brainyAccent)
                        }
                        
                        // 피드백
                        if !validation.feedback.isEmpty {
                            Text(validation.feedback)
                                .font(.brainyCaption)
                                .foregroundColor(.brainyTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                    }
                    .padding(20)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if isAnswerSubmitted {
                // 다음 문제 버튼
                BrainyButton(
                    "다음 문제",
                    style: .primary,
                    action: loadNextQuestion
                )
                
                // 설명 보기/숨기기 버튼
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showExplanation.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: showExplanation ? "eye.slash" : "eye")
                        Text(showExplanation ? "설명 숨기기" : "설명 보기")
                    }
                    .font(.brainyCaption)
                    .foregroundColor(.brainyAccent)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadFirstQuestion() {
        resetQuestionState()
        Task {
            await aiQuizManager.generateQuestion(for: category)
        }
    }
    
    private func loadNextQuestion() {
        resetQuestionState()
        
        // 애니메이션을 위한 상태 초기화
        questionAppearOffset = 50
        questionAppearOpacity = 0
        
        Task {
            await aiQuizManager.generateQuestion(for: category)
        }
    }
    
    private func submitAnswer() {
        guard !userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isAnswerSubmitted = true
        
        Task {
            let validation = await aiQuizManager.validateAnswer(userAnswer: userAnswer)
            
            await MainActor.run {
                currentValidation = validation
                withAnimation(.easeInOut(duration: 0.5)) {
                    showValidationResult = true
                }
                
                // 자동으로 설명 표시
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showExplanation = true
                    }
                }
            }
        }
    }
    
    private func resetQuestionState() {
        userAnswer = ""
        showHint = false
        showExplanation = false
        isAnswerSubmitted = false
        showValidationResult = false
        currentValidation = nil
    }
}

// MARK: - Supporting Views

/// AI 퀴즈 통계 뷰
struct AIQuizStatsView: View {
    let statistics: AIQuizStatistics
    
    var body: some View {
        BrainyCard {
            VStack(spacing: 16) {
                Text("AI 퀴즈 통계")
                    .font(.brainyHeadline)
                    .foregroundColor(.brainyText)
                
                HStack(spacing: 20) {
                    AIQuizStatItem(
                        title: "정답률",
                        value: "\(Int(statistics.accuracy * 100))%",
                        color: .green
                    )
                    
                    AIQuizStatItem(
                        title: "총 문제",
                        value: "\(statistics.totalQuestions)",
                        color: .brainyAccent
                    )
                    
                    AIQuizStatItem(
                        title: "평균 신뢰도",
                        value: "\(Int(statistics.averageConfidence * 100))%",
                        color: .blue
                    )
                }
            }
            .padding(20)
        }
    }
}

/// AI 퀴즈 통계 아이템 뷰
private struct AIQuizStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.brainyTextSecondary)
        }
    }
}
