import Foundation

/// AI 퀴즈 매니저 - AI 모드 퀴즈의 핵심 로직을 담당
@MainActor
final class AIQuizManager: ObservableObject {
    private let aiQuizService: AIQuizServiceProtocol
    private let networkService: NetworkServiceProtocol
    
    // AI 퀴즈 상태
    @Published var currentAIQuestion: AIGeneratedQuestion?
    @Published var isGeneratingQuestion: Bool = false
    @Published var generationError: String?
    @Published var lastValidation: AIAnswerValidation?
    
    // 난이도 조절 시스템
    private var recentPerformance: [Bool] = []
    private var currentDifficulty: QuizDifficulty
    private var questionHistory: [String] = []
    
    // 설정
    private let maxQuestionHistory = 20
    private let performanceWindowSize = 5
    
    init(
        aiQuizService: AIQuizServiceProtocol? = nil,
        networkService: NetworkServiceProtocol? = nil,
        initialDifficulty: QuizDifficulty = .medium
    ) {
        let defaultNetworkService = networkService ?? NetworkService()
        self.networkService = defaultNetworkService
        self.aiQuizService = aiQuizService ?? AIQuizService(networkService: defaultNetworkService)
        self.currentDifficulty = initialDifficulty
    }
    
    /// 새로운 AI 문제를 생성합니다
    func generateQuestion(for category: QuizCategory) async {
        isGeneratingQuestion = true
        generationError = nil
        
        do {
            let question = try await aiQuizService.generateQuestion(
                category: category,
                difficulty: currentDifficulty,
                previousQuestions: questionHistory
            )
            
            currentAIQuestion = question
            
            // 문제 히스토리에 추가
            addToQuestionHistory(question.question)
            
        } catch {
            generationError = handleGenerationError(error)
            
            // 에러 발생 시 백업 문제 생성 시도
            await generateFallbackQuestion(for: category)
        }
        
        isGeneratingQuestion = false
    }
    
    /// 사용자 답안을 AI로 검증합니다
    func validateAnswer(userAnswer: String) async -> AIAnswerValidation {
        guard let currentQuestion = currentAIQuestion else {
            return AIAnswerValidation(
                isCorrect: false,
                confidence: 0.0,
                explanation: "현재 문제가 없습니다.",
                alternativeAnswers: [],
                feedback: "문제를 다시 로드해주세요."
            )
        }
        
        do {
            let validation = try await aiQuizService.validateAnswer(
                question: currentQuestion.question,
                userAnswer: userAnswer,
                correctAnswer: currentQuestion.correctAnswer
            )
            
            lastValidation = validation
            
            // 성과 기록 업데이트
            updatePerformanceRecord(isCorrect: validation.isCorrect)
            
            // 난이도 조절
            adjustDifficultyIfNeeded()
            
            return validation
            
        } catch {
            // 네트워크 오류 시 기본 검증 수행
            let basicValidation = performBasicValidation(
                userAnswer: userAnswer,
                correctAnswer: currentQuestion.correctAnswer
            )
            
            lastValidation = basicValidation
            updatePerformanceRecord(isCorrect: basicValidation.isCorrect)
            adjustDifficultyIfNeeded()
            
            return basicValidation
        }
    }
    
    /// 현재 문제에 대한 힌트를 제공합니다
    func getHint() -> String? {
        guard let question = currentAIQuestion,
              !question.hints.isEmpty else {
            return nil
        }
        
        // 랜덤하게 힌트 하나를 선택
        return question.hints.randomElement()
    }
    
    /// 현재 문제의 설명을 반환합니다
    func getExplanation() -> String? {
        return currentAIQuestion?.explanation
    }
    
    /// 관련 주제들을 반환합니다
    func getRelatedTopics() -> [String] {
        return currentAIQuestion?.relatedTopics ?? []
    }
    
    /// 현재 난이도를 반환합니다
    func getCurrentDifficulty() -> QuizDifficulty {
        return currentDifficulty
    }
    
    /// 최근 성과를 반환합니다
    func getRecentAccuracy() -> Double {
        guard !recentPerformance.isEmpty else { return 0.0 }
        
        let correctCount = recentPerformance.filter { $0 }.count
        return Double(correctCount) / Double(recentPerformance.count)
    }
    
    /// AI 퀴즈 세션을 초기화합니다
    func resetSession() {
        currentAIQuestion = nil
        lastValidation = nil
        recentPerformance.removeAll()
        questionHistory.removeAll()
        currentDifficulty = .medium
        generationError = nil
    }
    
    /// 특정 난이도로 설정합니다
    func setDifficulty(_ difficulty: QuizDifficulty) {
        currentDifficulty = difficulty
    }
    
    // MARK: - Private Methods
    
    private func addToQuestionHistory(_ question: String) {
        questionHistory.append(question)
        
        // 히스토리 크기 제한
        if questionHistory.count > maxQuestionHistory {
            questionHistory.removeFirst()
        }
    }
    
    private func updatePerformanceRecord(isCorrect: Bool) {
        recentPerformance.append(isCorrect)
        
        // 성과 기록 크기 제한
        if recentPerformance.count > performanceWindowSize {
            recentPerformance.removeFirst()
        }
    }
    
    private func adjustDifficultyIfNeeded() {
        guard recentPerformance.count >= performanceWindowSize else { return }
        
        let newDifficulty = aiQuizService.adjustDifficulty(
            currentDifficulty: currentDifficulty,
            recentPerformance: recentPerformance
        )
        
        if newDifficulty != currentDifficulty {
            currentDifficulty = newDifficulty
            print("난이도가 \(newDifficulty.rawValue)로 조정되었습니다.")
        }
    }
    
    private func generateFallbackQuestion(for category: QuizCategory) async {
        // 간단한 백업 문제 생성
        let fallbackQuestions = getFallbackQuestions(for: category)
        
        if let randomQuestion = fallbackQuestions.randomElement() {
            currentAIQuestion = AIGeneratedQuestion(
                id: UUID().uuidString,
                question: randomQuestion.question,
                correctAnswer: randomQuestion.answer,
                explanation: randomQuestion.explanation,
                difficulty: currentDifficulty,
                category: category,
                hints: randomQuestion.hints,
                relatedTopics: randomQuestion.topics
            )
        }
    }
    
    private func performBasicValidation(
        userAnswer: String,
        correctAnswer: String
    ) -> AIAnswerValidation {
        let normalizedUser = normalizeAnswer(userAnswer)
        let normalizedCorrect = normalizeAnswer(correctAnswer)
        
        let similarity = calculateSimilarity(normalizedUser, normalizedCorrect)
        let isCorrect = similarity > 0.8
        
        let feedback = generateFeedback(isCorrect: isCorrect, similarity: similarity)
        
        return AIAnswerValidation(
            isCorrect: isCorrect,
            confidence: similarity,
            explanation: isCorrect ? "정답입니다!" : "아쉽게도 틀렸습니다. 정답은 '\(correctAnswer)'입니다.",
            alternativeAnswers: generateAlternativeAnswers(correctAnswer),
            feedback: feedback
        )
    }
    
    private func normalizeAnswer(_ answer: String) -> String {
        return answer
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
    }
    
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        let longer = str1.count > str2.count ? str1 : str2
        let shorter = str1.count > str2.count ? str2 : str1
        
        if longer.isEmpty { return 1.0 }
        
        let editDistance = levenshteinDistance(shorter, longer)
        return (Double(longer.count) - Double(editDistance)) / Double(longer.count)
    }
    
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let arr1 = Array(str1)
        let arr2 = Array(str2)
        let m = arr1.count
        let n = arr2.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }
        
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
    
    private func generateFeedback(isCorrect: Bool, similarity: Double) -> String {
        if isCorrect {
            let encouragements = [
                "훌륭합니다! 정확한 답변입니다.",
                "완벽해요! 잘 알고 계시네요.",
                "정답입니다! 계속 이런 식으로 해보세요.",
                "맞습니다! 실력이 늘고 있어요."
            ]
            return encouragements.randomElement() ?? "정답입니다!"
        } else if similarity > 0.6 {
            let nearMisses = [
                "아쉽습니다! 거의 정답에 가까웠어요.",
                "조금만 더! 거의 다 맞췄습니다.",
                "아깝네요. 정답과 비슷했어요.",
                "좋은 시도였어요! 조금 더 생각해보세요."
            ]
            return nearMisses.randomElement() ?? "거의 정답이었어요!"
        } else {
            let encouragements = [
                "다시 한번 생각해보세요.",
                "힌트를 참고해서 다시 시도해보세요.",
                "괜찮아요! 다음 문제에서 화이팅!",
                "학습하는 과정이니까 괜찮습니다."
            ]
            return encouragements.randomElement() ?? "다시 시도해보세요!"
        }
    }
    
    private func generateAlternativeAnswers(_ correctAnswer: String) -> [String] {
        // 간단한 대안 답안 생성 (실제로는 더 정교한 로직 필요)
        return []
    }
    
    private func handleGenerationError(_ error: Error) -> String {
        if let brainyError = error as? BrainyError {
            switch brainyError {
            case .networkUnavailable:
                return "네트워크 연결을 확인해주세요. 오프라인 모드로 진행합니다."
            case .dataCorrupted:
                return "서버 응답에 문제가 있습니다. 다시 시도해주세요."
            default:
                return brainyError.localizedDescription
            }
        }
        return "문제 생성 중 오류가 발생했습니다: \(error.localizedDescription)"
    }
    
    private func getFallbackQuestions(for category: QuizCategory) -> [FallbackQuestionData] {
        switch category {
        case .person:
            return [
                FallbackQuestionData(
                    question: "한국의 초대 대통령은 누구인가요?",
                    answer: "이승만",
                    explanation: "이승만은 1948년 대한민국 정부 수립과 함께 초대 대통령이 되었습니다.",
                    hints: ["정부 수립", "1948년"],
                    topics: ["한국사", "정치"]
                ),
                FallbackQuestionData(
                    question: "세종대왕이 창제한 문자는 무엇인가요?",
                    answer: "한글",
                    explanation: "세종대왕은 1443년 훈민정음(한글)을 창제하였습니다.",
                    hints: ["조선시대", "훈민정음"],
                    topics: ["한국사", "언어"]
                )
            ]
        case .general:
            return [
                FallbackQuestionData(
                    question: "지구에서 가장 큰 대륙은 어디인가요?",
                    answer: "아시아",
                    explanation: "아시아는 지구 육지 면적의 약 30%를 차지하는 가장 큰 대륙입니다.",
                    hints: ["대륙", "30%"],
                    topics: ["지리", "대륙"]
                )
            ]
        case .country:
            return [
                FallbackQuestionData(
                    question: "일본의 수도는 어디인가요?",
                    answer: "도쿄",
                    explanation: "도쿄는 일본의 수도이자 최대 도시입니다.",
                    hints: ["일본", "수도"],
                    topics: ["지리", "아시아"]
                )
            ]
        case .drama:
            return [
                FallbackQuestionData(
                    question: "'대장금'의 주인공 이름은 무엇인가요?",
                    answer: "서장금",
                    explanation: "MBC 드라마 '대장금'의 주인공은 서장금입니다.",
                    hints: ["MBC", "사극"],
                    topics: ["드라마", "사극"]
                )
            ]
        case .music:
            return [
                FallbackQuestionData(
                    question: "BTS의 리더는 누구인가요?",
                    answer: "RM",
                    explanation: "RM(김남준)은 BTS의 리더이자 메인 래퍼입니다.",
                    hints: ["김남준", "래퍼"],
                    topics: ["K-POP", "BTS"]
                )
            ]
        }
    }
}

// MARK: - Supporting Data Structures

/// 백업용 문제 데이터
private struct FallbackQuestionData {
    let question: String
    let answer: String
    let explanation: String
    let hints: [String]
    let topics: [String]
}

/// AI 퀴즈 통계
struct AIQuizStatistics {
    let totalQuestions: Int
    let correctAnswers: Int
    let averageConfidence: Double
    let difficultyProgression: [QuizDifficulty]
    let categoryPerformance: [QuizCategory: Double]
    
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
}

/// AI 퀴즈 설정
struct AIQuizSettings {
    var enableDynamicDifficulty: Bool = true
    var enableHints: Bool = true
    var maxQuestionsPerSession: Int = 10
    var confidenceThreshold: Double = 0.8
    var performanceWindowSize: Int = 5
}