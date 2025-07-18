import Foundation
import SwiftUI

/// 퀴즈 플레이 화면을 위한 ViewModel
@MainActor
@Observable
class QuizPlayViewModel {
    private let quizRepository: QuizRepositoryProtocol
    
    // Quiz state
    var questions: [QuizQuestion] = []
    var currentQuestionIndex: Int = 0
    var userAnswers: [String] = []
    var selectedOptionIndex: Int? = nil
    var shortAnswerText: String = ""
    var score: Int = 0
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    // Timer state
    var timeRemaining: Int = 0
    var totalTime: Int = 0
    private var timer: Timer?
    
    // Quiz configuration
    let category: QuizCategory
    let mode: QuizMode
    let quizType: QuizType
    let excludeCompleted: Bool
    
    // Computed properties
    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }
    
    var isLastQuestion: Bool {
        return currentQuestionIndex >= questions.count - 1
    }
    
    var hasAnswered: Bool {
        if let question = currentQuestion {
            switch question.type {
            case .multipleChoice:
                return selectedOptionIndex != nil
            case .shortAnswer:
                return !shortAnswerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            case .voice, .ai:
                return !shortAnswerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
        return false
    }
    
    init(
        quizRepository: QuizRepositoryProtocol,
        category: QuizCategory,
        mode: QuizMode,
        quizType: QuizType,
        excludeCompleted: Bool = false
    ) {
        self.quizRepository = quizRepository
        self.category = category
        self.mode = mode
        self.quizType = quizType
        self.excludeCompleted = excludeCompleted
    }
    
    /// 퀴즈를 시작합니다
    func startQuiz() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 퀴즈 문제들을 로드
            let allQuestions = try await quizRepository.getQuestions(
                category: category,
                excludeCompleted: excludeCompleted
            )
            
            // 퀴즈 타입에 맞는 문제들만 필터링
            questions = allQuestions.filter { $0.type == quizType }
            
            // 문제가 없는 경우 처리
            if questions.isEmpty {
                errorMessage = "해당 카테고리에 \(quizType.rawValue) 문제가 없습니다."
                isLoading = false
                return
            }
            
            // 문제들을 섞기
            questions.shuffle()
            
            // 스테이지 모드가 아닌 경우 최대 10문제로 제한
            if mode == .individual && questions.count > 10 {
                questions = Array(questions.prefix(10))
            }
            
            // 사용자 답안 배열 초기화
            userAnswers = Array(repeating: "", count: questions.count)
            
            // 타이머 설정 (문제당 30초)
            totalTime = questions.count * 30
            timeRemaining = totalTime
            
            // 첫 번째 문제로 이동
            currentQuestionIndex = 0
            
            // 타이머 시작
            startTimer()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// 답안을 제출합니다
    func submitAnswer() async {
        guard let question = currentQuestion else { return }
        
        let userAnswer: String
        switch question.type {
        case .multipleChoice:
            guard let selectedIndex = selectedOptionIndex,
                  let options = question.options,
                  selectedIndex < options.count else { return }
            userAnswer = options[selectedIndex]
        case .shortAnswer, .voice, .ai:
            userAnswer = shortAnswerText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 답안 저장
        userAnswers[currentQuestionIndex] = userAnswer
        
        // 정답 확인
        let isCorrect = checkAnswer(userAnswer: userAnswer, correctAnswer: question.correctAnswer)
        if isCorrect {
            score += 1
        }
        
        // 문제를 완료로 표시
        do {
            try await quizRepository.markQuestionAsCompleted(questionId: question.id)
        } catch {
            print("Failed to mark question as completed: \(error)")
        }
        
        // 다음 문제로 이동 또는 퀴즈 완료
        if isLastQuestion {
            await finishQuiz()
        } else {
            moveToNextQuestion()
        }
    }
    
    /// 다음 문제로 이동합니다
    private func moveToNextQuestion() {
        currentQuestionIndex += 1
        selectedOptionIndex = nil
        shortAnswerText = ""
    }
    
    /// 퀴즈를 완료합니다
    private func finishQuiz() async {
        stopTimer()
        
        // 퀴즈 결과 저장
        let timeSpent = totalTime - timeRemaining
        // TODO: QuizResult와 QuizSession 저장 로직 구현
        // 이는 Task 12에서 구현될 예정
    }
    
    /// 답안이 정답인지 확인합니다
    private func checkAnswer(userAnswer: String, correctAnswer: String) -> Bool {
        let normalizedUserAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedCorrectAnswer = correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return normalizedUserAnswer == normalizedCorrectAnswer
    }
    
    /// 타이머를 시작합니다
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    // 시간 초과
                    await self.handleTimeUp()
                }
            }
        }
    }
    
    /// 타이머를 중지합니다
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    /// 시간 초과 처리
    private func handleTimeUp() async {
        stopTimer()
        await finishQuiz()
    }
    
    /// 객관식 옵션을 선택합니다
    func selectOption(_ index: Int) {
        selectedOptionIndex = index
    }
    
    /// 에러 메시지를 클리어합니다
    func clearError() {
        errorMessage = nil
    }
    
    /// 퀴즈를 종료합니다
    func exitQuiz() {
        stopTimer()
    }
    
    deinit {
    }
}
