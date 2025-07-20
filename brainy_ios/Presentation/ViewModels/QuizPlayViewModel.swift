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
    private var questionStartTime: Date?
    
    // Quiz session management
    var currentSession: QuizSession?
    var sessionResults: [QuizResult] = []
    
    // Quiz configuration
    let category: QuizCategory
    let mode: QuizMode
    let quizType: QuizType
    let excludeCompleted: Bool
    
    // Current user (should be injected or retrieved from auth service)
    private var currentUserId: String = "default_user" // TODO: Get from AuthenticationService
    
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
            // 퀴즈 문제들을 로드 (향상된 로딩 로직)
            questions = try await loadQuestions()
            
            // 문제가 없는 경우 처리
            if questions.isEmpty {
                let message = excludeCompleted ? 
                    "해당 카테고리에 풀지 않은 \(quizType.rawValue) 문제가 없습니다." :
                    "해당 카테고리에 \(quizType.rawValue) 문제가 없습니다."
                errorMessage = message
                isLoading = false
                return
            }
            
            // 퀴즈 세션 생성
            try await createQuizSession()
            
            // 퀴즈 상태 초기화
            initializeQuizState()
            
            // 첫 번째 문제 시작
            startCurrentQuestion()
            
        } catch {
            errorMessage = handleError(error)
        }
        
        isLoading = false
    }
    
    /// 문제 로딩 로직 (향상된 버전)
    private func loadQuestions() async throws -> [QuizQuestion] {
        // 기본 문제 로드
        let allQuestions = try await quizRepository.getQuestions(
            category: category,
            excludeCompleted: excludeCompleted
        )
        
        // 퀴즈 타입에 맞는 문제들만 필터링
        var filteredQuestions = allQuestions.filter { $0.type == quizType }
        
        // 추가 필터링 로직
        if excludeCompleted {
            filteredQuestions = filteredQuestions.filter { !$0.isCompleted }
        }
        
        // 문제들을 섞기
        filteredQuestions.shuffle()
        
        // 모드에 따른 문제 수 제한
        let questionLimit = getQuestionLimit()
        if filteredQuestions.count > questionLimit {
            filteredQuestions = Array(filteredQuestions.prefix(questionLimit))
        }
        
        return filteredQuestions
    }
    
    /// 모드에 따른 문제 수 제한 반환
    private func getQuestionLimit() -> Int {
        switch mode {
        case .individual:
            return 10 // 개별 모드는 최대 10문제
        case .stage:
            return 20 // 스테이지 모드는 최대 20문제
        }
    }
    
    /// 퀴즈 세션 생성
    private func createQuizSession() async throws {
        let sessionId = UUID().uuidString
        let session = QuizSession(
            id: sessionId,
            userId: currentUserId,
            category: category,
            mode: mode,
            totalQuestions: questions.count
        )
        
        // 세션을 저장 (QuizRepositoryImpl에 saveQuizSession 메서드가 있음)
        if let repo = quizRepository as? QuizRepositoryImpl {
            try await repo.saveQuizSession(session)
        }
        
        currentSession = session
        sessionResults = []
    }
    
    /// 퀴즈 상태 초기화
    private func initializeQuizState() {
        // 사용자 답안 배열 초기화
        userAnswers = Array(repeating: "", count: questions.count)
        
        // 점수 초기화
        score = 0
        currentQuestionIndex = 0
        
        // 타이머 설정 (문제당 30초)
        totalTime = questions.count * 30
        timeRemaining = totalTime
    }
    
    /// 현재 문제 시작
    private func startCurrentQuestion() {
        questionStartTime = Date()
        selectedOptionIndex = nil
        shortAnswerText = ""
        
        // 타이머 시작 (첫 번째 문제에서만)
        if currentQuestionIndex == 0 {
            startTimer()
        }
    }
    
    /// 답안을 제출합니다 (향상된 버전)
    func submitAnswer() async {
        guard let question = currentQuestion else { return }
        
        // 사용자 답안 추출
        let userAnswer = extractUserAnswer(for: question)
        guard !userAnswer.isEmpty else { return }
        
        // 답안 저장
        userAnswers[currentQuestionIndex] = userAnswer
        
        // 정답 확인 및 점수 계산
        let isCorrect = validateAnswer(userAnswer: userAnswer, question: question)
        if isCorrect {
            score += 1
        }
        
        // 문제 소요 시간 계산
        let timeSpent = calculateQuestionTime()
        
        // 퀴즈 결과 생성 및 저장
        await saveQuestionResult(
            question: question,
            userAnswer: userAnswer,
            isCorrect: isCorrect,
            timeSpent: timeSpent
        )
        
        // 문제를 완료로 표시
        await markQuestionCompleted(questionId: question.id)
        
        // 다음 문제로 이동 또는 퀴즈 완료
        if isLastQuestion {
            await finishQuiz()
        } else {
            moveToNextQuestion()
        }
    }
    
    /// 사용자 답안 추출
    private func extractUserAnswer(for question: QuizQuestion) -> String {
        switch question.type {
        case .multipleChoice:
            guard let selectedIndex = selectedOptionIndex,
                  let options = question.options,
                  selectedIndex < options.count else { return "" }
            return options[selectedIndex]
        case .shortAnswer, .voice, .ai:
            return shortAnswerText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    /// 답안 검증 및 점수 계산 (향상된 버전)
    private func validateAnswer(userAnswer: String, question: QuizQuestion) -> Bool {
        switch question.type {
        case .multipleChoice:
            // 객관식은 정확한 매칭
            return userAnswer == question.correctAnswer
        case .shortAnswer:
            // 주관식은 유연한 매칭 (대소문자, 공백 무시)
            return checkFlexibleAnswer(userAnswer: userAnswer, correctAnswer: question.correctAnswer)
        case .voice:
            // 음성 모드는 유연한 매칭 + 발음 유사성 고려
            return checkVoiceAnswer(userAnswer: userAnswer, correctAnswer: question.correctAnswer)
        case .ai:
            // AI 모드는 의미적 유사성 고려 (현재는 유연한 매칭으로 대체)
            return checkFlexibleAnswer(userAnswer: userAnswer, correctAnswer: question.correctAnswer)
        }
    }
    
    /// 유연한 답안 검증 (주관식용)
    private func checkFlexibleAnswer(userAnswer: String, correctAnswer: String) -> Bool {
        let normalizedUser = normalizeAnswer(userAnswer)
        let normalizedCorrect = normalizeAnswer(correctAnswer)
        
        // 정확한 매칭
        if normalizedUser == normalizedCorrect {
            return true
        }
        
        // 부분 매칭 (정답이 사용자 답안에 포함되거나 그 반대)
        if normalizedUser.contains(normalizedCorrect) || normalizedCorrect.contains(normalizedUser) {
            return true
        }
        
        // 유사도 검사 (간단한 편집 거리 기반)
        return calculateSimilarity(normalizedUser, normalizedCorrect) > 0.8
    }
    
    /// 음성 답안 검증
    private func checkVoiceAnswer(userAnswer: String, correctAnswer: String) -> Bool {
        // 음성 인식의 특성상 더 관대한 검증
        let normalizedUser = normalizeAnswer(userAnswer)
        let normalizedCorrect = normalizeAnswer(correctAnswer)
        
        // 유사도 임계값을 낮춤
        return calculateSimilarity(normalizedUser, normalizedCorrect) > 0.7
    }
    
    /// 답안 정규화
    private func normalizeAnswer(_ answer: String) -> String {
        return answer
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
    }
    
    /// 문자열 유사도 계산 (간단한 버전)
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        let longer = str1.count > str2.count ? str1 : str2
        let shorter = str1.count > str2.count ? str2 : str1
        
        if longer.isEmpty {
            return 1.0
        }
        
        let editDistance = levenshteinDistance(shorter, longer)
        return (Double(longer.count) - Double(editDistance)) / Double(longer.count)
    }
    
    /// 레벤슈타인 거리 계산
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let arr1 = Array(str1)
        let arr2 = Array(str2)
        let m = arr1.count
        let n = arr2.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            dp[i][0] = i
        }
        
        for j in 0...n {
            dp[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                if arr1[i-1] == arr2[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]) + 1
                }
            }
        }
        
        return dp[m][n]
    }
    
    /// 문제 소요 시간 계산
    private func calculateQuestionTime() -> TimeInterval {
        guard let startTime = questionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    /// 문제 결과 저장
    private func saveQuestionResult(
        question: QuizQuestion,
        userAnswer: String,
        isCorrect: Bool,
        timeSpent: TimeInterval
    ) async {
        let resultId = UUID().uuidString
        let result = QuizResult(
            id: resultId,
            userId: currentUserId,
            questionId: question.id,
            userAnswer: userAnswer,
            isCorrect: isCorrect,
            timeSpent: timeSpent,
            category: category,
            quizMode: mode
        )
        
        // 세션 결과에 추가
        sessionResults.append(result)
        
        // 저장소에 저장
        do {
            try await quizRepository.saveQuizResult(result)
        } catch {
            print("Failed to save quiz result: \(error)")
        }
    }
    
    /// 문제 완료 표시
    private func markQuestionCompleted(questionId: String) async {
        do {
            try await quizRepository.markQuestionAsCompleted(questionId: questionId)
        } catch {
            print("Failed to mark question as completed: \(error)")
        }
    }
    
    /// 다음 문제로 이동합니다
    private func moveToNextQuestion() {
        currentQuestionIndex += 1
        
        // 다음 문제 시작
        startCurrentQuestion()
    }
    
    /// 퀴즈를 완료합니다 (향상된 버전)
    private func finishQuiz() async {
        stopTimer()
        
        // 퀴즈 세션 완료 처리
        await completeQuizSession()
        
        // AdMob 광고 미리 로드 (결과 화면에서 표시하기 위해)
        AdMobManager.shared.loadInterstitialAd()
    }
    
    /// 퀴즈 세션 완료 처리
    private func completeQuizSession() async {
        guard let session = currentSession else { return }
        
        let totalTimeSpent = TimeInterval(totalTime - timeRemaining)
        
        // 세션 완료 처리
        do {
            if let repo = quizRepository as? QuizRepositoryImpl {
                try await repo.completeQuizSession(
                    sessionId: session.id,
                    correctAnswers: score,
                    totalTime: totalTimeSpent
                )
            }
        } catch {
            print("Failed to complete quiz session: \(error)")
        }
        
        // 세션 상태 업데이트
        session.correctAnswers = score
        session.totalTime = totalTimeSpent
        session.completedAt = Date()
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
    
    /// 에러 처리
    private func handleError(_ error: Error) -> String {
        if let brainyError = error as? BrainyError {
            return brainyError.localizedDescription
        }
        return error.localizedDescription
    }
    
    /// 에러 메시지를 클리어합니다
    func clearError() {
        errorMessage = nil
    }
    
    /// 퀴즈를 종료합니다
    func exitQuiz() {
        stopTimer()
    }
    
    /// 퀴즈 진행 상태 정보 반환
    func getQuizProgress() -> QuizProgress {
        return QuizProgress(
            currentQuestionIndex: currentQuestionIndex,
            totalQuestions: questions.count,
            score: score,
            timeRemaining: timeRemaining,
            totalTime: totalTime
        )
    }
    
    /// 현재 세션의 통계 정보 반환
    func getSessionStatistics() -> SessionStatistics? {
        guard let session = currentSession else { return nil }
        
        let correctAnswers = sessionResults.filter { $0.isCorrect }.count
        let totalAnswered = sessionResults.count
        let averageTimePerQuestion = totalAnswered > 0 ? 
            sessionResults.reduce(0) { $0 + $1.timeSpent } / Double(totalAnswered) : 0
        
        return SessionStatistics(
            sessionId: session.id,
            category: session.category,
            mode: session.mode,
            totalQuestions: session.totalQuestions,
            answeredQuestions: totalAnswered,
            correctAnswers: correctAnswers,
            averageTimePerQuestion: averageTimePerQuestion
        )
    }
    
    deinit {
     
    }
}

// MARK: - Supporting Data Structures

/// 퀴즈 진행 상태 정보
struct QuizProgress {
    let currentQuestionIndex: Int
    let totalQuestions: Int
    let score: Int
    let timeRemaining: Int
    let totalTime: Int
    
    var progressPercentage: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(currentQuestionIndex) / Double(totalQuestions)
    }
    
    var accuracyPercentage: Double {
        guard currentQuestionIndex > 0 else { return 0 }
        return Double(score) / Double(currentQuestionIndex)
    }
}

/// 세션 통계 정보
struct SessionStatistics {
    let sessionId: String
    let category: QuizCategory
    let mode: QuizMode
    let totalQuestions: Int
    let answeredQuestions: Int
    let correctAnswers: Int
    let averageTimePerQuestion: TimeInterval
    
    var accuracyRate: Double {
        guard answeredQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(answeredQuestions)
    }
    
    var completionRate: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(answeredQuestions) / Double(totalQuestions)
    }
}
