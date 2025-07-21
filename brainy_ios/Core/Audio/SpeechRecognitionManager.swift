import Speech
import AVFoundation
import Foundation

/// 음성 인식을 관리하는 매니저
@MainActor
final class SpeechRecognitionManager: NSObject, ObservableObject {
    static let shared = SpeechRecognitionManager()
    
    @Published var recognizedText = ""
    @Published var isListening = false
    @Published var isAvailable = false
    @Published var errorMessage: String?
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override init() {
        // 한국어 음성 인식기 초기화
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
        super.init()
        
        speechRecognizer?.delegate = self
        checkAvailability()
    }
    
    deinit {
//        stopListening()
    }
    
    // MARK: - Public Methods
    func requestPermissions() async -> Bool {
        // 음성 인식 권한 요청
        let speechAuthStatus = await requestSpeechRecognitionPermission()
        
        // 마이크 권한 요청
        let microphoneAuthStatus = await requestMicrophonePermission()
        
        let isAuthorized = speechAuthStatus == .authorized && microphoneAuthStatus
        
        if isAuthorized {
            checkAvailability()
        }
        
        return isAuthorized
    }
    
    func startListening() async throws {
        guard isAvailable else {
            throw SpeechRecognitionError.notAvailable
        }
        
        // 기존 작업 정리
        stopListening()
        
        // 오디오 세션 설정
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 인식 요청 생성
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 오디오 엔진 설정
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // 오디오 엔진 시작
        audioEngine.prepare()
        try audioEngine.start()
        
        // 음성 인식 시작
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                    
                    // 최종 결과인 경우 자동으로 중지
                    if result.isFinal {
                        self.stopListening()
                    }
                }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.stopListening()
                }
            }
        }
        
        isListening = true
        recognizedText = ""
        errorMessage = nil
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListening = false
        
        // 오디오 세션 비활성화
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    func clearRecognizedText() {
        recognizedText = ""
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    private func checkAvailability() {
        guard let speechRecognizer = speechRecognizer else {
            isAvailable = false
            return
        }
        
        isAvailable = speechRecognizer.isAvailable && 
                     SFSpeechRecognizer.authorizationStatus() == .authorized &&
                     AVAudioApplication.shared.recordPermission == .granted
    }
    
    private func requestSpeechRecognitionPermission() async -> SFSpeechRecognizerAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechRecognitionManager: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            isAvailable = available
        }
    }
}

// MARK: - Speech Recognition Errors
enum SpeechRecognitionError: LocalizedError {
    case notAvailable
    case permissionDenied
    case requestCreationFailed
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "음성 인식을 사용할 수 없습니다"
        case .permissionDenied:
            return "음성 인식 권한이 필요합니다"
        case .requestCreationFailed:
            return "음성 인식 요청 생성에 실패했습니다"
        case .recognitionFailed(let message):
            return "음성 인식 실패: \(message)"
        }
    }
}
