import SwiftUI

/// 히스토리 상세 화면
struct HistoryDetailView: View {
    @State private var coordinator: AppCoordinator
    @State private var viewModel: HistoryDetailViewModel
    let session: QuizSession
    
    init(coordinator: AppCoordinator, session: QuizSession) {
        self._coordinator = State(initialValue: coordinator)
        self.session = session
        
        // ViewModel 초기화 (실제로는 DI를 통해 주입받아야 함)
        let quizRepository = QuizDataFactory.shared.createQuizRepository()
        self._viewModel = State(initialValue: HistoryDetailViewModel(
            quizRepository: quizRepository,
            session: session
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            if viewModel.isLoading {
                loadingView
            } else {
                detailContentView
            }
        }
        .background(Color.brainyBackground)
        .navigationBarHidden(true)
        .task {
            await viewModel.loadSessionDetails()
        }
        .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    coordinator.navigateBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.brainyText)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(session.category.rawValue)
                        .font(.brainyTitle)
                        .foregroundColor(.brainyText)
                    
                    Text(session.displayDate)
                        .font(.brainyCaption)
                        .foregroundColor(.brainyTextSecondary)
                }
                
                Spacer()
                
                // Share button (향후 구현)
                Button(action: {
                    // TODO: Implement sharing functionality
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundColor(.brainyText)
                }
            }
            
            // Session summary
            sessionSummaryView
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Session Summary
    
    private var sessionSummaryView: some View {
        BrainyCard {
            VStack(spacing: 16) {
                // Score display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("점수")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                        
                        Text(session.displayScore)
                            .font(.brainyTitle)
                            .foregroundColor(.brainyText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("정확도")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                        
                        Text(session.displayAccuracy)
                            .font(.brainyTitle)
                            .foregroundColor(session.accuracyRate >= 0.8 ? .brainySuccess : .brainyText)
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.brainySurface)
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(session.accuracyRate >= 0.8 ? Color.brainySuccess : Color.brainyAccent)
                            .frame(width: geometry.size.width * session.accuracyRate, height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
                
                // Additional stats
                HStack {
                    StatItem(title: "모드", value: session.mode.rawValue, icon: "gamecontroller")
                    
                    Spacer()
                    
                    StatItem(title: "소요시간", value: session.displayDuration, icon: "clock")
                    
                    Spacer()
                    
                    StatItem(title: "문제수", value: "\(session.totalQuestions)개", icon: "doc.text")
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("상세 정보를 불러오는 중...")
                .font(.brainyBody)
                .foregroundColor(.brainyTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Detail Content View
    
    private var detailContentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Performance analysis
                if !viewModel.quizResults.isEmpty {
                    performanceAnalysisView
                }
                
                // Question results
                questionResultsView
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Performance Analysis
    
    private var performanceAnalysisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("성과 분석")
                .font(.brainyHeadline)
                .foregroundColor(.brainyText)
            
            BrainyCard {
                VStack(spacing: 16) {
                    // Time analysis
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("평균 문제당 시간")
                                .font(.brainyCaption)
                                .foregroundColor(.brainyTextSecondary)
                            
                            Text(viewModel.averageTimePerQuestion)
                                .font(.brainyBody)
                                .foregroundColor(.brainyText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("가장 빠른 답변")
                                .font(.brainyCaption)
                                .foregroundColor(.brainyTextSecondary)
                            
                            Text(viewModel.fastestAnswerTime)
                                .font(.brainyBody)
                                .foregroundColor(.brainyText)
                        }
                    }
                    
                    Divider()
                    
                    // Accuracy breakdown
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("정답")
                                .font(.brainyCaption)
                                .foregroundColor(.brainySuccess)
                            
                            Text("\(viewModel.correctAnswersCount)개")
                                .font(.brainyBody)
                                .foregroundColor(.brainyText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 4) {
                            Text("오답")
                                .font(.brainyCaption)
                                .foregroundColor(.brainyTextSecondary)
                            
                            Text("\(viewModel.incorrectAnswersCount)개")
                                .font(.brainyBody)
                                .foregroundColor(.brainyText)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("정답률")
                                .font(.brainyCaption)
                                .foregroundColor(.brainyTextSecondary)
                            
                            Text(session.displayAccuracy)
                                .font(.brainyBody)
                                .foregroundColor(session.accuracyRate >= 0.8 ? .brainySuccess : .brainyText)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Question Results
    
    private var questionResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("문제별 결과")
                .font(.brainyHeadline)
                .foregroundColor(.brainyText)
            
            ForEach(Array(viewModel.quizResults.enumerated()), id: \.offset) { index, result in
                QuestionResultCard(
                    questionNumber: index + 1,
                    result: result,
                    question: viewModel.getQuestion(for: result.questionId)
                )
            }
        }
    }
}

// MARK: - Supporting Views

/// 통계 항목
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.brainyAccent)
            
            Text(value)
                .font(.brainyCaption)
                .foregroundColor(.brainyText)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.brainyTextSecondary)
        }
    }
}

/// 문제 결과 카드
struct QuestionResultCard: View {
    let questionNumber: Int
    let result: QuizResult
    let question: QuizQuestion?
    
    var body: some View {
        BrainyCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("문제 \(questionNumber)")
                        .font(.brainyHeadline)
                        .foregroundColor(.brainyText)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Correct/Incorrect indicator
                        Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.isCorrect ? .brainySuccess : .red)
                        
                        // Time spent
                        Text(formatTime(result.timeSpent))
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                    }
                }
                
                // Question text
                if let question = question {
                    Text(question.question)
                        .font(.brainyBody)
                        .foregroundColor(.brainyText)
                        .multilineTextAlignment(.leading)
                }
                
                // Answer comparison
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("내 답변:")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                        
                        Text(result.userAnswer)
                            .font(.brainyBody)
                            .foregroundColor(result.isCorrect ? .brainySuccess : .red)
                    }
                    
                    if !result.isCorrect, let question = question {
                        HStack {
                            Text("정답:")
                                .font(.brainyCaption)
                                .foregroundColor(.brainyTextSecondary)
                            
                            Text(question.correctAnswer)
                                .font(.brainyBody)
                                .foregroundColor(.brainySuccess)
                        }
                    }
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let seconds = Int(timeInterval)
        return "\(seconds)초"
    }
}
