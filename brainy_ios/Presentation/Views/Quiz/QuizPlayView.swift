import SwiftUI

/// 퀴즈 플레이 화면
struct QuizPlayView: View {
    @State private var coordinator: AppCoordinator
    @State private var viewModel: QuizPlayViewModel
    @State private var showExitAlert = false
    @State private var animateProgress = false
    
    let category: QuizCategory
    let mode: QuizMode
    let quizType: QuizType
    let excludeCompleted: Bool
    
    init(
        coordinator: AppCoordinator,
        category: QuizCategory,
        mode: QuizMode,
        quizType: QuizType,
        excludeCompleted: Bool = false
    ) {
        self._coordinator = State(initialValue: coordinator)
        self.category = category
        self.mode = mode
        self.quizType = quizType
        self.excludeCompleted = excludeCompleted
        
        // ViewModel 초기화 (실제 앱에서는 DI를 통해 주입)
        let quizRepository = QuizDataFactory.shared.makeQuizRepository()
        self._viewModel = State(initialValue: QuizPlayViewModel(
            quizRepository: quizRepository,
            category: category,
            mode: mode,
            quizType: quizType,
            excludeCompleted: excludeCompleted
        ))
    }
    
    var body: some View {
        ZStack {
            Color.brainyBackground
                .ignoresSafeArea()
            
            if quizType == .ai {
                // AI 모드는 전용 뷰 사용
                AIQuizView(
                    category: category,
                    onQuizComplete: {
                      // TODO: 실제 사용자 ID로 교체해야 합니다.
                       let session = QuizSession(
                           id: UUID().uuidString,
                           userId: "temp-user-id", // 임시 ID
                           category: category,
                           mode: mode,
                           totalQuestions: 10
                       )
                       session.correctAnswers = viewModel.score
                       session.completedAt = Date()
                       // TODO: 실제 총 소요 시간으로 교체
                       // session.totalTime = viewModel.elapsedTime

                       coordinator.navigateToQuizResult(session: session)
                    },
                    onExit: {
                        coordinator.navigateBack()
                    }
                )
            } else {
                // 기존 퀴즈 UI
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else if viewModel.questions.isEmpty {
                    emptyStateView
                } else {
                    quizContentView
                }
            }
        }
        .navigationBarHidden(true)
        .alert("퀴즈 종료", isPresented: $showExitAlert) {
            Button("계속하기", role: .cancel) { }
            Button("종료", role: .destructive) {
                coordinator.navigateBack()
            }
        } message: {
            Text("정말로 퀴즈를 종료하시겠습니까?\n현재까지의 진행 상황이 저장되지 않습니다.")
        }
        .task {
            await viewModel.startQuiz()
        }
        .onDisappear {
            viewModel.exitQuiz()
        }
        .onChange(of: viewModel.currentQuestionIndex) { _, _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                animateProgress = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateProgress = false
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.brainyPrimary)
            
            Text("퀴즈를 준비하고 있습니다...")
                .font(.brainyBodyLarge)
                .foregroundColor(.brainyTextSecondary)
        }
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.brainyError)
            
            Text("오류가 발생했습니다")
                .font(.brainyHeadlineMedium)
                .foregroundColor(.brainyText)
            
            Text(message)
                .font(.brainyBodyLarge)
                .foregroundColor(.brainyTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                BrainyButton("다시 시도", style: .primary) {
                    Task {
                        await viewModel.startQuiz()
                    }
                }
                
                BrainyButton("뒤로 가기", style: .secondary) {
                    coordinator.navigateBack()
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.brainyTextSecondary)
            
            Text("문제가 없습니다")
                .font(.brainyHeadlineMedium)
                .foregroundColor(.brainyText)
            
            Text("해당 카테고리에 \(quizType.rawValue) 문제가 없습니다.")
                .font(.brainyBodyLarge)
                .foregroundColor(.brainyTextSecondary)
                .multilineTextAlignment(.center)
            
            BrainyButton("뒤로 가기", style: .primary) {
                coordinator.navigateBack()
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Quiz Content View
    private var quizContentView: some View {
        VStack(spacing: 0) {
            // Header with progress and timer
            headerView
            
            // Question content
            ScrollView {
                VStack(spacing: 24) {
                    questionView
                    answerInputView
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100) // Space for bottom button
            }
            
            Spacer()
            
            // Bottom action button
            bottomActionView
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Progress bar
            HStack {
                Button(action: {
                    coordinator.navigateBack()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.brainyText)
                }
                
                Spacer()
                
                Text("\(viewModel.currentQuestionIndex + 1) / \(viewModel.questions.count)")
                    .font(.brainyBodyMedium)
                    .foregroundColor(.brainyTextSecondary)
                
                Spacer()
                
                // Timer
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(timerColor)
                    
                    Text(formatTime(viewModel.timeRemaining))
                        .font(.brainyBodyMedium)
                        .foregroundColor(timerColor)
                }
            }
            .padding(.horizontal, 24)
            
            // Progress bar
            ProgressView(value: viewModel.progress)
                .tint(.brainyPrimary)
                .scaleEffect(y: 2)
                .padding(.horizontal, 24)
            
            // Reward status
            AdRewardStatusView()
                .padding(.horizontal, 24)
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(Color.brainyBackground)
    }
    
    // MARK: - Question View
    private var questionView: some View {
        BrainyCard(style: .quiz, shadow: .medium) {
            VStack(alignment: .leading, spacing: 16) {
                // Question type badge
                HStack {
                    Text(quizType.rawValue)
                        .font(.brainyLabelMedium)
                        .foregroundColor(.brainyPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.brainyPrimary.opacity(0.1))
                        .cornerRadius(16)
                    
                    Spacer()
                    
                    // Reward ad button for hints
                    RewardedAdButton(title: "힌트") {
                        // Show hint for current question
                        showHintForCurrentQuestion()
                    }
                    
                    Text(category.rawValue)
                        .font(.brainyLabelMedium)
                        .foregroundColor(.brainyTextSecondary)
                }
                
                // Question text
                Text(viewModel.currentQuestion?.question ?? "")
                    .font(.brainyHeadlineMedium)
                    .foregroundColor(.brainyText)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Answer Input View
    private var answerInputView: some View {
        Group {
            if let question = viewModel.currentQuestion {
                switch question.type {
                case .multipleChoice:
                    multipleChoiceView(question: question)
                case .voice:
                    voiceQuizView(question: question)
                case .shortAnswer, .ai:
                    shortAnswerView
                }
            }
        }
    }
    
    // MARK: - Multiple Choice View
    private func multipleChoiceView(question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            if let options = question.options {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    BrainyQuizCard(
                        isSelected: viewModel.selectedOptionIndex == index,
                        onTap: {
                            viewModel.selectOption(index)
                        }
                    ) {
                        HStack {
                            // Option letter (A, B, C, D)
                            Text(String(Character(UnicodeScalar(65 + index)!)))
                                .font(.brainyBodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(.brainyPrimary)
                                .frame(width: 24, height: 24)
                                .background(Color.brainyPrimary.opacity(0.1))
                                .cornerRadius(12)
                            
                            Text(option)
                                .font(.brainyBodyLarge)
                                .foregroundColor(.brainyText)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Voice Quiz View
    private func voiceQuizView(question: QuizQuestion) -> some View {
        VoiceQuizView(question: question) { answer in
            viewModel.shortAnswerText = answer
        }
    }
    
    // MARK: - Short Answer View
    private var shortAnswerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("답안을 입력하세요")
                .font(.brainyBodyMedium)
                .foregroundColor(.brainyTextSecondary)
            
            BrainyTextField(
                text: $viewModel.shortAnswerText,
                placeholder: "답안을 입력하세요...",
                style: .outlined
            )
        }
    }
    
    // MARK: - Bottom Action View
    private var bottomActionView: some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.brainyTextSecondary.opacity(0.2))
            
            HStack(spacing: 16) {
                // Skip button (for individual mode)
                if mode == .individual {
                    BrainyButton(
                        "건너뛰기",
                        style: .ghost,
                        size: .medium
                    ) {
                        Task {
                            await viewModel.submitAnswer()
                        }
                    }
                }
                
                // Submit/Next button
                BrainyButton(
                    viewModel.isLastQuestion ? "완료" : "다음",
                    style: .primary,
                    size: .medium,
                    isEnabled: viewModel.hasAnswered
                ) {
                    Task {
                        await viewModel.submitAnswer()
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 34) // Safe area bottom padding
        .background(Color.brainyBackground)
    }
    
    // MARK: - Helper Methods
    private var timerColor: Color {
        if viewModel.timeRemaining <= 30 {
            return .brainyError
        } else if viewModel.timeRemaining <= 60 {
            return .brainyWarning
        } else {
            return .brainyTextSecondary
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func showHintForCurrentQuestion() {
        // TODO: Implement hint functionality
        // This could show the first letter of the answer, eliminate wrong options, etc.
        print("Hint requested for current question")
    }
}
