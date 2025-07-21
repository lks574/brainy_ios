import Foundation

/// AI 퀴즈 서비스 프로토콜
protocol AIQuizServiceProtocol: Sendable {
    func generateQuestion(
        category: QuizCategory,
        difficulty: QuizDifficulty,
        previousQuestions: [String]
    ) async throws -> AIGeneratedQuestion
    
    func validateAnswer(
        question: String,
        userAnswer: String,
        correctAnswer: String
    ) async throws -> AIAnswerValidation
    
    func adjustDifficulty(
        currentDifficulty: QuizDifficulty,
        recentPerformance: [Bool]
    ) -> QuizDifficulty
}

/// AI 퀴즈 서비스 구현체
final class AIQuizService: AIQuizServiceProtocol, @unchecked Sendable {
    private let networkService: NetworkServiceProtocol
    private let apiKey: String
    private let maxRetries: Int = 3
    private let retryDelay: TimeInterval = 1.0
    
    init(networkService: NetworkServiceProtocol, apiKey: String = "") {
        self.networkService = networkService
        self.apiKey = apiKey.isEmpty ? Self.loadAPIKeyFromConfig() : apiKey
    }
    
    /// 설정에서 API 키를 로드합니다
    private static func loadAPIKeyFromConfig() -> String {
        // 실제 구현에서는 환경 변수나 설정 파일에서 로드
        return Bundle.main.object(forInfoDictionaryKey: "AI_API_KEY") as? String ?? ""
    }
    
    func generateQuestion(
        category: QuizCategory,
        difficulty: QuizDifficulty,
        previousQuestions: [String] = []
    ) async throws -> AIGeneratedQuestion {
        let endpoint = AIQuizAPIEndpoint.generateQuestion(
            category: category,
            difficulty: difficulty,
            previousQuestions: previousQuestions
        )
        
        do {
            let response: AIQuestionResponse = try await networkService.request(endpoint)
            return response.question
        } catch {
            // 네트워크 오류 시 로컬 백업 문제 생성
            return try generateFallbackQuestion(category: category, difficulty: difficulty)
        }
    }
    
    func validateAnswer(
        question: String,
        userAnswer: String,
        correctAnswer: String
    ) async throws -> AIAnswerValidation {
        let endpoint = AIQuizAPIEndpoint.validateAnswer(
            question: question,
            userAnswer: userAnswer,
            correctAnswer: correctAnswer
        )
        
        do {
            let response: AIValidationResponse = try await networkService.request(endpoint)
            return response.validation
        } catch {
            // 네트워크 오류 시 기본 검증 로직 사용
            return performBasicValidation(userAnswer: userAnswer, correctAnswer: correctAnswer)
        }
    }
    
    func adjustDifficulty(
        currentDifficulty: QuizDifficulty,
        recentPerformance: [Bool]
    ) -> QuizDifficulty {
        guard !recentPerformance.isEmpty else { return currentDifficulty }
        
        let correctCount = recentPerformance.filter { $0 }.count
        let accuracy = Double(correctCount) / Double(recentPerformance.count)
        
        switch currentDifficulty {
        case .easy:
            return accuracy > 0.8 ? .medium : .easy
        case .medium:
            if accuracy > 0.8 {
                return .hard
            } else if accuracy < 0.4 {
                return .easy
            } else {
                return .medium
            }
        case .hard:
            return accuracy < 0.4 ? .medium : .hard
        }
    }
    
    // MARK: - Private Methods
    
    private func generateFallbackQuestion(
        category: QuizCategory,
        difficulty: QuizDifficulty
    ) throws -> AIGeneratedQuestion {
        let fallbackQuestions = getFallbackQuestions(for: category, difficulty: difficulty)
        
        guard let randomQuestion = fallbackQuestions.randomElement() else {
            throw BrainyError.quizNotFound
        }
        
        return AIGeneratedQuestion(
            id: UUID().uuidString,
            question: randomQuestion.question,
            correctAnswer: randomQuestion.answer,
            explanation: randomQuestion.explanation,
            difficulty: difficulty,
            category: category,
            hints: randomQuestion.hints,
            relatedTopics: randomQuestion.topics
        )
    }
    
    private func performBasicValidation(
        userAnswer: String,
        correctAnswer: String
    ) -> AIAnswerValidation {
        let normalizedUser = normalizeAnswer(userAnswer)
        let normalizedCorrect = normalizeAnswer(correctAnswer)
        
        let similarity = calculateSimilarity(normalizedUser, normalizedCorrect)
        let isCorrect = similarity > 0.8
        
        return AIAnswerValidation(
            isCorrect: isCorrect,
            confidence: similarity,
            explanation: isCorrect ? "정답입니다!" : "아쉽게도 틀렸습니다.",
            alternativeAnswers: [],
            feedback: generateBasicFeedback(isCorrect: isCorrect, similarity: similarity)
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
    
    private func generateBasicFeedback(isCorrect: Bool, similarity: Double) -> String {
        if isCorrect {
            return "훌륭합니다! 정확한 답변입니다."
        } else if similarity > 0.6 {
            return "아쉽습니다. 거의 정답에 가까웠어요!"
        } else {
            return "다시 한번 생각해보세요."
        }
    }
    
    private func getFallbackQuestions(
        for category: QuizCategory,
        difficulty: QuizDifficulty
    ) -> [FallbackQuestion] {
        switch category {
        case .person:
            return getPersonQuestions(difficulty: difficulty)
        case .general:
            return getGeneralQuestions(difficulty: difficulty)
        case .country:
            return getCountryQuestions(difficulty: difficulty)
        case .drama:
            return getDramaQuestions(difficulty: difficulty)
        case .music:
            return getMusicQuestions(difficulty: difficulty)
        }
    }
    
    private func getPersonQuestions(difficulty: QuizDifficulty) -> [FallbackQuestion] {
        switch difficulty {
        case .easy:
            return [
                FallbackQuestion(
                    question: "대한민국의 초대 대통령은 누구인가요?",
                    answer: "이승만",
                    explanation: "이승만은 1948년 대한민국 정부 수립과 함께 초대 대통령이 되었습니다.",
                    hints: ["정부 수립", "1948년"],
                    topics: ["한국사", "정치"]
                ),
                FallbackQuestion(
                    question: "세종대왕이 만든 문자는 무엇인가요?",
                    answer: "한글",
                    explanation: "세종대왕은 1443년 훈민정음(한글)을 창제하였습니다.",
                    hints: ["조선시대", "문자"],
                    topics: ["한국사", "언어"]
                )
            ]
        case .medium:
            return [
                FallbackQuestion(
                    question: "노벨문학상을 받은 한국 작가는 누구인가요?",
                    answer: "한강",
                    explanation: "한강 작가는 2024년 노벨문학상을 수상했습니다.",
                    hints: ["소설가", "2024년"],
                    topics: ["문학", "노벨상"]
                )
            ]
        case .hard:
            return [
                FallbackQuestion(
                    question: "조선시대 실학자 중 '북학의'를 저술한 인물은?",
                    answer: "박제가",
                    explanation: "박제가는 조선 후기 실학자로 '북학의'를 통해 청나라 문물 수용을 주장했습니다.",
                    hints: ["실학", "청나라"],
                    topics: ["한국사", "실학"]
                )
            ]
        }
    }
    
    private func getGeneralQuestions(difficulty: QuizDifficulty) -> [FallbackQuestion] {
        switch difficulty {
        case .easy:
            return [
                FallbackQuestion(
                    question: "지구에서 가장 큰 대륙은 어디인가요?",
                    answer: "아시아",
                    explanation: "아시아는 지구 육지 면적의 약 30%를 차지하는 가장 큰 대륙입니다.",
                    hints: ["대륙", "면적"],
                    topics: ["지리", "대륙"]
                )
            ]
        case .medium:
            return [
                FallbackQuestion(
                    question: "빛의 속도는 초당 몇 km인가요?",
                    answer: "300000",
                    explanation: "빛의 속도는 진공에서 초당 약 30만 km입니다.",
                    hints: ["물리", "진공"],
                    topics: ["과학", "물리학"]
                )
            ]
        case .hard:
            return [
                FallbackQuestion(
                    question: "DNA의 이중나선 구조를 발견한 과학자는?",
                    answer: "왓슨과 크릭",
                    explanation: "제임스 왓슨과 프랜시스 크릭이 1953년 DNA 이중나선 구조를 발견했습니다.",
                    hints: ["1953년", "이중나선"],
                    topics: ["생물학", "DNA"]
                )
            ]
        }
    }
    
    private func getCountryQuestions(difficulty: QuizDifficulty) -> [FallbackQuestion] {
        switch difficulty {
        case .easy:
            return [
                FallbackQuestion(
                    question: "일본의 수도는 어디인가요?",
                    answer: "도쿄",
                    explanation: "도쿄는 일본의 수도이자 최대 도시입니다.",
                    hints: ["일본", "수도"],
                    topics: ["지리", "아시아"]
                )
            ]
        case .medium:
            return [
                FallbackQuestion(
                    question: "유럽연합의 본부가 있는 도시는?",
                    answer: "브뤼셀",
                    explanation: "벨기에의 브뤼셀에 유럽연합 본부가 위치해 있습니다.",
                    hints: ["벨기에", "EU"],
                    topics: ["지리", "유럽", "정치"]
                )
            ]
        case .hard:
            return [
                FallbackQuestion(
                    question: "세계에서 가장 작은 국가는?",
                    answer: "바티칸",
                    explanation: "바티칸 시국은 면적 0.44㎢로 세계에서 가장 작은 국가입니다.",
                    hints: ["교황", "이탈리아"],
                    topics: ["지리", "종교"]
                )
            ]
        }
    }
    
    private func getDramaQuestions(difficulty: QuizDifficulty) -> [FallbackQuestion] {
        switch difficulty {
        case .easy:
            return [
                FallbackQuestion(
                    question: "'대장금'의 주인공 이름은?",
                    answer: "서장금",
                    explanation: "MBC 드라마 '대장금'의 주인공은 서장금입니다.",
                    hints: ["MBC", "사극"],
                    topics: ["드라마", "사극"]
                )
            ]
        case .medium:
            return [
                FallbackQuestion(
                    question: "'기생충'으로 아카데미상을 받은 감독은?",
                    answer: "봉준호",
                    explanation: "봉준호 감독은 '기생충'으로 2020년 아카데미 작품상을 수상했습니다.",
                    hints: ["2020년", "아카데미"],
                    topics: ["영화", "감독"]
                )
            ]
        case .hard:
            return [
                FallbackQuestion(
                    question: "'올드보이'의 원작 만화 제목은?",
                    answer: "올드보이",
                    explanation: "박찬욱 감독의 '올드보이'는 같은 제목의 일본 만화가 원작입니다.",
                    hints: ["박찬욱", "일본만화"],
                    topics: ["영화", "만화"]
                )
            ]
        }
    }
    
    private func getMusicQuestions(difficulty: QuizDifficulty) -> [FallbackQuestion] {
        switch difficulty {
        case .easy:
            return [
                FallbackQuestion(
                    question: "BTS의 리더는 누구인가요?",
                    answer: "RM",
                    explanation: "RM(김남준)은 BTS의 리더이자 메인 래퍼입니다.",
                    hints: ["김남준", "래퍼"],
                    topics: ["K-POP", "BTS"]
                )
            ]
        case .medium:
            return [
                FallbackQuestion(
                    question: "'강남스타일'을 부른 가수는?",
                    answer: "싸이",
                    explanation: "싸이(PSY)의 '강남스타일'은 2012년 전 세계적으로 큰 인기를 얻었습니다.",
                    hints: ["2012년", "말춤"],
                    topics: ["K-POP", "싸이"]
                )
            ]
        case .hard:
            return [
                FallbackQuestion(
                    question: "서태지와 아이들의 데뷔곡은?",
                    answer: "난 알아요",
                    explanation: "서태지와 아이들은 1992년 '난 알아요'로 데뷔했습니다.",
                    hints: ["1992년", "데뷔"],
                    topics: ["한국음악", "90년대"]
                )
            ]
        }
    }
}

// MARK: - Data Models

/// AI 생성 문제
struct AIGeneratedQuestion: Codable, Sendable {
    let id: String
    let question: String
    let correctAnswer: String
    let explanation: String
    let difficulty: QuizDifficulty
    let category: QuizCategory
    let hints: [String]
    let relatedTopics: [String]
    let generatedAt: Date
    
    init(
        id: String,
        question: String,
        correctAnswer: String,
        explanation: String,
        difficulty: QuizDifficulty,
        category: QuizCategory,
        hints: [String] = [],
        relatedTopics: [String] = []
    ) {
        self.id = id
        self.question = question
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.difficulty = difficulty
        self.category = category
        self.hints = hints
        self.relatedTopics = relatedTopics
        self.generatedAt = Date()
    }
}

/// AI 답안 검증 결과
struct AIAnswerValidation: Codable, Sendable {
    let isCorrect: Bool
    let confidence: Double
    let explanation: String
    let alternativeAnswers: [String]
    let feedback: String
}

/// 백업용 문제 구조체
private struct FallbackQuestion {
    let question: String
    let answer: String
    let explanation: String
    let hints: [String]
    let topics: [String]
}

// MARK: - API Endpoints

/// AI 퀴즈 API 엔드포인트
enum AIQuizAPIEndpoint: APIEndpoint, Sendable {
    case generateQuestion(category: QuizCategory, difficulty: QuizDifficulty, previousQuestions: [String])
    case validateAnswer(question: String, userAnswer: String, correctAnswer: String)
    
    var path: String {
        switch self {
        case .generateQuestion:
            return "/api/v1/ai/generate-question"
        case .validateAnswer:
            return "/api/v1/ai/validate-answer"
        }
    }
    
    var method: HTTPMethod {
        return .POST
    }
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
    
    var body: Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        switch self {
        case .generateQuestion(let category, let difficulty, let previousQuestions):
            let request = AIQuestionRequest(
                category: category,
                difficulty: difficulty,
                previousQuestions: previousQuestions
            )
            return try? encoder.encode(request)
            
        case .validateAnswer(let question, let userAnswer, let correctAnswer):
            let request = AIValidationRequest(
                question: question,
                userAnswer: userAnswer,
                correctAnswer: correctAnswer
            )
            return try? encoder.encode(request)
        }
    }
}

// MARK: - API Request/Response Models

/// AI 문제 생성 요청
private struct AIQuestionRequest: Codable, Sendable {
    let category: QuizCategory
    let difficulty: QuizDifficulty
    let previousQuestions: [String]
    let language: String = "ko"
    let maxHints: Int = 3
}

/// AI 문제 생성 응답
struct AIQuestionResponse: Codable, Sendable {
    let success: Bool
    let question: AIGeneratedQuestion
    let message: String?
}

/// AI 답안 검증 요청
private struct AIValidationRequest: Codable, Sendable {
    let question: String
    let userAnswer: String
    let correctAnswer: String
    let language: String = "ko"
}

/// AI 답안 검증 응답
struct AIValidationResponse: Codable, Sendable {
    let success: Bool
    let validation: AIAnswerValidation
    let message: String?
}
